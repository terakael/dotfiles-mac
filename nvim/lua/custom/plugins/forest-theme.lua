return {
  'neanias/everforest-nvim',
  name = 'everforest',
  lazy = false,
  priority = 1000,
  config = function()
    require('everforest').setup {
      colours_override = function(palette)
        -- palette.bg_dim = '#201e1c'
        palette.bg0 = '#252321'
        palette.bg1 = '#2d2a27'
        palette.bg2 = '#30312e'
        palette.bg_visual = '#3d4d45'
        -- palette.bg3 = '#353230'
        -- palette.bg4 = '#3a3733'
        -- palette.bg5 = '#3f3c39'
      end,
      on_highlights = function(hl, palette)
        -- Python / general parameter + docstring overrides
        hl['@variable.parameter'] = { fg = palette.blue }
        hl['@string.documentation'] = { fg = palette.grey1, italic = true }

        -- Mini statusline mode colors
        hl.MiniStatuslineModeVisual = { fg = palette.bg0, bg = palette.aqua, bold = true }

        -- Rainbow delimiters
        hl.RainbowDelimiterRed = { fg = palette.red }
        hl.RainbowDelimiterYellow = { fg = palette.yellow }
        hl.RainbowDelimiterBlue = { fg = palette.blue }
        hl.RainbowDelimiterOrange = { fg = palette.orange }
        hl.RainbowDelimiterGreen = { fg = palette.green }
        hl.RainbowDelimiterViolet = { fg = palette.purple }
        hl.RainbowDelimiterCyan = { fg = palette.aqua }

        -- Helm/gotmpl template delimiters
        hl['@punctuation.bracket.helm'] = { fg = palette.red, bold = true }
        hl['@punctuation.bracket.gotmpl'] = { fg = palette.red, bold = true }

        -- Helm built-in constants (.Values, .Release, .Chart)
        hl['@constant.builtin.helm'] = { fg = palette.purple, bold = true }
        hl['@constant.builtin.gotmpl'] = { fg = palette.purple, bold = true }

        -- Helm template variables
        hl['@variable.member.helm'] = { fg = palette.yellow }
        hl['@variable.member.gotmpl'] = { fg = palette.yellow }

        -- Helm/gotmpl built-in functions (Sprig etc.)
        hl['@function.builtin.helm'] = { fg = palette.green, bold = true }
        hl['@function.builtin.gotmpl'] = { fg = palette.green, bold = true }

        -- YAML
        hl['@property.yaml'] = { fg = palette.blue, bold = true }
        hl['@string.yaml'] = { fg = palette.aqua }

        -- Markdown (restore colors from old forest theme)
        hl['@markup.strong'] = { fg = palette.yellow, bold = true }
        hl['@markup.italic'] = { fg = palette.purple, italic = true }
        hl['@markup.raw'] = { fg = palette.green }
        hl['@markup.list'] = { fg = palette.aqua }
        hl['@markup.quote'] = { fg = palette.grey1, italic = true }
        hl['@markup.link'] = { fg = palette.blue, underline = true }
        hl['@markup.link.label'] = { fg = palette.aqua }
        hl['@markup.link.url'] = { fg = palette.blue, italic = true }
      end,
    }
    vim.cmd.colorscheme 'everforest'
  end,
}
