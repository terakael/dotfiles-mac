-- Rainbow delimiters for better bracket visibility
-- Shows matching brackets in different colors

return {
  'HiPhish/rainbow-delimiters.nvim',
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    -- Setup rainbow delimiters with global strategy for all languages
    require('rainbow-delimiters.setup').setup {
      strategy = {
        [''] = require('rainbow-delimiters').strategy['global'],
      },
      query = {
        [''] = 'rainbow-delimiters',
      },
      highlight = {
        'RainbowDelimiterRed',
        'RainbowDelimiterYellow',
        'RainbowDelimiterBlue',
        'RainbowDelimiterOrange',
        'RainbowDelimiterGreen',
        'RainbowDelimiterViolet',
        'RainbowDelimiterCyan',
      },
    }
  end,
}
