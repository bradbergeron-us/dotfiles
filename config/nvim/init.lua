-- init.lua — minimal, dependency-free Neovim baseline (managed by dotfiles).
--
-- No plugin manager and no external plugins, so it works on any fresh machine
-- with just Neovim installed. Layer machine-specific config under
-- ~/.config/nvim/ (e.g. a lua/ directory or a file you source) — that is not
-- tracked by this repo.

-- Leader keys (set before any mappings).
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"      -- avoid text shifting when signs appear
opt.termguicolors = true    -- 24-bit color (diagnostics, themes)
opt.scrolloff = 5
opt.wrap = false
opt.colorcolumn = "100"
opt.mouse = "a"

-- Indentation — 2 spaces, expand tabs
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

-- Search — case-insensitive unless the query has a capital
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- System clipboard integration (uses pbcopy/pbpaste on macOS when present)
opt.clipboard = "unnamedplus"

-- Files / persistence
opt.swapfile = false
opt.backup = false
opt.undofile = true         -- persistent undo across sessions
opt.updatetime = 300

-- Splits open where you expect
opt.splitright = true
opt.splitbelow = true

-- Core mappings
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Readable diagnostics without any colorscheme/plugin dependency
vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  float = { border = "rounded" },
})

-- Briefly highlight yanked text (built-in; vim.hl on 0.11+, vim.highlight before)
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight on yank",
  callback = function()
    local hl = vim.hl or vim.highlight
    hl.on_yank({ timeout = 150 })
  end,
})
