# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Context
All questions and tasks in this project relate to the setup and configuration of Neovim. When answering questions, always reference the actual configuration files and settings present in this repository.
Keep your answers token-efficient.

## Common Development Commands

### Formatting
- `stylua .` - Format all Lua files using stylua (configuration in `.stylua.toml`)
- `stylua --check .` - Check formatting without modifying files

### Package Management
- `:Lazy` - Open Lazy.nvim plugin manager UI
- `:Lazy update` - Update all plugins
- `:Lazy sync` - Install/update plugins based on configuration

### LSP and Development Tools
- `:Mason` - Open Mason tool installer UI
- `:checkhealth` - Check Neovim configuration health
- `:Telescope` - Access Telescope fuzzy finder commands

## Architecture Overview

### Core Structure
This is a **kickstart.nvim** configuration - a starting point for Neovim configuration that is:
- Single-file focused (main config in `lua/init.lua`)
- Completely documented with extensive comments
- Modular with optional plugin files in `lua/kickstart/plugins/`

### Key Files
- `init.lua` - Main entry point with all core configuration (plugins, LSP, keymaps)
- `lua/kickstart/plugins/` - Optional plugin configurations (debug, lint, gitsigns, etc.)
- `lua/custom/plugins/` - User's custom plugin directory

### Plugin Management
Uses **Lazy.nvim** as the plugin manager with plugins configured in `lua/init.lua`:
- Core plugins: Telescope, LSP, Treesitter, CMP autocompletion
- Formatting: conform.nvim with stylua for Lua
- Git integration: gitsigns.nvim
- AI integration: gp.nvim (configured for Azure OpenAI)
- Colorscheme: everforest

### LSP Configuration
- **Mason** for automatic LSP server installation
- **nvim-lspconfig** for LSP configuration
- Servers configured: `lua_ls`, `pyright`
- Auto-formatting on save (except C/C++)

### Keybindings Structure
- Leader key: `<Space>`
- Prefix groups: `[C]ode`, `[D]ocument`, `[R]ename`, `[S]earch`, `[W]orkspace`, `[T]oggle`, `[H]unk`
- GPT commands use `<C-g>` prefix for AI interactions
- Window navigation: `<C-hjkl>`

### VSCode Integration
Separate configuration (`lua/init_vscode.lua`) provides VSCode-compatible keymaps:
- `<leader>sf` - Find in files
- `<leader>s.` - Quick open
- `gd` - Go to definition
- `gr` - Go to references

### Custom Extensions
Users can add plugins in `lua/custom/plugins/` directory which is automatically loaded by Lazy.nvim.

## Development Workflow
1. Edit configuration in `lua/init.lua` or add plugins in `lua/custom/plugins/`
2. Restart Neovim or use `:Lazy reload` to apply changes
3. Use `:checkhealth` to verify configuration
4. Format code with `stylua .` before committing
