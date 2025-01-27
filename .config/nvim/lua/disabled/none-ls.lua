return {
  "nvimtools/none-ls.nvim",
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = { "mason.nvim", "nvim-lua/plenary.nvim" },
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.diagnostics.mypy,
        null_ls.builtins.diagnostics.pylint,
        null_ls.builtins.diagnostics.flake8,

        -- require("plugins.lib.cspell_diagnostics"),
        -- require("plugins.lib.cspell_code_actions"),
      }
    })
  end,
}
