-- Bitbucket PR Review plugin entry point
local M = {}
local pr = require 'bitbucket_review.pr'
local gutter = require 'bitbucket_review.gutter'
local ui = require 'bitbucket_review.ui'

local loaded = false
local loading = false

-- Load PR + comments for the current repo. Idempotent.
-- force: re-fetch even if already loaded
-- callback: optional function() called on success
function M.load(force, callback)
  if loaded and not force then
    if callback then
      callback()
    end
    return
  end
  if loading then
    return
  end
  loading = true

  pr.detect(function(err, found_pr)
    if err then
      vim.notify('[BbReview] ' .. err, vim.log.levels.WARN)
      loading = false
      return
    end
    if not found_pr then
      loading = false
      return
    end

    local title = found_pr.title or ''
    local from = (found_pr.fromRef or {}).displayId or '?'
    local to = (found_pr.toRef or {}).displayId or '?'
    vim.notify(('[BbReview] PR #%d bound: %s → %s'):format(found_pr.id, from, to), vim.log.levels.INFO)

    pr.fetch_comments(function(cerr, _)
      loading = false
      if cerr then
        vim.notify('[BbReview] Failed to fetch comments: ' .. cerr, vim.log.levels.WARN)
        return
      end
      loaded = true
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          gutter.refresh(bufnr)
        end
      end
      if callback then
        callback()
      end
    end)
  end)
end

