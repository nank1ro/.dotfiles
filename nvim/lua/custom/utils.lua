local M = {}

-- Returns the git repo name
function M.git_repo_name()
  return vim.fn.system "basename `git rev-parse --show-toplevel` | tr -d '\n'"
end

-- Returns the git repo root path
function M.git_repo_root_path()
  return vim.fn.system "git rev-parse --show-toplevel | tr -d '\n'"
end

-- Returns true if the file with the given [name] exists
function M.file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  end
  return false
end

return M
