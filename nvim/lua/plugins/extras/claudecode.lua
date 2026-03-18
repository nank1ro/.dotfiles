return {
  {
    import = "lazyvim.plugins.extras.ai.claudecode",
  },
  {
    "coder/claudecode.nvim",
    lazy = false,
    opts = {
      terminal_cmd = "claude --dangerously-skip-permissions",
    },
  },
}
