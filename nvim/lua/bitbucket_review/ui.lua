-- UI components using Snacks.win
local M = {}

local hl_ns = vim.api.nvim_create_namespace 'bb_review_ui'

-- Highlight groups — defined with default=true so a colorscheme can override them
local function setup_highlights()
  vim.api.nvim_set_hl(0, 'BbReviewHeader', { default = true, link = 'DiagnosticInfo' })
  vim.api.nvim_set_hl(0, 'BbReviewHint', { default = true, link = 'Comment' })
  vim.api.nvim_set_hl(0, 'BbReviewSep', { default = true, link = 'Comment' })
  vim.api.nvim_set_hl(0, 'BbReviewAuthor', { default = true, link = 'Title' })
  vim.api.nvim_set_hl(0, 'BbReviewTime', { default = true, link = 'Comment' })
end
setup_highlights()

-- ─ is a 3-byte UTF-8 sequence; check the raw bytes for separator detection
local SEP_CHAR = '─'

-- Apply syntax highlights to the rendered thread buffer
local function apply_highlights(buf, lines)
  vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)
  for i, line in ipairs(lines) do
    local row = i - 1 -- extmarks are 0-indexed
    local trimmed = vim.trim(line)

    if trimmed:sub(1, #SEP_CHAR) == SEP_CHAR then
      -- Separator line
      vim.api.nvim_buf_set_extmark(buf, hl_ns, row, 0, {
        end_row = row,
        end_col = #line,
        hl_group = 'BbReviewSep',
      })
    elseif line:match '^  Thread %d' then
      -- "Thread N / N" in header colour, navigation hints in muted hint colour
      local hint_byte = line:find('%s+<', 1)
      if hint_byte then
        vim.api.nvim_buf_set_extmark(buf, hl_ns, row, 0, {
          end_row = row,
          end_col = hint_byte - 1,
          hl_group = 'BbReviewHeader',
        })
        vim.api.nvim_buf_set_extmark(buf, hl_ns, row, hint_byte - 1, {
          end_row = row,
          end_col = #line,
          hl_group = 'BbReviewHint',
        })
      else
        vim.api.nvim_buf_set_extmark(buf, hl_ns, row, 0, {
          end_row = row,
          end_col = #line,
          hl_group = 'BbReviewHeader',
        })
      end
    else
      -- Author + timestamp line: ends with YYYY-MM-DD HH:MM
      local ts_start = line:find '%d%d%d%d%-%d%d%-%d%d %d%d:%d%d'
      if ts_start and ts_start > 1 then
        -- Author name (before the two spaces + timestamp)
        vim.api.nvim_buf_set_extmark(buf, hl_ns, row, 0, {
          end_row = row,
          end_col = ts_start - 3,
          hl_group = 'BbReviewAuthor',
        })
        -- Timestamp
        vim.api.nvim_buf_set_extmark(buf, hl_ns, row, ts_start - 1, {
          end_row = row,
          end_col = #line,
          hl_group = 'BbReviewTime',
        })
      end
    end
  end
end

-- Format a single comment node into display lines
local function fmt_comment(c)
  local indent = string.rep('  ', c._depth or 0)
  local author = (c.author and c.author.displayName) or 'Unknown'
  local ts = os.date('%Y-%m-%d %H:%M', math.floor((c.createdDate or 0) / 1000))
  local lines = {}
  table.insert(lines, indent .. string.rep('─', math.max(2, 44 - #indent)))
  table.insert(lines, indent .. author .. '  ' .. ts)
  table.insert(lines, indent)
  for _, l in ipairs(vim.split(c.text or '', '\n', { plain = true })) do
    table.insert(lines, indent .. l)
  end
  table.insert(lines, '')
  return lines
end

-- Render thread into buffer lines; return lines and a line->comment map (1-indexed).
local function render(threads, idx)
  local lines = {}
  local line_to_comment = {}

  if #threads == 0 then
    table.insert(lines, '  (no comments on this line)')
    return lines, line_to_comment
  end

  table.insert(lines, string.format('  Thread %d / %d    <C-p>/<C-n> navigate  <CR> reply  q close', idx, #threads))
  table.insert(lines, '')

  for _, c in ipairs(threads[idx]) do
    local first = #lines + 1
    for _, l in ipairs(fmt_comment(c)) do
      table.insert(lines, l)
    end
    -- Map every rendered line of this comment back to the comment object
    for ln = first, #lines do
      line_to_comment[ln] = c
    end
  end

  return lines, line_to_comment
end

-- Open a thread viewer popup.
-- threads: list of flat comment lists (from pr.get_threads)
-- on_reply(parent_id_or_nil): called when user wants to reply
function M.open_thread(threads, on_reply)
  local idx = 1
  local line_to_comment = {}
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'markdown'

  local function set_content()
    vim.bo[buf].modifiable = true
    local content, mapping = render(threads, idx)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    line_to_comment = mapping
    vim.bo[buf].modifiable = false
    apply_highlights(buf, content)
  end
  set_content()

  Snacks.win {
    buf = buf,
    width = 0.6,
    height = 0.45,
    position = 'float',
    title = ' PR Comments ',
    title_pos = 'center',
    border = 'rounded',
    wo = { wrap = true, linebreak = true },
    keys = {
      q = 'close',
      ['<C-n>'] = function(self)
        if idx < #threads then
          idx = idx + 1
          set_content()
        end
      end,
      ['<C-p>'] = function(self)
        if idx > 1 then
          idx = idx - 1
          set_content()
        end
      end,
      ['<CR>'] = function(self)
        local cursor_line = vim.api.nvim_win_get_cursor(self.win)[1]
        local comment = line_to_comment[cursor_line]
        local parent_id = comment and comment.id or nil
        self:close()
        vim.schedule(function()
          on_reply(parent_id)
        end)
      end,
    },
  }
end

-- Open an input window for composing a comment.
-- title: window title string
-- on_submit(text): called with comment text when user does :wq
function M.open_input(title, on_submit)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'acwrite'
  vim.bo[buf].filetype = 'markdown'
  -- Name must be unique to avoid conflicts
  local bname = 'PR Comment [' .. tostring(buf) .. ']'
  vim.api.nvim_buf_set_name(buf, bname)

  local submitted = false

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = buf,
    callback = function()
      if submitted then
        return
      end
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      -- Strip trailing blank lines
      while #lines > 0 and vim.trim(lines[#lines]) == '' do
        table.remove(lines)
      end
      local text = table.concat(lines, '\n')
      if vim.trim(text) == '' then
        vim.notify('[BbReview] Comment is empty, not posting.', vim.log.levels.WARN)
        return
      end
      submitted = true
      vim.bo[buf].modified = false
      -- Don't close the window here — let the :q part of :wq do it naturally.
      -- Closing it ourselves causes :q to then run on the wrong window.
      on_submit(text)
    end,
  })

  -- Enter insert mode only once the buffer is actually focused.
  -- Using vim.schedule risks firing while the previous (non-modifiable) window still has focus.
  vim.api.nvim_create_autocmd('BufEnter', {
    buffer = buf,
    once = true,
    callback = function()
      vim.bo[buf].modifiable = true
      vim.cmd 'startinsert'
    end,
  })

  Snacks.win {
    buf = buf,
    width = 0.6,
    height = 0.25,
    position = 'float',
    title = ' ' .. title .. ' (:wq to post  :q! to cancel) ',
    title_pos = 'center',
    border = 'rounded',
    enter = true,
    keys = {},
  }
end

return M
