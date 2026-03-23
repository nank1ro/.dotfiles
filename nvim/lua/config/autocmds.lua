-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- Auto-generate .nvim.lua from .vscode/launch.json for flutter-tools
vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
  group = vim.api.nvim_create_augroup("generate_nvim_lua", { clear = true }),
  pattern = "*",
  callback = function()
    local cwd = vim.fn.getcwd()
    local nvim_lua = cwd .. "/.nvim.lua"
    local launch_json = cwd .. "/.vscode/launch.json"

    if vim.fn.filereadable(launch_json) == 0 then
      return
    end
    -- Skip if .nvim.lua exists and is newer than launch.json
    if vim.fn.filereadable(nvim_lua) == 1 then
      local nvim_lua_mtime = vim.fn.getftime(nvim_lua)
      local launch_json_mtime = vim.fn.getftime(launch_json)
      if nvim_lua_mtime >= launch_json_mtime then
        return
      end
    end

    local raw = vim.fn.readfile(launch_json)
    -- Strip JSON comments (// and /* */) before decoding
    local stripped = {}
    for _, line in ipairs(raw) do
      table.insert(stripped, (line:gsub("//.*$", "")))
    end
    local ok, data = pcall(vim.json.decode, table.concat(stripped, "\n"))
    if not ok or not data or not data.configurations then
      return
    end

    -- Build a lookup for inputs (e.g. shellCommand.execute)
    local inputs = {}
    if data.inputs then
      for _, input in ipairs(data.inputs) do
        if input.id and input.args and input.args.command then
          inputs[input.id] = input.args.command
        end
      end
    end

    local entries = {}
    for _, cfg in ipairs(data.configurations) do
      if cfg.type == "dart" then
        local parts = {}
        local dart_defines = {}
        local dynamic_defines = {}

        -- Parse args for -d, --flavor, --dart-define, --target
        local device, flavor, target_from_args
        if cfg.args then
          local i = 1
          while i <= #cfg.args do
            local arg = cfg.args[i]
            if (arg == "-d" or arg == "--device-id") and cfg.args[i + 1] then
              device = cfg.args[i + 1]
              i = i + 2
            elseif arg == "--flavor" and cfg.args[i + 1] then
              flavor = cfg.args[i + 1]
              i = i + 2
            elseif arg == "--target" and cfg.args[i + 1] then
              target_from_args = cfg.args[i + 1]
              i = i + 2
            elseif arg:match("^%-%-dart%-define=(.+)$") then
              local define = arg:match("^%-%-dart%-define=(.+)$")
              local key, val = define:match("^([^=]+)=(.+)$")
              if key then
                local input_id = val:match("^%${input:(.+)}$")
                if input_id and inputs[input_id] then
                  table.insert(dynamic_defines, { key = key, command = inputs[input_id] })
                elseif not val:match("%${") then
                  dart_defines[key] = val
                end
              end
              i = i + 1
            else
              i = i + 1
            end
          end
        end

        if cfg.name then
          table.insert(parts, string.format('    name = %q,', cfg.name))
        end
        local target = cfg.program or target_from_args or "lib/main.dart"
        table.insert(parts, string.format('    target = %q,', target))
        if cfg.cwd then
          table.insert(parts, string.format('    cwd = %q,', cfg.cwd))
        end
        if device then
          table.insert(parts, string.format('    device = %q,', device))
        end
        if flavor then
          table.insert(parts, string.format('    flavor = %q,', flavor))
        end
        if cfg.flutterMode then
          table.insert(parts, string.format('    flutter_mode = %q,', cfg.flutterMode))
        end
        if next(dart_defines) then
          local define_parts = {}
          for k, v in pairs(dart_defines) do
            table.insert(define_parts, string.format("      %s = %q,", k, v))
          end
          table.sort(define_parts)
          table.insert(parts, "    dart_define = {\n" .. table.concat(define_parts, "\n") .. "\n    },")
        end
        if #dynamic_defines > 0 then
          local cb_lines = { "    pre_run_callback = function(config)" }
          table.insert(cb_lines, "      config.dart_define = config.dart_define or {}")
          for _, dd in ipairs(dynamic_defines) do
            table.insert(cb_lines, string.format(
              '      config.dart_define.%s = vim.trim(vim.fn.system(%q))',
              dd.key, dd.command
            ))
          end
          table.insert(cb_lines, "    end,")
          table.insert(parts, table.concat(cb_lines, "\n"))
        end

        if #parts > 0 then
          table.insert(entries, "  {\n" .. table.concat(parts, "\n") .. "\n  }")
        end
      end
    end

    if #entries == 0 then
      return
    end

    local content = 'require("flutter-tools").setup_project({\n'
      .. table.concat(entries, ",\n")
      .. ",\n})\n"

    vim.fn.writefile(vim.split(content, "\n"), nvim_lua)
    vim.cmd.source(nvim_lua)
    vim.notify("Generated .nvim.lua from launch.json", vim.log.levels.INFO)
  end,
})

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
