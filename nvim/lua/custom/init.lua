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
local customPlugins = require "core.customPlugins"

customPlugins.add(function(use)
   use {
      "tpope/vim-fugitive",
      event = "VimEnter",
   }

   use {
     "idanarye/vim-merginal",
     requires = "tpope/vim-fugitive",
   }

    use {
      "karb94/neoscroll.nvim",
       opt = true,
       config = function()
          require("neoscroll").setup()
       end,

       -- lazy loading
       setup = function()
         require("core.utils").packer_lazy_load "neoscroll.nvim"
       end,
    }

    use {
        "tpope/vim-surround",
        event = "VimEnter"
    }

    use {
        "tpope/vim-repeat",
        event = "VimEnter"
    }

    use {
        "puremourning/vimspector",
        event = "VimEnter"
    }

    use {
        "tpope/vim-unimpaired",
        event = "VimEnter"
    }

    use {
        "f-person/pubspec-assist-nvim",
        event = "VimEnter"
    }

    use {
        "mfussenegger/nvim-dap"
    }
    use {
        "L3MON4D3/LuaSnip",
        branch = "deterministic_load",
        event = "InsertEnter",
        after = "nvim-cmp",
        config = function()
          local luasnip = require("luasnip")
          luasnip.config.set_config({
                  history = true,
                  updateevents = "TextChanged,TextChangedI",
          })
          require("luasnip/loaders/from_vscode").load({ paths = { "/Users/alex/.config/nvim/lua/custom/my_snippets/" }})
          print(vim.inspect(luasnip.available()))
          -- require("luasnip/loaders/from_vscode").load()
      -- require("luasnip/loaders/from_vscode").load { paths = chadrc_config.plugins.options.luasnip.snippet_path }
      -- require("luasnip/loaders/from_vscode").load()
      -- Adds the flutter friendly snippets
      -- require("luasnip").filetype_extend("dart", {"flutter"})

        end,
        setup = function()
          require("luasnip/loaders/from_vscode").load({ paths = { "/Users/alex/.config/nvim/lua/custom/my_snippets/" }})
          print(vim.inspect(luasnip.available()))
        end
    }
  
   use {
      "saadparwaiz1/cmp_luasnip",
      after = "LuaSnip"
   }


    use {
        "akinsho/flutter-tools.nvim",
        requires = {
          "mfussenegger/nvim-dap",
          "nvim-lua/plenary.nvim",
        },
        event = "VimEnter",
        config = function()
        require("flutter-tools").setup {
            ui = {
              -- the border type to use for all floating windows, the same options/formats
              -- used for ":h nvim_open_win" e.g. "single" | "shadow" | {<table-of-eight-chars>}
              border = "rounded",
            },
            decorations = {
              statusline = {
                -- set to true to be able use the 'flutter_tools_decorations.app_version' in your statusline
                -- this will show the current version of the flutter app from the pubspec.yaml file
                app_version = true,
                -- set to true to be able use the 'flutter_tools_decorations.device' in your statusline
          -- this will show the currently running device if an application was started with a specific
          -- device
          device = true,
        }
      },
      debugger = { -- integrate with nvim dap + install dart code debugger
        enabled = true,
        run_via_dap = true, -- use dap instead of a plenary job to run flutter apps 
        register_configurations = function(paths)
          require("dap").configurations.dart = {}
          require("dap.ext.vscode").load_launchjs()
        end,
      },
      flutter_path = "~/development/flutter", -- <-- this takes priority over the lookup
      flutter_lookup_cmd = nil, -- example "dirname $(which flutter)" or "asdf where flutter"
      fvm = true, -- takes priority over path, uses <workspace>/.fvm/flutter_sdk if enabled
      widget_guides = {
        enabled = false,
      },
      closing_tags = {
        highlight = "ErrorMsg", -- highlight for the closing tag
        prefix = "// ", -- character to use for close tag e.g. > Widget
        enabled = true -- set to false to disable
      },
      dev_log = {
        enabled = false,
        open_cmd = "tabedit", -- command to use to open the log buffer
      },
      dev_tools = {
        autostart = false, -- autostart devtools server if not detected
        auto_open_browser = false, -- Automatically opens devtools in the browser
      },
      outline = {
        open_cmd = "30vnew", -- command to use to open the outline buffer
        auto_open = false -- if true this will open the outline automatically when it is first populated
      },
      -- lsp = {
      --   on_attach = my_custom_on_attach,
      --   capabilities = my_custom_capabilities -- e.g. lsp_status capabilities
      --   --- OR you can specify a function to deactivate or change or control how the config is created
      --   capabilities = function(config)
      --     config.specificThingIDontWant = false
      --     return config
      --   end,
      --   settings = {
      --     showTodos = true,
      --     completeFunctionCalls = true,
      --     analysisExcludedFolders = {<path-to-flutter-sdk-packages>}
      --   }
      -- }
          }
       end,

       -- lazy loading
       setup = function()
         require("core.utils").packer_lazy_load "flutter-tools.nvim"
       end
    }


    use {
      "rcarriga/nvim-dap-ui",
      requires = "mfussenegger/nvim-dap",
      config = function()
          require("dapui").setup()

      end,
      setup = function()
         require("core.utils").packer_lazy_load "nvim-dap-ui"
      end

    }

    -- removed in favor of nvim-lsp-config
    -- use {
    -- 'glepnir/lspsaga.nvim',
    --   config = function()
    --     require("lspsaga").init_lsp_saga()
    --   end,
    --   setup = function()
    --      require("core.utils").packer_lazy_load "lspsaga.nvim"
    --   end
    -- }
    -- use {
    --   "theHamsta/nvim-dap-virtual-text",
    --   requires = "nvim-dap",
    --   event = "VimEnter",
    --   setup = function()
    --     require("nvim-dap-virtual-text").setup()
    --   end
    -- }

    use {
      "sbdchd/neoformat",
      event = "VimEnter"
    }


end)
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
