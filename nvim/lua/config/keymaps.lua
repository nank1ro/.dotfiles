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

-- Smarter gx: extract full URL near cursor (works in terminal buffers too)
local function smart_open()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  local patterns = {
    "https?://[%S]+",        -- http(s) URLs
    "file://[%S]+",          -- file URLs
    "%w[%w%-]*%.%w[%w%.%-]*[/:][%S]*", -- domain.tld/path or domain:port
    "localhost:%d[%S]*",     -- localhost:port
  }

  for _, pat in ipairs(patterns) do
    local search_start = 1
    while search_start <= #line do
      local s, e = line:find(pat, search_start)
      if not s then break end
      -- Strip common trailing punctuation that's not part of the URL
      local url = line:sub(s, e):gsub("[,;>%)%]'\"]+$", "")
      e = s + #url - 1
      if col >= s and col <= e then
        -- Add scheme if missing
        if not url:match("^%w+://") then url = "http://" .. url end
        vim.ui.open(url)
        return
      end
      search_start = e + 1
    end
  end

  -- Default fallback
  vim.ui.open(vim.fn.expand("<cfile>"))
end
map({ "n", "t" }, "gx", smart_open, { desc = "Open URL under cursor" })
