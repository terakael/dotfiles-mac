-- Core logic for DBUI rainbow highlighting
-- Handles column detection and syntax pattern generation

local M = {}
local colors_util = require 'custom.dbui-rainbow.colors'

-- Default configuration
M.config = {
  enabled = true,
  style = 'grid', -- 'grid', 'columns', 'rows', 'off'
  max_columns = 20, -- Increased default for typical DBUI queries
  colors = nil, -- nil = use defaults
}

-- Setup function to merge user config
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

-- Detect column boundaries from DBUI table separator line
-- Handles two formats:
-- 1. MySQL/Postgres style: +----------+----------+
-- 2. SQLite/other style:   ---  ---  ---
-- @param bufnr number: Buffer number
-- @return table|nil: Array of {start, end} column positions, or nil if detection fails
function M.detect_columns(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, math.min(10, vim.api.nvim_buf_line_count(bufnr)), false)
  local separator_line = nil
  local separator_line_num = nil
  local header_line_num = nil

  -- Find the separator line (can be line 1 or 2)
  for i, line in ipairs(lines) do
    -- Check for different separator formats:
    -- 1. SQLite format: ---  ----  --- (dashes with spaces)
    -- 2. MySQL format: +----+-----+----+ (starts and ends with +)
    -- 3. PostgreSQL format:  ---------+-----------+-----+ (dashes with + in middle, may have leading space)
    if line:match '^%s*[-]+%s+[-]+' or line:match '^%s*%+[-+]+%+$' or line:match '^%s*[-]+%+[-+]+' then
      separator_line = line
      separator_line_num = i

      -- Header is either before or after separator
      if i > 1 then
        -- SQLite/PostgreSQL format or MySQL with header above separator
        header_line_num = i - 1
      elseif i < #lines and lines[i + 1]:match '^|' then
        -- MySQL format with header below separator (rare)
        header_line_num = i + 1
      end
      break
    end
  end

  if not separator_line then
    return nil
  end

  -- Parse column positions based on format
  local columns = {}

  -- Check format type
  if separator_line:match '^%+[-+]+%+$' then
    -- MySQL format: +----+-----+----+
    -- Split by + to find column boundaries
    local pos = 1
    for i = 2, #separator_line do -- Start at 2 to skip first +
      local char = separator_line:sub(i, i)
      if char == '+' then
        -- Found column boundary
        table.insert(columns, {
          start_col = pos + 1, -- Skip the + itself
          end_col = i - 1,
        })
        pos = i
      end
    end
  elseif separator_line:match '^%s*[-]+%+[-+]+' then
    -- PostgreSQL format:  ---------+-----------+---------+ (may have leading space)
    -- Split by + to find column boundaries (+ marks boundaries between columns)
    local pos = 1
    for i = 1, #separator_line do
      local char = separator_line:sub(i, i)
      if char == '+' then
        -- Found column boundary
        table.insert(columns, {
          start_col = pos,
          end_col = i - 1,
        })
        pos = i + 1
      end
    end

    -- Handle last column (after the last +)
    if pos <= #separator_line then
      table.insert(columns, {
        start_col = pos,
        end_col = #separator_line,
      })
    end
  else
    -- SQLite format: ---  ----  ---
    -- Find transitions between dashes and spaces
    local in_separator = false
    local col_start = nil

    for i = 1, #separator_line do
      local char = separator_line:sub(i, i)
      local is_dash = (char == '-')

      if is_dash and not in_separator then
        -- Start of a column separator
        col_start = i
        in_separator = true
      elseif not is_dash and in_separator then
        -- End of column separator (hit a space)
        if col_start then
          table.insert(columns, {
            start_col = col_start,
            end_col = i - 1,
          })
        end
        in_separator = false
        col_start = nil
      end
    end

    -- Handle last column if line ends with dashes
    if in_separator and col_start then
      table.insert(columns, {
        start_col = col_start,
        end_col = #separator_line,
      })
    end
  end

  -- Don't colorize if we have too many columns (performance)
  if #columns > M.config.max_columns then
    vim.notify(string.format('DBUI Rainbow: Too many columns (%d > %d), disabling for this buffer', #columns, M.config.max_columns), vim.log.levels.WARN)
    return nil
  end

  if #columns == 0 then
    return nil
  end

  return {
    columns = columns,
    header_line = header_line_num or separator_line_num,
    separator_line = separator_line_num,
  }
end

-- Setup highlight groups for rainbow colors
function M.setup_highlights()
  local base_colors = M.config.colors or colors_util.get_default_colors()

  -- Get background colors for alternating rows
  -- Use a subtle background similar to cursorline
  local bg_normal = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg or 0x1e1e1e
  local bg_cursorline = vim.api.nvim_get_hl(0, { name = 'CursorLine' }).bg or (bg_normal + 0x0a0a0a)

  -- Convert to hex strings if they're numbers
  if type(bg_normal) == 'number' then
    bg_normal = string.format('#%06x', bg_normal)
  end
  if type(bg_cursorline) == 'number' then
    bg_cursorline = string.format('#%06x', bg_cursorline)
  end

  -- Create highlight groups for each column
  for i = 1, #base_colors do
    -- Odd rows (no background, just colored text)
    local hl_odd = string.format('DboutCol%dRow0', i)
    vim.api.nvim_set_hl(0, hl_odd, { fg = base_colors[i] })

    -- Even rows (with subtle background)
    local hl_even = string.format('DboutCol%dRow1', i)
    vim.api.nvim_set_hl(0, hl_even, { fg = base_colors[i], bg = bg_cursorline })
  end

  -- Create header highlight groups (bold + rainbow colors)
  for i = 1, #base_colors do
    local hl_header = string.format('DboutHeaderCol%d', i)
    vim.api.nvim_set_hl(0, hl_header, { fg = base_colors[i], bold = true })
  end

  -- Create separator highlight groups (rainbow colors, no bold)
  for i = 1, #base_colors do
    local hl_separator = string.format('DboutSeparatorCol%d', i)
    vim.api.nvim_set_hl(0, hl_separator, { fg = base_colors[i] })
  end
end

-- Apply rainbow syntax to a buffer
-- @param bufnr number: Buffer number
function M.apply_syntax(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Check if enabled
  if not M.config.enabled or M.config.style == 'off' then
    return
  end

  -- Detect columns
  local detection = M.detect_columns(bufnr)
  if not detection then
    return
  end

  local columns = detection.columns
  local header_line = detection.header_line
  local separator_line = detection.separator_line

  -- Store in buffer variable for reference
  vim.b[bufnr].dbui_rainbow_columns = columns
  vim.b[bufnr].dbui_rainbow_header_line = header_line
  vim.b[bufnr].dbui_rainbow_separator_line = separator_line

  -- Setup highlights if not already done
  M.setup_highlights()

  -- Clear any existing syntax
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd 'syntax clear'
  end)

  -- Apply syntax based on style
  if M.config.style == 'grid' then
    -- Use extmarks for grid mode (better control over row/column intersection)
    M.apply_row_alternating_extmarks(bufnr, separator_line, columns)
  elseif M.config.style == 'columns' then
    M.apply_column_syntax(bufnr, columns, separator_line)
  elseif M.config.style == 'rows' then
    M.apply_row_syntax(bufnr, separator_line)
  end

  -- Apply rainbow colors to header columns
  if header_line > 0 then
    M.apply_header_colors(bufnr, header_line, columns)
  end

  -- Apply rainbow colors to separator line
  if separator_line > 0 then
    M.apply_separator_colors(bufnr, separator_line, columns)
  end
end

-- Apply rainbow colors to a specific line with column-based highlighting
-- @param bufnr number: Buffer number
-- @param line_num number: Line number (1-indexed)
-- @param columns table: Column boundaries
-- @param hl_group_prefix string: Prefix for highlight group names (e.g., 'DboutHeaderCol', 'DboutSeparatorCol')
-- @param namespace string: Namespace for extmarks
local function apply_line_colors(bufnr, line_num, columns, hl_group_prefix, namespace)
  local base_colors = M.config.colors or colors_util.get_default_colors()
  local ns_id = vim.api.nvim_create_namespace(namespace)

  -- Clear existing extmarks
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line_num - 1, line_num)

  -- Get the line content
  local line_content = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
  if not line_content then
    return
  end

  -- Apply color to each column
  for col_idx, col in ipairs(columns) do
    local color_idx = ((col_idx - 1) % #base_colors) + 1
    local start_col = col.start_col - 1 -- Convert to 0-indexed
    local end_col = col.end_col

    if start_col < #line_content then
      pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, line_num - 1, start_col, {
        end_col = math.min(end_col, #line_content),
        hl_group = hl_group_prefix .. color_idx,
        priority = 110, -- Higher priority than data rows to ensure visibility
      })
    end
  end
end

-- Apply rainbow colors to header columns
-- @param bufnr number: Buffer number
-- @param header_line number: Line number of the header (1-indexed)
-- @param columns table: Column boundaries
function M.apply_header_colors(bufnr, header_line, columns)
  apply_line_colors(bufnr, header_line, columns, 'DboutHeaderCol', 'dbui_rainbow_header')
end

-- Apply rainbow colors to separator line
-- @param bufnr number: Buffer number
-- @param separator_line number: Line number of the separator (1-indexed)
-- @param columns table: Column boundaries
function M.apply_separator_colors(bufnr, separator_line, columns)
  apply_line_colors(bufnr, separator_line, columns, 'DboutSeparatorCol', 'dbui_rainbow_separator')
end

-- Apply column-based rainbow syntax
-- @param bufnr number: Buffer number
-- @param columns table: Column boundaries
-- @param separator_line number: Line number of separator (data starts after this)
function M.apply_column_syntax(bufnr, columns, separator_line)
  local base_colors = M.config.colors or colors_util.get_default_colors()

  vim.api.nvim_buf_call(bufnr, function()
    for i, col in ipairs(columns) do
      local color_idx = ((i - 1) % #base_colors) + 1
      local start_col = col.start_col
      local end_col = col.end_col

      if start_col and end_col then
        -- Simple approach: just color the columns without row alternating for now
        -- We'll use extmarks for row alternating instead
        local pattern = string.format('\\%%>%dl\\%%%dc.\\{-}\\%%%dc', separator_line, start_col, end_col)

        pcall(function()
          vim.cmd(string.format('syntax match DboutCol%dRow0 /%s/', color_idx, pattern))
        end)
      end
    end
  end)
end

-- Apply row alternating with extmarks (more reliable than syntax)
-- @param bufnr number: Buffer number
-- @param separator_line number: Line number of separator (data starts after this)
-- @param columns table: Column boundaries
function M.apply_row_alternating_extmarks(bufnr, separator_line, columns)
  -- Clear existing namespace
  local ns_id = vim.api.nvim_create_namespace 'dbui_rainbow_rows'
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local base_colors = M.config.colors or colors_util.get_default_colors()

  -- Find where data actually starts (skip all header/separator lines)
  -- Data starts after we've seen: separator, header row, separator
  local data_start = nil
  local seen_separator_count = 0

  for i = 1, math.min(10, line_count) do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]

    -- Count separators
    if line and (line:match '^%+[-+]+%+$' or line:match '^[-]+%s+[-]+') then
      seen_separator_count = seen_separator_count + 1

      -- After 2nd separator (or 1st in SQLite format), next line with | is data
      if seen_separator_count >= 2 or line:match '^[-]+%s+[-]+' then
        -- Next non-separator line is data
        for j = i + 1, math.min(i + 3, line_count) do
          local next_line = vim.api.nvim_buf_get_lines(bufnr, j - 1, j, false)[1]
          if next_line and not next_line:match '^%+[-+]+%+$' and not next_line:match '^[-]+%s+[-]+' then
            data_start = j
            break
          end
        end
        if data_start then
          break
        end
      end
    end
  end

  if not data_start then
    data_start = separator_line + 1 -- Default fallback: data starts right after separator
  end

  local row_counter = 0 -- Track actual data rows

  for line_num = data_start, line_count do
    local line_content = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]

    -- Skip separator lines
    if line_content and not line_content:match '^%+[-+]+%+$' and not line_content:match '^[-]+%s+[-]+' then
      -- Determine if odd or even row
      local is_even_row = (row_counter % 2) == 1

      -- Apply color to each column
      for col_idx, col in ipairs(columns) do
        local color_idx = ((col_idx - 1) % #base_colors) + 1

        -- Add extmark for this column
        -- Even rows get background color, odd rows don't
        local start_col = col.start_col - 1 -- 0-indexed
        local end_col = col.end_col -- exclusive end

        if start_col < #line_content then
          pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, line_num - 1, start_col, {
            end_col = math.min(end_col, #line_content),
            hl_group = 'DboutCol' .. color_idx .. (is_even_row and 'Row1' or 'Row0'),
            priority = 100,
          })
        end
      end

      row_counter = row_counter + 1 -- Increment for next row
    end
  end
end

-- Apply row alternating syntax (for 'rows' or 'grid' style)
-- @param bufnr number: Buffer number
-- @param separator_line number: Line number of separator (not currently used, kept for API compatibility)
function M.apply_row_syntax(bufnr, separator_line)
  -- For grid mode, we use extmarks instead
  -- This function is now a no-op, replaced by apply_row_alternating_extmarks
end

-- Toggle between rainbow styles
function M.toggle_style()
  local styles = { 'grid', 'columns', 'rows', 'off' }
  local current_idx = 1

  for i, style in ipairs(styles) do
    if M.config.style == style then
      current_idx = i
      break
    end
  end

  local next_idx = (current_idx % #styles) + 1
  M.config.style = styles[next_idx]

  -- Reapply syntax to current buffer
  M.apply_syntax()

  vim.notify(string.format('DBUI Rainbow style: %s', M.config.style), vim.log.levels.INFO)
end

-- Set specific style
function M.set_style(style)
  local valid_styles = { 'grid', 'columns', 'rows', 'off' }
  if not vim.tbl_contains(valid_styles, style) then
    vim.notify(string.format('Invalid style: %s. Valid: %s', style, table.concat(valid_styles, ', ')), vim.log.levels.ERROR)
    return
  end

  M.config.style = style
  M.apply_syntax()
  vim.notify(string.format('DBUI Rainbow style: %s', style), vim.log.levels.INFO)
end

-- Show info about current rainbow configuration
function M.show_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local columns = vim.b[bufnr].dbui_rainbow_columns or {}

  local info = {
    'DBUI Rainbow Info:',
    string.format('  Style: %s', M.config.style),
    string.format('  Enabled: %s', M.config.enabled),
    string.format('  Row dimming: %.0f%%', M.config.row_dimming * 100),
    string.format('  Columns detected: %d', #columns),
    string.format('  Max columns: %d', M.config.max_columns),
  }

  vim.notify(table.concat(info, '\n'), vim.log.levels.INFO)
end

return M
