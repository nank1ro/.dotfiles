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
    -- setup = function ()
    --   require("custom.plugins.lspconfig").setup()
    -- end,
  },
  -- ["akinsho/pubspec-assist.nvim"] = {
  --   requires = { "nvim-lua/plenary.nvim", module = "plenary" },
  --   rocks = {
  --     {
  --       "lyaml",
  --       server = "http://rocks.moonscript.org",
  --       -- If using macOS or Ubuntu, you may need to install the `libyaml` package.
  --       -- if you install libyaml with homebrew you will need to set the YAML_DIR
  --       -- to the location of the homebrew installation of libyaml e.g.
  --       env = { YAML_DIR = '/opt/homebrew/Cellar/libyaml/0.2.5/' },
  --     },
  --   },
  --   config = function()
  --     require("pubspec-assist").setup()
  --   end,
  --   event = { "BufRead pubspec.yaml" },
  -- },
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
  -- ["akinsho/flutter-tools.nvim"] = {
  --   requires = 'nvim-lua/plenary.nvim',
  --   as = 'flutter-tools',
  --   setup = function()
  --     require("flutter-tools").setup{
  --       lsp = {
  --         on_attach = require("plugins.configs.lspconfig").on_attach,
  --         capabilities = require("plugins.configs.lspconfig").capabilities,
  --       }
  --     }
  --   end
  -- }
  -- ["/Users/alexandrumariuti/.config/nvim/lua/custom/plugins/flutter-tools.nvim"] = {
  --   requires = 'nvim-lua/plenary.nvim',
  --   as = 'flutter-tools',
  --   setup = function()
  --    require("flutter-tools").setup {}
  --   end
  -- }

  -- ["nvim-telescope/telescope.nvim"] = {
  --   after = "gbprod/yanky.nvim",
  --   extensions_list = { "yank_history" },
  -- },
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
}
