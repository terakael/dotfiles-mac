-- Color manipulation utilities for DBUI rainbow highlighting
-- Provides functions to dim colors and convert between color spaces

local M = {}

-- Convert hex color to RGB components
-- @param hex string: Color in hex format (e.g., "#89ddff" or "89ddff")
-- @return table: {r, g, b} with values 0-255
function M.hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return {
    r = tonumber(hex:sub(1, 2), 16),
    g = tonumber(hex:sub(3, 4), 16),
    b = tonumber(hex:sub(5, 6), 16),
  }
end

-- Convert RGB to hex color
-- @param rgb table: {r, g, b} with values 0-255
-- @return string: Color in hex format (e.g., "#89ddff")
function M.rgb_to_hex(rgb)
  return string.format('#%02x%02x%02x', math.floor(rgb.r), math.floor(rgb.g), math.floor(rgb.b))
end

-- Convert RGB to HSV color space
-- @param rgb table: {r, g, b} with values 0-255
-- @return table: {h, s, v} where h=0-360, s=0-1, v=0-1
function M.rgb_to_hsv(rgb)
  local r, g, b = rgb.r / 255, rgb.g / 255, rgb.b / 255
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local delta = max - min

  local h, s, v
  v = max

  if delta < 0.00001 then
    s = 0
    h = 0
    return { h = h, s = s, v = v }
  end

  if max > 0 then
    s = delta / max
  else
    s = 0
    h = 0
    return { h = h, s = s, v = v }
  end

  if r >= max then
    h = (g - b) / delta
  elseif g >= max then
    h = 2.0 + (b - r) / delta
  else
    h = 4.0 + (r - g) / delta
  end

  h = h * 60
  if h < 0 then
    h = h + 360
  end

  return { h = h, s = s, v = v }
end

-- Convert HSV to RGB color space
-- @param hsv table: {h, s, v} where h=0-360, s=0-1, v=0-1
-- @return table: {r, g, b} with values 0-255
function M.hsv_to_rgb(hsv)
  local h, s, v = hsv.h, hsv.s, hsv.v

  if s <= 0 then
    return { r = v * 255, g = v * 255, b = v * 255 }
  end

  local hh = h
  if hh >= 360 then
    hh = 0
  end
  hh = hh / 60

  local i = math.floor(hh)
  local ff = hh - i
  local p = v * (1.0 - s)
  local q = v * (1.0 - (s * ff))
  local t = v * (1.0 - (s * (1.0 - ff)))

  local r, g, b
  if i == 0 then
    r, g, b = v, t, p
  elseif i == 1 then
    r, g, b = q, v, p
  elseif i == 2 then
    r, g, b = p, v, t
  elseif i == 3 then
    r, g, b = p, q, v
  elseif i == 4 then
    r, g, b = t, p, v
  else
    r, g, b = v, p, q
  end

  return {
    r = r * 255,
    g = g * 255,
    b = b * 255,
  }
end

-- Dim a color by reducing its brightness (value in HSV)
-- @param hex string: Color in hex format
-- @param factor number: Dimming factor (0.0-1.0, where 1.0 = no change, 0.75 = 75% brightness)
-- @return string: Dimmed color in hex format
function M.dim_color(hex, factor)
  factor = factor or 0.75

  local rgb = M.hex_to_rgb(hex)
  local hsv = M.rgb_to_hsv(rgb)

  -- Reduce the value (brightness) component
  hsv.v = hsv.v * factor

  local new_rgb = M.hsv_to_rgb(hsv)
  return M.rgb_to_hex(new_rgb)
end

-- Get the default Forest theme rainbow colors
-- @return table: Array of hex color strings
function M.get_default_colors()
  return {
    '#89ddff', -- Cyan
    '#f9cd60', -- Yellow
    '#a9dc76', -- Green
    '#ff66cc', -- Magenta
    '#79b8ff', -- Blue
    '#ff9955', -- Orange
  }
end

-- Generate dimmed variants of all colors
-- @param colors table: Array of hex color strings
-- @param factor number: Dimming factor (default: 0.75)
-- @return table: Array of dimmed hex color strings
function M.generate_dimmed_colors(colors, factor)
  factor = factor or 0.75
  local dimmed = {}
  for _, color in ipairs(colors) do
    table.insert(dimmed, M.dim_color(color, factor))
  end
  return dimmed
end

return M
