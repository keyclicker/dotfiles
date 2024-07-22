return {
  -- Session management. This saves your session in the background,
  -- keeping track of open buffers, window arrangement, and more.
  -- You can restore sessions when returning through the dashboard.
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = {},
    -- stylua: ignore
    keys = {
      { "<leader>ms", function() require("persistence").load() end, desc = "Restore session" },
      { "<leader>ml", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>md", function() require("persistence").stop() end, desc = "Don't save current session" },
    },
  },
}
