return {
  {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- optional for vim.ui.select
      "mfussenegger/nvim-dap", -- optional for debugging
    },
    config = {
      debugger = {
        enabled = true,
        evaluate_to_string_in_debug_views = true,
      },
      dev_log = {
        enabled = false,
        open_cmd = "botright 15split", -- command to use to open the log buffer
        focus_on_open = false, -- focus on the newly opened log window
      },
      lsp = {
        settings = {
          analysisExcludedFolders = {
            "~/.pub-cache",
            "~/fvm/versions/stable/packages",
            "~/fvm/versions/stable/bin/cache",
          },
        },
      },
    },
  },
}
