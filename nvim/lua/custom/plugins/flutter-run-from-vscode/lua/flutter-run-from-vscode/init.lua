local json = require "flutter-run-from-vscode.json"
local nvterm = require "nvterm.terminal"
local M = {}

-- Selects the configuration and runs the cmd in the terminal
local function select_configuration(configuration)
  local program = configuration.program or "lib/main.dart"
  local args = ""
  if configuration.args then
    args = table.concat(configuration.args, " ")
  end

  -- If the program has a different working directory, change it
  if configuration.cwd then
    nvterm.send("cd " .. configuration.cwd)
  end

  local cmd = "flutter run -t " .. program .. " " .. args .. " --pid-file=/tmp/tf1.pid"
  nvterm.toggle "horizontal"
  nvterm.send(cmd, "horizontal")

  -- hot refresh on save
  local watch_cmd = 'npx -y nodemon -e dart -x "cat /tmp/tf1.pid | xargs kill -s USR1" > /dev/null 2>&1'
  nvterm.new "vertical"
  nvterm.send(watch_cmd, "vertical")
  nvterm.toggle "vertical"
end

-- Finds the first configuration with the given [name]
local function first_where_name(list, name)
  for _, conf in pairs(list) do
    if name == conf.name then
      return conf
    end
  end
end

-- Shows a select view
local function show_select(configurations)
  local list_of_configs = {}

  local i = 1
  for _, conf in pairs(configurations) do
    list_of_configs[i] = conf.name
    i = i + 1
  end
  vim.ui.select(list_of_configs, {
    prompt = "Select a configuration",
  }, function(config, _)
    if config then
      local select_conf = first_where_name(configurations, config)
      select_configuration(select_conf)
    end
  end)
end

function M.run_from_vscode()
  local utils = require "custom.utils"
  local root_dir = utils.git_repo_root_path() or utils.working_dir_path()
  local launch_json_path = root_dir .. "/.vscode/launch.json"
  local launch_json_exists = utils.file_exists(launch_json_path)
  if not launch_json_exists then
    vim.api.nvim_err_writeln "Cannot find a launch.json file inside the project"
  end
  local file = io.open(launch_json_path)
  ---@diagnostic disable-next-line: need-check-nil
  local json_string = file:read "*a"
  local t = json.decode(json_string)
  show_select(t.configurations)
end

return M
