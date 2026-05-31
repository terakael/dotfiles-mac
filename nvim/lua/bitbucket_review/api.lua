-- Bitbucket Server REST API client
-- Uses BITBUCKET_BEARER_TOKEN env var for auth
local M = {}

local function get_token()
  return os.getenv 'BITBUCKET_BEARER_TOKEN'
end

-- Simple URL encoding for query parameter values
local function urlencode(str)
  if not str then
    return ''
  end
  return str:gsub('([^%w%-_%.~])', function(c)
    return string.format('%%%02X', string.byte(c))
  end)
end

M.urlencode = urlencode

-- Async GET. callback(err_string_or_nil, decoded_table_or_nil)
function M.get(url, callback)
  local token = get_token()
  if not token then
    callback('BITBUCKET_BEARER_TOKEN not set', nil)
    return
  end
  vim.system({ 'curl', '-s', '-H', 'Authorization: Bearer ' .. token, '-H', 'Accept: application/json', url }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback('curl error (' .. result.code .. '): ' .. (result.stderr or ''), nil)
        return
      end
      local ok, data = pcall(vim.json.decode, result.stdout or '')
      if not ok then
        callback('JSON decode failed', nil)
        return
      end
      if data.errors then
        local msg = (data.errors[1] or {}).message or 'Bitbucket API error'
        callback(msg, nil)
        return
      end
      callback(nil, data)
    end)
  end)
end

-- Async POST with JSON body. callback(err, decoded_response)
function M.post(url, body, callback)
  local token = get_token()
  if not token then
    callback('BITBUCKET_BEARER_TOKEN not set', nil)
    return
  end
  local json_body = vim.json.encode(body)
  vim.system({
    'curl',
    '-s',
    '-X',
    'POST',
    '-H',
    'Authorization: Bearer ' .. token,
    '-H',
    'Content-Type: application/json',
    '-H',
    'Accept: application/json',
    '-d',
    json_body,
    url,
  }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback('curl error (' .. result.code .. '): ' .. (result.stderr or ''), nil)
        return
      end
      local ok, data = pcall(vim.json.decode, result.stdout or '')
      if not ok then
        callback('JSON decode failed', nil)
        return
      end
      if data.errors then
        local msg = (data.errors[1] or {}).message or 'Bitbucket API error'
        callback(msg, nil)
        return
      end
      callback(nil, data)
    end)
  end)
end

-- Paginated GET — fetches all pages and merges values[].
-- callback(err, all_values_list)
function M.get_all(base_url, callback)
  local sep = base_url:find '?' and '&' or '?'
  local all = {}
  local function fetch(start)
    local url = base_url .. sep .. 'limit=1000&start=' .. start
    M.get(url, function(err, data)
      if err then
        callback(err, nil)
        return
      end
      for _, v in ipairs(data.values or {}) do
        table.insert(all, v)
      end
      if data.isLastPage == false and data.nextPageStart then
        fetch(data.nextPageStart)
      else
        callback(nil, all)
      end
    end)
  end
  fetch(0)
end

return M
