local M = {}

-- Returns the git repo name
function M.git_repo_name()
  return vim.fn.system "basename `git rev-parse --show-toplevel` | tr -d '\n'"
end

return M
