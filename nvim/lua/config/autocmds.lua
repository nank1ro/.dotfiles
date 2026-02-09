-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_user_command("DeleteComments", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local language_tree = vim.treesitter.get_parser(bufnr)
  if not language_tree then
    vim.notify("No treesitter parser found for this buffer", vim.log.levels.WARN)
    return
  end
  local syntax_tree = language_tree:parse()[1]
  local query = vim.treesitter.query.parse(
    language_tree._lang,
    [[
    (comment) @comment
    ]]
  )

  -- Collect all text changes first
  local changes = {}
  for id, node in query:iter_captures(syntax_tree:root(), bufnr) do
    local name = query.captures[id]
    if name == "comment" or name == "jsx_comment" then
      local target_node = name == "jsx_comment" and node:parent() or node
      local start_row, start_col, end_row, end_col = target_node:range()

      -- Validate ranges
      local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, true)[1] or ""
      start_col = math.max(0, math.min(start_col, #line))
      end_col = math.max(0, math.min(end_col, #line))

      if start_row == end_row and start_col <= end_col then
        table.insert(changes, {
          start_row = start_row,
          start_col = start_col,
          end_row = end_row,
          end_col = end_col,
        })
      end
    end
  end

  -- Apply changes in reverse order
  for i = #changes, 1, -1 do
    local change = changes[i]
    pcall(vim.api.nvim_buf_set_text, bufnr, change.start_row, change.start_col, change.end_row, change.end_col, { "" })
  end

  require("conform").format({ bufnr = bufnr })
end, {
  range = true,
  desc = "Delete comments in the current buffer",
})
