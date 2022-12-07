vim.g.luasnippets_path = "/Users/alexandrumariuti/.config/nvim/lua/custom/snippets"
local api = vim.api

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
