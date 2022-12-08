local api = vim.api

vim.g.luasnippets_path = "~/.config/nvim/lua/custom/snippets"
vim.o.swapfile = false
vim.o.relativenumber = true
vim.o.sw = 2
vim.o.ts = 2
vim.o.sts = 2
vim.o.expandtab = true

vim.cmd [[
let g:sml#echo_yank_str = 0
]]
-- vim.cmd [[
-- highlight NvimTreeGitDirty guifg=#8BE9FD
-- ]]

-- Changes the NvimTreeGitDirty default color (dark-red) to a light blue color
local nvimTreeHighlightGroup = api.nvim_create_augroup("NvimTreeGitDirtyHiglight", { clear = true })
api.nvim_create_autocmd("BufEnter", {
  command = "silent! highlight NvimTreeGitDirty guifg=#8BE9FD",
  group = nvimTreeHighlightGroup,
})

-- Autoformats a Dart file before saving
local nvimDartAutoFormat = api.nvim_create_augroup("AutoFormatDart", { clear = true })
api.nvim_create_autocmd("BufWritePre *.dart", {
  command = "silent! :lua vim.lsp.buf.format()",
  group = nvimDartAutoFormat,
})

-- Adds the `TbufCloseOthers` command to close all the buffers expect the current one
api.nvim_create_user_command("TbufCloseOthers", function()
  local tabufline = require "nvchad_ui.tabufline"
  -- get the list of buffers ids
  local buffers = tabufline.bufilter()
  -- get the current buffer id
  local current_buf = vim.api.nvim_get_current_buf()

  -- close all the buffers, except the current one
  for _, buf in ipairs(buffers) do
    if buf ~= current_buf then
      tabufline.close_buffer(buf)
    end
  end

  -- pick again the previous active buffer
  vim.cmd("b" .. current_buf)
  api.nvim_echo({ { "" } }, false, {})
  vim.cmd "redraw"
end, {})
