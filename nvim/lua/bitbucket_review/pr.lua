-- PR detection and comment state management
local M = {}
local api = require 'bitbucket_review.api'

M.state = {
  pr = nil,
  base_url = nil,
  project = nil,
  repo = nil,
  branch = nil,
  -- [file_path][line_num] = list of top-level comment objects (each may have .comments[] replies)
  by_file_line = {},
}

-- Run a command synchronously, return trimmed stdout or nil
local function cmd(args)
  local r = vim.system(args, { text = true }):wait()
  if r.code ~= 0 then
    return nil
  end
  return vim.trim(r.stdout)
end

-- Parse Bitbucket Server remote URL into (base_url, project, repo)
-- Handles:
--   https://host/scm/PROJECT/repo.git
--   ssh://git@host:7999/PROJECT/repo.git
local function parse_remote(url)
  -- HTTPS
  local base, proj, repo = url:match '(https?://[^/]+)/scm/([^/]+)/([^/.]+)'
  if base then
    return base, proj:upper(), repo
  end
  -- SSH  ssh://git@host:port/PROJECT/REPO.git
  base, proj, repo = url:match 'ssh://[^@]+@([^:/]+)[:/]%d*/([^/]+)/([^/.]+)'
  if base then
    return 'https://' .. base, proj:upper(), repo
  end
  -- SCP  git@host:PROJECT/REPO.git
  base, proj, repo = url:match '[^@]+@([^:]+):([^/]+)/([^/.]+)'
  if base then
    return 'https://' .. base, proj:upper(), repo
  end
  return nil, nil, nil
end

-- Recursively flatten a comment thread into a list, tagging each with _depth
local function flatten(comment, depth, out)
  out = out or {}
  depth = depth or 0
  comment._depth = depth
  table.insert(out, comment)
  for _, reply in ipairs(comment.comments or {}) do
    flatten(reply, depth + 1, out)
  end
  return out
end

-- Build by_file_line index from a flat list of top-level comment objects.
-- Uses c._mapped_line when present (set by apply_line_maps), else anchor.line.
local function index(comments)
  local idx = {}
  for _, c in ipairs(comments) do
    local a = c.anchor
    local line = c._mapped_line or (a and a.line)
    if a and line and a.path then
      idx[a.path] = idx[a.path] or {}
      idx[a.path][line] = idx[a.path][line] or {}
      table.insert(idx[a.path][line], c)
    end
  end
  return idx
end

-- Parse a unified diff into a line-mapper function: old_line -> new_line | nil (deleted).
-- Lines outside all diff hunks are mapped via the cumulative delta at that point.
local function make_line_mapper(diff_text)
  if not diff_text or diff_text == '' then
    return function(l)
      return l
    end
  end

  local explicit = {} -- [old_line] = new_line, or false for deleted lines
  -- Breakpoints: after processing each hunk we record the running delta for
  -- lines that fall between hunks (not explicitly mapped).
  -- Each entry: { old_end = N, delta = D } meaning "for old_line > N (until
  -- the next entry's old_end), new_line = old_line + D".
  local breakpoints = {}
  local pre_hunk_delta = nil -- delta valid before the first hunk

  local lines = vim.split(diff_text, '\n', { plain = true })
  local i = 1
  while i <= #lines do
    local os, oc, ns = lines[i]:match '^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@'
    if os then
      local old_pos = tonumber(os)
      local new_pos = tonumber(ns)
      -- Delta for lines sitting before this hunk (unchanged, outside context window)
      if pre_hunk_delta == nil then
        pre_hunk_delta = new_pos - old_pos
      end
      i = i + 1
      while i <= #lines do
        local ch = lines[i]:sub(1, 1)
        if ch == ' ' then
          explicit[old_pos] = new_pos
          old_pos = old_pos + 1
          new_pos = new_pos + 1
        elseif ch == '-' then
          explicit[old_pos] = false
          old_pos = old_pos + 1
        elseif ch == '+' then
          new_pos = new_pos + 1
        elseif ch == '@' then
          break -- start of next hunk; don't advance i
        elseif ch == 'd' or ch == 'i' then
          break -- next diff --git header
        end
        -- '\' (no newline at end of file) and empty lines: skip
        if ch ~= '@' and ch ~= 'd' and ch ~= 'i' then
          i = i + 1
        end
      end
      -- After this hunk: delta = new_pos - old_pos (both point past last line)
      table.insert(breakpoints, { old_end = old_pos - 1, delta = new_pos - old_pos })
    else
      i = i + 1
    end
  end

  if pre_hunk_delta == nil then
    return function(l)
      return l
    end -- no hunks parsed
  end

  return function(old_line)
    local v = explicit[old_line]
    if v == false then
      return nil
    end -- line was deleted
    if v then
      return v
    end -- context line explicitly mapped in hunk

    -- Outside all hunks: apply the running delta at this position
    -- Scan breakpoints in order; the last one whose old_end < old_line applies.
    local delta = pre_hunk_delta
    for _, bp in ipairs(breakpoints) do
      if bp.old_end < old_line then
        delta = bp.delta
      else
        break
      end
    end
    return old_line + delta
  end
