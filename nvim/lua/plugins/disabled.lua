return {
  -- disable markdown lint
  {
    "mfussenegger/nvim-lint",
    enabled = false,
  },
  {
    "snacks.nvim",
    opts = {
      -- disable smooth scroll
      scroll = { enabled = false },
      -- disable snacks explorer
      explorer = { enabled = false },
    },
  },
}
