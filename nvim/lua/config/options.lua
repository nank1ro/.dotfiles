-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
if vim.g.vscode then
  return
end
-- Enable loading .nvim.lua config
vim.opt.exrc = true
-- Disable swap files
vim.opt.swapfile = false
-- Use absolute line numbers instead of relative
vim.opt.relativenumber = false