end

-- For each unique (path, toHash) pair among inline comments, run git diff
-- toHash..HEAD to build a line mapper. Calls callback() when all are ready,
-- with c._mapped_line set on each comment.
local function apply_line_maps(inline, callback)
  -- Collect unique pairs
  local needed = {}
  for _, c in ipairs(inline) do
    local to_hash = c.anchor and c.anchor.toHash
    local path = c.anchor and c.anchor.path
    if to_hash and path then
      local key = path .. '\0' .. to_hash
      needed[key] = { path = path, to_hash = to_hash }
    end
  end

  local mappers = {}
  local total = 0
  local finished = 0
  for _ in pairs(needed) do
    total = total + 1
  end

  if total == 0 then
    callback()
    return
  end

  local function on_done()
    finished = finished + 1
    if finished < total then
      return
    end
    -- Apply mappers to set _mapped_line on each comment
    for _, c in ipairs(inline) do
      local to_hash = c.anchor and c.anchor.toHash
      local path = c.anchor and c.anchor.path
      if to_hash and path then
        local key = path .. '\0' .. to_hash
        local mapper = mappers[key] or function(l)
          return l
        end
        c._mapped_line = mapper(c.anchor.line)
      end
    end
    callback()
  end

  for key, info in pairs(needed) do
    local k = key
    vim.system({ 'git', 'diff', info.to_hash .. '..HEAD', '--', info.path }, { text = true }, function(r)
      vim.schedule(function()
        mappers[k] = make_line_mapper(r.code == 0 and r.stdout or '')
        on_done()
      end)
    end)
  end
end

-- Returns git root for cwd (sync)
function M.git_root()
  return cmd { 'git', 'rev-parse', '--show-toplevel' }
end

