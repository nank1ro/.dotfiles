local present, null_ls = pcall(require, "null-ls")
local utils = require "custom.utils"

if not present then
  return
end

local b = null_ls.builtins

local sources = {
  -- Dart
  b.formatting.dart_format,
  -- Lua
  b.formatting.stylua,
  -- Swift
  b.formatting.swiftformat,
  -- JSON
  b.formatting.jq,
  -- Python
  b.formatting.black,
  -- Kotlin
  b.formatting.ktlint,
  -- "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "css", "scss", "less", "html", "json", "jsonc", "yaml", "markdown", "markdown.mdx", "graphql", "handlebars"
  b.formatting.prettier,
  -- Go (aka Golang)
  b.formatting.gofmt,
}

null_ls.setup {
  debug = true,
  sources = sources,
  --disable the formatter on markdown files inside the `codigo-questions` directory
  -- because the files aren't following the md conventions.
  should_attach = function(bufnr)
    local git_repo_name = utils.git_repo_name()
    local is_md_file = vim.api.nvim_buf_get_name(bufnr):match "%.md$"
    return not is_md_file or git_repo_name ~= "codigo-questions"
  end,
}
