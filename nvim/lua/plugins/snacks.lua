return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          position = "float",
        },
      },
    },
    init = function()
      local win_before_float = nil
      local float_term_wins = {}

      local function is_float_win(win)
        local cfg = vim.api.nvim_win_get_config(win)
        return cfg.relative and cfg.relative ~= ""
      end

      local function toggle_shell_terminal()
        -- Only save origin window when opening, not when closing
        local has_float = next(float_term_wins) ~= nil
        if not has_float then
          win_before_float = vim.api.nvim_get_current_win()
        end
        -- If in a snacks terminal split, switch out first to avoid hiding it
        if vim.bo.filetype == "snacks_terminal" and not is_float_win(vim.api.nvim_get_current_win()) then
          vim.cmd("wincmd p")
        end
        Snacks.terminal(nil, { cwd = LazyVim.root() })
      end

      -- Override global <C-/> to track origin window and avoid hiding terminal splits
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          vim.schedule(function()
            for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
              vim.keymap.set({ "n", "t" }, lhs, toggle_shell_terminal, {
                desc = lhs == "<C-_>" and "which_key_ignore" or "Terminal (Root Dir)",
              })
            end
          end)
        end,
      })

      -- Buffer-local <C-/> on any non-float snacks terminal to prevent it from being hidden
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function(ev)
          if vim.bo[ev.buf].filetype ~= "snacks_terminal" then
            return
          end
          vim.schedule(function()
            local win = vim.fn.bufwinid(ev.buf)
            if win == -1 or is_float_win(win) then
              return
            end
            for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
              vim.keymap.set("t", lhs, toggle_shell_terminal, {
                buffer = ev.buf,
                desc = "Terminal (Root Dir)",
              })
            end
          end)
        end,
      })

      -- Track floating terminal windows
      vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function(ev)
          if vim.bo[ev.buf].filetype == "snacks_terminal" then
            local win = vim.api.nvim_get_current_win()
            if is_float_win(win) then
              float_term_wins[win] = true
            end
          end
        end,
      })

      -- Restore focus when floating terminal closes
      vim.api.nvim_create_autocmd("WinClosed", {
        callback = function(ev)
          local win = tonumber(ev.match)
          if not (win and float_term_wins[win]) then
            return
          end
          float_term_wins[win] = nil
          vim.schedule(function()
            if win_before_float and vim.api.nvim_win_is_valid(win_before_float) then
              vim.api.nvim_set_current_win(win_before_float)
              if vim.bo.buftype == "terminal" then
                vim.cmd("startinsert")
              end
            end
            win_before_float = nil
          end)
        end,
      })
    end,
  },
}
