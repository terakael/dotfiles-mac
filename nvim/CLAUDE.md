# nvim

## Purpose

Neovim config based on kickstart.nvim — a fully documented, single-file starting point. Extended with Python/Lua LSP and Azure OpenAI integration.

## Key Decisions

- **kickstart.nvim as base:** self-documenting and minimal — chosen over full distros (LazyVim, AstroNvim) for maintainability and readability
- **Lazy.nvim:** spec-driven plugin manager; lazy-loads by default
- **Mason:** auto-installs LSP servers and tools — no manual binary management
- **LSP servers:** `pyright` (Python), `lua_ls` (Lua); auto-format on save via conform.nvim + stylua
- **gp.nvim:** AI integration via Azure OpenAI; `<C-g>` prefix for all AI commands

## Structure

- `init.lua` — all core config: plugins, LSP, keymaps
- `lua/kickstart/plugins/` — optional kickstart plugins (debug, lint, gitsigns)
- `lua/custom/plugins/` — personal extensions; auto-loaded by Lazy

## Commands

- `stylua .` — format all Lua files
- `stylua --check .` — check formatting without modifying
- `:Lazy` — plugin manager UI
- `:Mason` — LSP/tool installer UI
- `:checkhealth` — verify configuration health
