local present, null_ls = pcall(require, "null-ls")

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
}
