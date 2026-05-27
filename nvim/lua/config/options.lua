-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
if vim.g.vscode then
  return
end
-- Enable loading .nvim.lua config
vim.opt.exrc = true
-- Auto-trust .nvim.lua files (bypass the trust prompt)
vim.secure.read = function(path)
  local f = io.open(path, "r")
  if f then
    local content = f:read("*a")
    f:close()
    return content
  end
end
-- Disable swap files
vim.opt.swapfile = false
-- Use absolute line numbers instead of relative
vim.opt.relativenumber = false
-- Faster CursorHold for auto-reloading files changed externally (e.g. Claude Code sidebar)
vim.opt.updatetime = 250
-- Hide the tabline entirely (use buffers, not tabs)
vim.opt.showtabline = 0

-- Work around nvim 0.12's glob parser rejecting the Dart LSP's file-watcher
-- glob `**/**.dart`. nvim treats consecutive `**` as invalid and aborts the
-- `client/registerCapability` request (SERVER_REQUEST_HANDLER_ERROR), which
-- breaks file watching for dartls. Sanitize the malformed segment
-- (`**<suffix>` -> `*<suffix>`, e.g. `**/**.dart` -> `**/*.dart`) before it
-- reaches the parser so watching keeps working instead of being disabled.
local glob = require("vim.glob")
local to_lpeg = glob.to_lpeg
glob.to_lpeg = function(pattern)
  if type(pattern) == "string" then
    pattern = pattern:gsub("%*%*([^/])", "*%1")
  end
  return to_lpeg(pattern)
end
