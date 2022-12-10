local M = {}

function M.wrap_with_print_statement()
  local word = vim.fn.expand "<cword>"
  local print_statement = string.format('print("%s: $%s");', word, word)
  -- vim.api.nvim_set_current_line(print_statement)
  vim.cmd("normal! diwi" .. print_statement)
end

return M
