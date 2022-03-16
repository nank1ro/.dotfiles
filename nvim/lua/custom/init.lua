-- This is an example init file , its supposed to be placed in /lua/custom dir
-- lua/custom/init.lua

-- This is where your custom modules and plugins go.
-- Please check NvChad docs if you're totally new to nvchad + dont know lua!!

local map = require "core.utils".map
-- MAPPINGS
-- To add new plugins, use the "setup_mappings" hook,

  map("n", "<leader>fg", ":Telescope git_files<CR>", opt)
  map("n", "<leader>fl", ":Telescope resume<CR>", {
    noremap = true,
  })

  -- " Vim fugitive shortcuts
  map("n", "<leader>gs", ":G<cr><c-w>T", opt)
  map("n", "<leader>gl", ":diffget //3", opt)
  map("n", "<leader>gh", ":diffget //2", opt)

  -- Keep visual mode after indent
  map("v", ">", ">gv", opt)
  map("v", "<", "<gv", opt)


  -- Taken from .vimrc
  -- Replace visual selection with entered text
  map("v", "<C-r>", '"hy:%s/<C-r>h//gc<left><left><left>', {
    noremap = true,
  })

  function ExecuteMacroOverVisualRange()
    echo "@".getcmdline()
    execute ":'<,'>normal @".nr2char(getchar())
  end
  map("x", "@", ":<C-u>call ExecuteMacroOverVisualRange()<CR>", {
    noremap = true,
  })

  -- Debugger
  map("n", "<F5>", ":lua require'dap'.continue()<CR>", opt)
  map("n", "<F10>", ":lua require'dap'.step_over()<CR>", opt)
  map("n", "<F11>", ":lua require'dap'.step_into()<CR>", opt)
  map("n", "<F12>", ":lua require'dap'.step_out()<CR>", opt)
  map("n", "<F9>", ":lua require'dap'.toggle_breakpoint()<CR>", opt)
  map("n", "<leader>dr", ":lua require'dap'.repl_open()<CR>", opt)
  map("n", "<leader>dl", ":lua require'dap'.run_last()<CR>", opt)
  map("n", "<F2>", ":lua require('dapui').toggle()<CR>", opt)
  
  -- Neovim lsp
  map("n", "gd", ":lua vim.lsp.buf.definition()<CR>", {
    noremap = true,
    silent = true,
  })

  -- Removed because doesn't work
  -- map("n", "gi", ":lua vim.lsp.buf.implementation()<CR>", {
  --   noremap = true,
  --   silent = true,
  -- })


  map("n", "<leader>ca", ":lua vim.lsp.buf.code_action()<CR>", {
    noremap = true,
    silent = true,
  })

  map("v", "<leader>ca", ":lua vim.lsp.buf.range_code_action()<CR>", {
    noremap = true,
    silent = true,
  })

  map("n", "K", ":lua vim.lsp.buf.hover()<CR>", {
    noremap = true,
    silent = true,
  })

  map("n", "gs", ":lua vim.lsp.buf.signature_help()<CR>", {
    noremap = true,
    silent = true,
  })

  map("n", "<leader>rn", ":lua vim.lsp.buf.rename()<CR>", {
    noremap = true,
    silent = true,
  })

  map("n", "gr", ":lua vim.lsp.buf.references()<CR>", {
    noremap = true,
    silent = true,
  })

  map("n", "[d", ":lua vim.diagnostic.goto_prev()<CR>", {
    noremap = true,
    silent = true,
  })

  map("n", "]d", ":lua vim.diagnostic.goto_next()<CR>", {
    noremap = true,
    silent = true,
  })

  map("n", "<leader>fm", ":lua vim.lsp.buf.formatting()<CR>", {
    noremap = true,
    silent = true,
  })

  -- da stands for diagnostic all
  map("n", "<leader>da", ":lua vim.diagnostic.setqflist()<CR>", {
    noremap = true,
    silent = true,
  })

-- NOTE : opt is a variable  there (most likely a table if you want multiple options),
-- you can remove it if you dont have any custom options

-- Install plugins
-- To add new plugins, use the "install_plugins" hook,

-- examples below:
-- local customPlugins = require "core.customPlugins"
-- local userPlugins = require "custom.plugins"

-- Stop sourcing filetype.vim
-- disabled because highlight doesn't work
-- vim.g.did_load_filetypes = 1

-- NOTE: we heavily suggest using Packer's lazy loading (with the 'event' field)
-- see: https://github.com/wbthomason/packer.nvim
-- https://nvchad.github.io/config/walkthrough

-- vim.g.dashboard_disable_at_vimenter = 0

-- Make nvim-dap-ui to be opened automatically when the dap server is started
-- local dap, dapui = require("dap"), require("dapui")
-- dap.listeners.after.event_initialized["dapui_config"] = function()
--   dapui.open()
-- end
-- dap.listeners.before.event_terminated["dapui_config"] = function()
--   dapui.close()
-- end
-- dap.listeners.before.event_exited["dapui_config"] = function()
--   dapui.close()
-- end
--

-- write all auto commands here:
-- 1. set the default shell to /bin/zsh
vim.api.nvim_command([[
  augroup AutoCompileLatex
  autocmd vimenter * let &shell='/bin/zsh -i'
  augroup END 
]])
-- 2. auto format on dart file save
vim.api.nvim_command([[
  autocmd BufWritePre *.dart silent :lua vim.lsp.buf.formatting()
]])
