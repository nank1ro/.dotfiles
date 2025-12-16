return {
  {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- optional for vim.ui.select
    },
    config = {
      dev_log = {
        open_cmd = "edit", -- command to use to open the log buffer
        focus_on_open = false, -- focus on the newly opened log window
      },
    },
  },
}