-- Jump to the next/previous commented line in the current file
local function jump_comment(direction)
  local bufnr = vim.api.nvim_get_current_buf()
  local path = pr.relative_path(bufnr)
  if not path then
    return
  end

  local by_line = pr.state.by_file_line[path]
  if not by_line then
    return
  end

  local commented_lines = {}
  for line_num, threads in pairs(by_line) do
    if #threads > 0 then
      table.insert(commented_lines, line_num)
    end
  end
  if #commented_lines == 0 then
    return
  end
  table.sort(commented_lines)

  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local target

  if direction == 'next' then
    for _, ln in ipairs(commented_lines) do
      if ln > cursor then
        target = ln
        break
      end
    end
    if not target then
      target = commented_lines[1]
    end -- wrap
  else
    for i = #commented_lines, 1, -1 do
      if commented_lines[i] < cursor then
        target = commented_lines[i]
        break
      end
    end
    if not target then
      target = commented_lines[#commented_lines]
    end -- wrap
  end

  local row = math.min(target, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  vim.cmd 'normal! zz'
end

-- Main action: open comment thread / post new comment on current line
local function open_comment()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local file_path = pr.relative_path(bufnr)
  if not file_path then
    vim.notify('[BbReview] Buffer is not inside a git repo', vim.log.levels.WARN)
    return
  end

  local function do_open()
    local threads = pr.get_threads(file_path, line)

    local function do_reply(parent_id)
      local title = parent_id and 'Reply' or ('Comment on line ' .. line)
      ui.open_input(title, function(text)
        if parent_id then
          pr.post_reply(parent_id, text, function(cerr, _)
            if cerr then
              vim.notify('[BbReview] Reply failed: ' .. cerr, vim.log.levels.ERROR)
            else
              vim.notify('[BbReview] Reply posted.', vim.log.levels.INFO)
              gutter.refresh(bufnr)
            end
          end)
        else
          pr.post_comment(file_path, line, text, function(cerr, _)
            if cerr then
              vim.notify('[BbReview] Comment failed: ' .. cerr, vim.log.levels.ERROR)
            else
              vim.notify('[BbReview] Comment posted.', vim.log.levels.INFO)
              gutter.refresh(bufnr)
            end
          end)
        end
      end)
    end

    if #threads > 0 then
      ui.open_thread(threads, do_reply)
    else
      do_reply(nil)
    end
  end

  if not loaded then
    M.load(false, function()
      if not pr.state.pr then
        vim.notify('[BbReview] No open PR for this branch.', vim.log.levels.INFO)
        return
      end
      do_open()
    end)
  else
    if not pr.state.pr then
      vim.notify('[BbReview] No open PR for this branch.', vim.log.levels.INFO)
      return
    end
    do_open()
  end
end

-- Telescope picker over all inline PR comments
local function search_comments()
  if not pr.state.pr then
    vim.notify('[BbReview] No PR bound.', vim.log.levels.INFO)
    return
  end

  local ok_tel = pcall(require, 'telescope')
  if not ok_tel then
    vim.notify('[BbReview] Telescope not available.', vim.log.levels.WARN)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local entry_display = require 'telescope.pickers.entry_display'

  local git_root = pr.git_root() or ''

  -- Collect every comment (top-level + replies) as a flat list
  local entries = {}
  local function collect(comment, path, line, depth)
    local author = (comment.author and comment.author.displayName) or 'Unknown'
    local preview = (comment.text or ''):gsub('%s+', ' ')
    table.insert(entries, {
      path = path,
      abs_path = git_root .. '/' .. path,
      line = line,
      author = author,
      preview = preview,
      depth = depth,
    })
    for _, reply in ipairs(comment.comments or {}) do
      collect(reply, path, line, depth + 1)
    end
  end

  for path, by_line in pairs(pr.state.by_file_line) do
    for line_num, comments in pairs(by_line) do
      for _, comment in ipairs(comments) do
        collect(comment, path, line_num, 0)
      end
    end
  end

  if #entries == 0 then
    vim.notify('[BbReview] No inline comments found.', vim.log.levels.INFO)
    return
  end

  table.sort(entries, function(a, b)
    if a.path ~= b.path then
      return a.path < b.path
    end
    if a.line ~= b.line then
      return a.line < b.line
    end
    return a.depth < b.depth
  end)

  -- Column-aligned display: file:line │ author │ preview
  local displayer = entry_display.create {
    separator = '  ',
    items = {
      { width = 6 }, -- line number
      { width = 30 }, -- author (truncated)
      { remaining = true }, -- comment preview
    },
  }

  local function make_display(entry)
    local v = entry.value
    local author = #v.author > 28 and v.author:sub(1, 27) .. '…' or v.author
    return displayer {
      { tostring(v.line), 'TelescopeResultsNumber' },
      { author, 'BbReviewAuthor' },
      { v.preview, 'TelescopeResultsComment' },
    }
  end

  pickers
    .new({}, {
      prompt_title = string.format('PR #%d Comments', pr.state.pr.id),
      finder = finders.new_table {
        results = entries,
        entry_maker = function(e)
          return {
            value = e,
            display = make_display,
            -- Keep ordinal short: long strings cause fzy to match almost anything
            ordinal = vim.fn.fnamemodify(e.path, ':t') .. ' ' .. e.author .. ' ' .. e.preview:sub(1, 120),
            filename = e.abs_path,
            lnum = e.line,
          }
        end,
      },
      sorter = require('telescope.sorters').get_fzy_sorter(),
      previewer = conf.grep_previewer {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local sel = action_state.get_selected_entry()
          if not sel then
            return
          end
          vim.cmd('edit ' .. vim.fn.fnameescape(sel.value.abs_path))
          local target = math.min(sel.value.line, vim.api.nvim_buf_line_count(0))
          vim.api.nvim_win_set_cursor(0, { target, 0 })
          vim.cmd 'normal! zz'
        end)
        return true
      end,
    })
    :find()
end

-- Telescope picker: all files changed in the PR, with inline diff preview
local function browse_pr_files()
  if not pr.state.pr then
    vim.notify('[BbReview] No PR bound.', vim.log.levels.INFO)
    return
  end
  if not pcall(require, 'telescope') then
    vim.notify('[BbReview] Telescope not available.', vim.log.levels.WARN)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local entry_display = require 'telescope.pickers.entry_display'
  local previewers = require 'telescope.previewers'

  local git_root = pr.git_root() or ''

  -- Collect changed files from git
  local r = vim.system({ 'git', 'diff', 'development...HEAD', '--name-status' }, { text = true }):wait()
  if r.code ~= 0 or not r.stdout or vim.trim(r.stdout) == '' then
    vim.notify('[BbReview] No changed files found.', vim.log.levels.INFO)
    return
  end

  local entries = {}
  for _, line in ipairs(vim.split(r.stdout, '\n', { plain = true })) do
    if line ~= '' then
      local status, path = line:match '^(%a+)\t(.+)$'
      if status and path then
        -- Renames: "R100\told\tnew" — take the new path
        if status:sub(1, 1) == 'R' then
          local _, new_p = path:match '^(.+)\t(.+)$'
          if new_p then
            path = new_p
          end
          status = 'R'
        else
          status = status:sub(1, 1)
        end
        local by_line = pr.state.by_file_line[path] or {}
        local n_comments = 0
        for _, threads in pairs(by_line) do
          n_comments = n_comments + #threads
        end
        table.insert(entries, {
          status = status,
          path = path,
          abs_path = git_root .. '/' .. path,
          n_comments = n_comments,
        })
      end
    end
  end

  if #entries == 0 then
    vim.notify('[BbReview] No changed files found.', vim.log.levels.INFO)
    return
  end

  -- Files with comments first, then alphabetical
  table.sort(entries, function(a, b)
    if a.n_comments ~= b.n_comments then
      return a.n_comments > b.n_comments
    end
    return a.path < b.path
  end)

  local status_hl = { M = 'DiagnosticWarn', A = 'DiagnosticOk', D = 'DiagnosticError', R = 'DiagnosticInfo' }

  local displayer = entry_display.create {
    separator = '  ',
    items = { { width = 1 }, { width = 5 }, { remaining = true } },
  }

  local function make_display(entry)
    local v = entry.value
    local badge = v.n_comments > 0 and ('💬' .. v.n_comments) or ''
    return displayer {
      { v.status, status_hl[v.status] or 'Normal' },
      { badge, 'BbReviewAuthor' },
      { v.path, 'TelescopeResultsIdentifier' },
    }
  end

  -- Terminal diff previewer — pipes through delta for syntax-highlighted diffs
  local diff_prev = previewers.new_termopen_previewer {
    title = 'PR Diff',
    get_command = function(entry)
      return { 'bash', '-c', string.format('git diff development...HEAD -- %s | delta', vim.fn.shellescape(entry.value.path)) }
    end,
  }

  pickers
    .new({}, {
      prompt_title = string.format('PR #%d Files', pr.state.pr.id),
      finder = finders.new_table {
        results = entries,
        entry_maker = function(e)
          return {
            value = e,
            display = make_display,
            ordinal = e.status .. ' ' .. e.path,
            filename = e.abs_path,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = diff_prev,
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local sel = action_state.get_selected_entry()
          if sel then
            vim.cmd('edit ' .. vim.fn.fnameescape(sel.value.abs_path))
          end
        end)
        return true
      end,
    })
    :find()
end

function M.setup()
  local remote = vim.fn.system('git remote get-url origin 2>/dev/null'):gsub('%s+$', '')
  if not remote:find('git.rakuten-it.com', 1, true) then
    return
  end

  vim.keymap.set('n', '<leader>cc', open_comment, { desc = 'PR [C]omment on line' })

  vim.keymap.set('n', ']p', function()
    jump_comment 'next'
  end, { desc = 'Next PR comment' })
  vim.keymap.set('n', '[p', function()
    jump_comment 'prev'
  end, { desc = 'Previous PR comment' })

  vim.keymap.set('n', '<leader>cs', search_comments, { desc = 'PR [C]omments [S]earch' })
  vim.keymap.set('n', '<leader>cf', browse_pr_files, { desc = 'PR [C]hanged [F]iles' })

  vim.keymap.set('n', '<leader>cr', function()
    loaded = false
    M.load(true)
  end, { desc = 'PR [C]omments [R]efresh' })

  vim.keymap.set('n', '<leader>ci', function()
    if pr.state.pr then
      local p = pr.state.pr
      local from = (p.fromRef or {}).displayId or '?'
      local to = (p.toRef or {}).displayId or '?'
      vim.notify(('[BbReview] PR #%d: %s\n  %s → %s'):format(p.id, p.title or '', from, to), vim.log.levels.INFO)
    else
      vim.notify('[BbReview] No PR bound for this branch.', vim.log.levels.INFO)
    end
  end, { desc = 'PR [C]omments [I]nfo' })

  vim.keymap.set('n', '<leader>cd', function()
    if not pr.state.pr then
      vim.notify('[BbReview] No PR bound', vim.log.levels.WARN)
      return
    end
    local api = require 'bitbucket_review.api'
    local url = ('%s/rest/api/1.0/projects/%s/repos/%s/pull-requests/%d/activities?limit=10'):format(
      pr.state.base_url,
      pr.state.project,
      pr.state.repo,
      pr.state.pr.id
    )
    api.get(url, function(err, data)
      if err then
        vim.notify('[BbReview] Debug fetch error: ' .. err, vim.log.levels.ERROR)
        return
      end
      local lines = { '[BbReview] Raw activities (first 10):' }
      for i, act in ipairs(data.values or {}) do
        local action = tostring(act.action)
        local c = act.comment
        if c then
          local a = c.anchor
          local path_val = a and (type(a.path) == 'table' and vim.inspect(a.path) or tostring(a.path or '(nil)')) or '(no anchor)'
          local line_val = a and tostring(a.line or '(nil)') or '(no anchor)'
          local has_parent = c.parent and tostring(c.parent.id) or 'none'
          table.insert(lines, string.format('  [%d] action=%s  anchor.path=%s  anchor.line=%s  parent=%s', i, action, path_val, line_val, has_parent))
        else
          table.insert(lines, string.format('  [%d] action=%s  (no comment)', i, action))
        end
      end
      local buf_path = pr.relative_path(0)
      table.insert(lines, 'Buffer relative path: ' .. (buf_path or '(nil)'))
      table.insert(lines, 'Indexed paths: ' .. vim.inspect(vim.tbl_keys(pr.state.by_file_line)))
      vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
    end)
  end, { desc = 'PR [C]omments [D]ebug' })

  -- Auto-load on first BufEnter; refresh gutter when returning to a buffer
  local group = vim.api.nvim_create_augroup('BbReview', { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(ev)
      if not loaded and not loading then
        M.load(false)
      else
        gutter.refresh(ev.buf)
      end
    end,
  })
end

return M
