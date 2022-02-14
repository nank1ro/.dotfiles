-- This is an example chadrc file , its supposed to be placed in /lua/custom dir
-- lua/custom/chadrc.lua

local M = {}

-- make sure you maintain the structure of `core/default_config.lua` here,
-- example of changing theme:

M.ui = {
   theme = "gruvchad",
}

M.options = {
  relativenumber = true,
  -- Horizontal splits will automatically be below
  splitbelow = true,
  -- Vertical splits will automatically be to the right
  splitright = true,
}

M.plugins = {
  default_plugin_remove = {
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip"
  },
  default_plugin_config_replace = {
    telescope = "custom.telescope"
  },
  status = {
    dashboard = true,
    nvimtree = true,
    snippets = true,
  },
  -- options = {
  --   luasnip = {
  --      snippet_path = {
  --        "/Users/alex/.config/nvim/lua/custom/my_snippets"
  --      },
  --   },
  -- }
  -- options = {
  --     lspconfig = {
  --        setup_lspconf = "custom.plugins.lspconfig",
  --     },
  --  },
}

return M
