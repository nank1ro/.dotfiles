local M = {}

M.options = {
  relativenumber = true,
  -- Horizontal splits will automatically be below
  splitbelow = true,
  -- Vertical splits will automatically be to the right
  splitright = true,
  shiftwidth = 2,
  tabstop = 2,
  softtabstop = 2,
}

M.plugins = require "custom.plugins"

M.ui = {
  theme = "catppuccin",
}

M.mappings = require "custom.mappings"

return M