-- Returns repo-relative path of bufnr (or current buffer)
function M.relative_path(bufnr)
  local abs = vim.api.nvim_buf_get_name(bufnr or 0)
  local root = M.git_root()
  if not root or abs == '' then
    return nil
  end
  if abs:sub(1, #root) == root then
    return abs:sub(#root + 2)
  end
  return nil
end

-- Detect PR for the current worktree. callback(err, pr_or_nil)
function M.detect(callback)
  local branch = cmd { 'git', 'branch', '--show-current' }
  if not branch then
    callback('not in a git repo', nil)
    return
  end
  if branch == 'development' or branch == 'master' or branch == 'main' then
    callback(nil, nil)
    return
  end
  local remote_url = cmd { 'git', 'remote', 'get-url', 'origin' }
  if not remote_url then
    callback('no git remote origin', nil)
    return
  end
  local base_url, project, repo = parse_remote(remote_url)
  if not base_url then
    callback('could not parse remote: ' .. remote_url, nil)
    return
  end
  M.state.base_url = base_url
  M.state.project = project
  M.state.repo = repo
  M.state.branch = branch

  local url = ('%s/rest/api/1.0/projects/%s/repos/%s/pull-requests?at=refs/heads/%s&state=OPEN&direction=OUTGOING'):format(
    base_url,
    project,
    repo,
    api.urlencode(branch)
  )
  api.get(url, function(err, data)
    if err then
      callback(err, nil)
      return
    end
    local prs = (data or {}).values or {}
    if #prs == 0 then
      callback(nil, nil)
      return
    end
    M.state.pr = prs[1]
    callback(nil, M.state.pr)
  end)
end

-- Fetch all inline PR comments via the activities endpoint and refresh the index.
-- The /comments endpoint requires a ?path= filter; activities gives us everything.
-- callback(err, inline_comments)
function M.fetch_comments(callback)
  local pr = M.state.pr
  if not pr then
    callback('no PR bound', nil)
    return
  end
  local url = ('%s/rest/api/1.0/projects/%s/repos/%s/pull-requests/%d/activities'):format(M.state.base_url, M.state.project, M.state.repo, pr.id)
  api.get_all(url, function(err, activities)
    if err then
      callback(err, nil)
      return
    end
    -- Extract top-level inline comments from COMMENTED activities.
    -- The anchor lives at act.commentAnchor (activity level), not act.comment.anchor.
    -- General PR comments have no commentAnchor; skip those.
    local inline = {}
    for _, act in ipairs(activities) do
      if act.action == 'COMMENTED' then
        local anchor = act.commentAnchor
        local c = act.comment
        if c and anchor and anchor.line and anchor.path and not c.parent then
          c.anchor = anchor -- attach for indexing and posting replies
          table.insert(inline, c)
        end
      end
    end
    apply_line_maps(inline, function()
      M.state.by_file_line = index(inline)
      callback(nil, inline)
    end)
  end)
end

-- Returns list of flattened thread lists for a given file + 1-indexed line
-- Each element is a list of comments (top-level + replies, depth-tagged)
function M.get_threads(file_path, line)
  local by_line = M.state.by_file_line[file_path]
  if not by_line then
    return {}
  end
  local threads = {}
  for _, top in ipairs(by_line[line] or {}) do
    table.insert(threads, flatten(top))
  end
  return threads
end

-- Detect whether a line is ADDED or CONTEXT relative to development
-- callback(line_type_string)
local function detect_line_type(file_path, line_num, callback)
  vim.system({ 'git', 'diff', 'development..HEAD', '--', file_path }, { text = true }, function(r)
    vim.schedule(function()
      if r.code ~= 0 or not r.stdout or r.stdout == '' then
        callback 'ADDED'
        return
      end
      local to_line = 0
      local found = 'CONTEXT'
      for _, dline in ipairs(vim.split(r.stdout, '\n')) do
        local ns, _ = dline:match '^@@ %-%d+,?%d* %+(%d+),?(%d*) @@'
        if ns then
          to_line = tonumber(ns) - 1
        elseif dline:match '^%+' and not dline:match '^%+%+%+' then
          to_line = to_line + 1
          if to_line == line_num then
            found = 'ADDED'
            break
          end
        elseif dline:match '^%-' and not dline:match '^%-%-%-' then
          -- removed line: does not advance to-side counter
        elseif not dline:match '^\\' and dline ~= '' then
          to_line = to_line + 1
          if to_line == line_num then
            found = 'CONTEXT'
            break
          end
        end
      end
      callback(found)
    end)
  end)
end

-- Post a new inline comment. callback(err, comment)
function M.post_comment(file_path, line, text, callback)
  local pr = M.state.pr
  if not pr then
    callback('no PR bound', nil)
    return
  end
  local url = ('%s/rest/api/1.0/projects/%s/repos/%s/pull-requests/%d/comments'):format(M.state.base_url, M.state.project, M.state.repo, pr.id)

  local function do_post(line_type)
    local body = {
      text = text,
      anchor = {
        diffType = 'EFFECTIVE',
        fileType = 'TO',
        line = line,
        lineType = line_type,
        path = file_path,
      },
    }
    api.post(url, body, function(err, comment)
      if err and line_type == 'ADDED' then
        -- Retry as CONTEXT (line may be unchanged relative to base)
        do_post 'CONTEXT'
      elseif err then
        callback(err, nil)
      else
        M.fetch_comments(function() end)
        callback(nil, comment)
      end
    end)
  end

  detect_line_type(file_path, line, do_post)
end

-- Post a reply to an existing comment. callback(err, comment)
function M.post_reply(parent_id, text, callback)
  local pr = M.state.pr
  if not pr then
    callback('no PR bound', nil)
    return
  end
  local url = ('%s/rest/api/1.0/projects/%s/repos/%s/pull-requests/%d/comments'):format(M.state.base_url, M.state.project, M.state.repo, pr.id)
  api.post(url, { text = text, parent = { id = parent_id } }, function(err, comment)
    if err then
      callback(err, nil)
      return
    end
    M.fetch_comments(function() end)
    callback(nil, comment)
  end)
end

return M
