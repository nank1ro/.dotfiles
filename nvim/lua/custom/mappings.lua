local M = {}

M.telescope = {
  n = {
    ["<leader>fg"] = { "<cmd> Telescope git_files <CR>", "telescope list git files" },
    ["<leader>fl"] = { "<cmd> Telescope resume <CR>", "telescope resume" },
    ["<leader>qe"] = { "<cmd> Telescope diagnostics default_text=:error:<CR>", "telescope diagnostics errors" },
    ["<leader>qw"] = { "<cmd> Telescope diagnostics default_text=:warning:<CR>", "telescope diagnostics warnings" },
    ["<leader>qa"] = { "<cmd> Telescope diagnostics <CR>", "telescope diagnostics list all" },
    ["<leader>yh"] = { "<cmd> Telescope yank_history <CR>", "telescope yank_history" },
    ["gr"] = { "<cmd> Telescope lsp_references <CR>", "telescope references" },
    ["<leader>gb"] = { "<cmd> Telescope git_branches <CR>", "telescope git branches" },
    ["<leader>cd"] = {
      function()
        require("custom.plugins.telescope-live-grep-in-folder").live_grep_in_folder()
      end,
      "telescope find in folder",
    },
    ["<leader>ch"] = { "<cmd> Telescope command_history <CR>", "telescope command history" },
    ["<leader>sh"] = { "<cmd> Telescope search_history <CR>", "telescope search history" },
    ["<leader>ml"] = { "<cmd> Telescope marks <CR>", "telescope marks list" },
  },
}

M.nvimtree = {
  n = {
    ["<leader>mn"] = {
      function()
        require("nvim-tree.api").marks.navigate.next()
      end,
      "navigate to next NvimTree mark",
    },
    ["<leader>mp"] = {
      function()
        require("nvim-tree.api").marks.navigate.prev()
      end,
      "navigate to prev NvimTree mark",
    },
    ["<leader>ms"] = {
      function()
        require("nvim-tree.api").marks.navigate.select()
      end,
      "select NvimTree mark",
    },
  },
}

M.general = {
  n = {
    ["<leader>mu"] = { "<cmd> call sml#mode_on()<CR>", "enter multi-line non-adjacent select" },
    ["<C-d>"] = { "<C-d>zz" },
    ["<C-u>"] = { "<C-u>zz" },
    ["n"] = { "nzzzv" },
    ["N"] = { "Nzzzv" },
  },
  i = {
    ["<A-.>"] = {
      function()
        vim.lsp.buf.completion()
      end,
      "lsp completion",
    },
  },
  v = {
    -- keep visual mode after indent
    [">"] = { ">gv" },
    ["<"] = { "<gv" },
    -- Replace visual selection with entered text
    ["<C-r>"] = { '"hy:%s/\\<<C-r>h\\>//gc<left><left><left>' },
  },
}

M.spectre = {
  n = {
    ["<leader>S"] = { "<cmd>lua require('spectre').open()<CR>", "open nvim spectre" },
    ["<leader>sw"] = { "<cmd>lua require('spectre').open_visual({select_word=true})<CR>", "search current word" },
    ["<leader>sp"] = { "<cmd>lua require('spectre').open_file_search()<CR>", "search in current file" },
  },
  v = {
    ["<leader>s"] = { "<esc>:lua require('spectre').open_visual()<CR>", "search current word in visual mode" },
  },
}

return M
