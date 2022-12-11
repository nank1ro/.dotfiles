local M = {}

-- Returns the git repo name
function M.git_repo_name()
  return vim.fn.system "basename `git rev-parse --show-toplevel` | tr -d '\n'"
end

-- Returns the git repo root path
function M.git_repo_root_path()
  return vim.fn.system "git rev-parse --show-toplevel | tr -d '\n'"
end

-- Returns the flutter sdk path
function M.flutter_sdk_path()
  return vim.fn.system "which flutter | tr -d '\n'"
end

local uname = vim.loop.os_uname()
local is_windows = uname.version:match "Windows"
local path_sep = is_windows and "\\" or "/"

---Join path segments using the os separator
---@vararg string
---@return string
function M.path_join(...)
  local result = table.concat(vim.tbl_flatten { ... }, path_sep):gsub(path_sep .. "+", path_sep)
  return result
end

-- The user home path, e.g. /Users/alex
M.home_path = os.getenv "HOME"

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
