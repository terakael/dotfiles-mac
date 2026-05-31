-- Comment.nvim - Easy code commenting
-- https://github.com/numToStr/Comment.nvim

return {
  'numToStr/Comment.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    require('Comment').setup {
      -- Add a space b/w comment and the line
      padding = true,
      -- Whether the cursor should stay at its position
      sticky = true,
      -- LHS of toggle mappings in NORMAL mode
      toggler = {
        line = 'gcc', -- Line-comment toggle keymap
        block = 'gbc', -- Block-comment toggle keymap
      },
      -- LHS of operator-pending mappings in NORMAL and VISUAL mode
      opleader = {
        line = 'gc', -- Line-comment keymap
        block = 'gb', -- Block-comment keymap
      },
    }
  end,
}
