-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
if vim.g.vscode then
  return
end
local map = vim.keymap.set
map({ "i", "x", "n", "s" }, "<Char-0xAA>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Use the git root with a stable fallback to nvim's cwd.
local function open_terminal()
  local git_root = vim.fs.find(".git", { path = vim.uv.cwd(), upward = true })[1]
  local cwd = git_root and vim.fn.fnamemodify(git_root, ":h") or vim.uv.cwd()
  Snacks.terminal(nil, { cwd = cwd })
end
local function hide_terminal()
  vim.cmd("hide")
end
map("n", "<c-/>", open_terminal, { desc = "Terminal (Root Dir)" })
map("n", "<c-_>", open_terminal, { desc = "which_key_ignore" })
map("t", "<c-/>", hide_terminal, { desc = "Hide Terminal" })
map("t", "<c-_>", hide_terminal, { desc = "which_key_ignore" })
