local utils = require "custom.utils"

return {
  ["williamboman/mason.nvim"] = {
    override_options = {
      ensure_installed = {
        -- lua stuff
        "lua-language-server", -- lsp
        "stylua", -- formatter

        -- web dev stuff
        "css-lsp", -- lsp
        "html-lsp", -- lsp
        "typescript-language-server", --lsp
        "json-lsp", -- lsp

        -- json
        "jq", -- formatter

        -- markdown
        "marksman", -- lsp
        -- python
        "pyright", -- lsp
        "black", -- formatter

        -- kotlin
        "kotlin-language-server", -- lsp
        "ktlint", -- formatter

        -- "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "css", "scss", "less", "html", "json", "jsonc", "yaml", "markdown", "markdown.mdx", "graphql", "handlebars"
        "prettier",

        -- golang
        "gopls", -- lsp
      },
    },
  },
  ["jose-elias-alvarez/null-ls.nvim"] = {
    after = "nvim-lspconfig",
    config = function()
      require "custom.plugins.null-ls"
    end,
  },
  ["neovim/nvim-lspconfig"] = {
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.plugins.lspconfig"
    end,
  },
  ["gbprod/yanky.nvim"] = {
    before = "nvim-telescope/telescope.nvim",
    config = function()
      require("yanky").setup {}
    end,
  },
  ["nvim-telescope/telescope.nvim"] = {
    cmd = "Telescope",
    config = function()
      require "plugins.configs.telescope"
      require("telescope").load_extension "yank_history"
    end,
    setup = function()
      require("core.utils").load_mappings "telescope"
    end,
    extensions_list = { "yank_history" },
  },
  ["kylechui/nvim-surround"] = {
    tag = "*", -- Use for stability; omit to use `main` branch for the latest features
    config = function()
      require("nvim-surround").setup {
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },
  ["Rasukarusan/nvim-select-multi-line"] = {},
  -- file managing , picker etc
  ["kyazdani42/nvim-tree.lua"] = {
    override_options = {
      git = {
        enable = true,
        ignore = true,
      },
      diagnostics = {
        enable = true,
        show_on_dirs = false,
        show_on_open_dirs = true,
        debounce_delay = 50,
        severity = {
          min = vim.diagnostic.severity.WARN,
          max = vim.diagnostic.severity.ERROR,
        },
        icons = {
          hint = "",
          info = "",
          warning = "",
          error = "",
        },
      },
      renderer = {
        highlight_git = true,
        highlight_opened_files = "none",

        indent_markers = {
          enable = false,
        },

        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },

          glyphs = {
            default = "",
            symlink = "",
            folder = {
              default = "",
              empty = "",
              empty_open = "",
              open = "",
              symlink = "",
              symlink_open = "",
              arrow_open = "",
              arrow_closed = "",
            },
            git = {
              unstaged = "✗",
              staged = "✓",
              unmerged = "",
              renamed = "➜",
              untracked = "★",
              deleted = "",
              ignored = "◌",
            },
          },
        },
      },
    },
  },
  ["goolord/alpha-nvim"] = {
    disable = false,
    override_options = {
      header = {
        val = {
          "                                                     ",
          "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
          "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
          "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
          "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
          "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
          "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
          "                                                     ",
        },
      },
    },
  },
  ["windwp/nvim-spectre"] = {
    requires = { "nvim-lua/plenary.nvim", opt = true },
    after = { "ui" },
    config = function()
      require("spectre").setup()
    end,
  },
  ["tpope/vim-abolish"] = {},
  ["sindrets/diffview.nvim"] = {
    requires = "nvim-lua/plenary.nvim",
  },
  ["L3MON4D3/LuaSnip"] = {
    wants = "friendly-snippets",
    after = "nvim-cmp",
    config = function()
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "html" })
      luasnip.filetype_extend("javascriptreact", { "html" })
      luasnip.filetype_extend("typescriptreact", { "html" })
      require("plugins.configs.others").luasnip()
      -- extend snippets to typescript and javascript files
      luasnip.filetype_extend("typescript", { "javascript" })
    end,
  },
  ["nvim-treesitter/nvim-treesitter"] = {
    override_options = {
      playground = {
        enable = true,
      },
      query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { "BufWrite", "CursorHold" },
      },
      highlight = {
        enable = true,
        use_languagetree = true,
        -- disable on md files of the repo `codigo-questions` because it can
        -- freeze when using non-conventional characters.
        disable = function(lang, _)
          local git_repo_name = utils.git_repo_name()
          return lang == "markdown" and git_repo_name == "codigo-questions"
        end,
      },
    },
  },
  ["nvim-treesitter/playground"] = {
    requires = "nvim-treesitter/nvim-treesitter",
  },
  ["f-person/pubspec-assist-nvim"] = {},
  ["~/.config/nvim/lua/custom/plugins/flutter-run-from-vscode"] = {},
  ["nvim-treesitter/nvim-treesitter-context"] = {
    config = function()
      require("treesitter-context").setup {
        enable = false,
      }
    end,
  },
  ["mfussenegger/nvim-dap"] = {
    config = function()
      local dap = require "dap"
      dap.adapters.dart = {
        type = "executable",
        command = "flutter",
        args = { "debug-adapter" },
        options = {
          -- dartls is slow to start so avoid warnings from nvim-dap
          initialize_timeout_sec = 30,
        },
      }
      -- local dartSdkPath = "/Users/alexandrumariuti/fvm/versions/stable/bin/flutter" -- utils.dart_sdk_path()
      -- local flutterSdkPath = "/Users/alexandrumariuti/fvm/versions/stable/bin/dart" --utils.flutter_sdk_path()
      -- print("dartSdkPath", dartSdkPath)
      -- print("flutterSdkPath", flutterSdkPath)
      -- dap.configurations.dart = {
      --   {
      --     type = "dart",
      --     request = "launch",
      --     name = "Launch flutter",
      --     dartSdkPath = dartSdkPath,
      --     flutterSdkPath = flutterSdkPath,
      --     program = "${workspaceFolder}/lib/main_dev.dart",
      --     cwd = "${workspaceFolder}",
      --   },
      --   {
      --     type = "dart",
      --     request = "attach",
      --     name = "Connect flutter",
      --     dartSdkPath = dartSdkPath,
      --     flutterSdkPath = flutterSdkPath,
      --     program = "${workspaceFolder}/lib/main_dev.dart",
      --     cwd = "${workspaceFolder}",
      --   },
      -- }
      -- dap.set_log_level "DEBUG"
    end,
  },
  ["rcarriga/nvim-dap-ui"] = {
    requires = { "mfussenegger/nvim-dap" },
    config = function()
      local dap, dapui = require "dap", require "dapui"
      dapui.setup()
      -- Use nvim-dap events to open and close the windows automatically
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
  ["szw/vim-maximizer"] = {},
  ["tpope/vim-unimpaired"] = {},
  ["triglav/vim-visual-increment"] = {},
}
