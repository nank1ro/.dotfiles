local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities
local merge_tb = vim.tbl_deep_extend
local lspconfig = require "lspconfig"
local utils = require "custom.utils"

local json_capabilities = capabilities
json_capabilities.textDocument.completion.completionItem.snippetSupport = true

local default_server_options = {
  capabilities = capabilities,
  on_attach = on_attach,
}

-- servers table with custom options (optional)
local servers = {
  html = {},
  cssls = {},
  jsonls = {
    capabilities = json_capabilities,
  },
  dartls = {
    init_options = {
      closingLabels = true,
      flutterOutline = true,
      onlyAnalyzeProjectsWithOpenFiles = true,
      outline = true,
      suggestFromUnimportedLibraries = true,
    },
    settings = {
      dart = {
        completeFunctionCalls = true,
        showTodos = true,
        renameFilesWithClasses = "prompt",
        analysisExcludedFolders = {
          utils.path_join(utils.flutter_sdk_path(), "packages"),
          utils.path_join(utils.flutter_sdk_path(), ".pub-cache"),
          utils.path_join(utils.home_path, ".pub-cache"),
          utils.path_join(utils.home_path, "fvm/versions"),
        },
      },
    },
  },
  -- swift
  sourcekit = {
    lspName = "sourcekit",
  },
  -- markdown
  marksman = {},
  -- python
  pyright = {},
  kotlin_language_server = {},
  -- typescript
  tsserver = {},
  -- golang
  gopls = {},
}

for server_name, server_options in pairs(servers) do
  local merged_server_options = merge_tb("force", default_server_options, server_options)
  lspconfig[server_name].setup(merged_server_options)
end
