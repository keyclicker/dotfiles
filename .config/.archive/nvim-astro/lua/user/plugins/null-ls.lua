return {
  "jose-elias-alvarez/null-ls.nvim",
  opts = function(_, config)
    -- config variable is the default configuration table for the setup function call
    local null_ls = require "null-ls"

    -- local hack = {
    --   extra_args = function()
    --     local virtual = os.getenv "VIRTUAL_ENV" or os.getenv "CONDA_PREFIX" or "/usr"
    --     return { "--python-executable", virtual .. "/bin/python3" }
    --   end,
    -- }

    -- Check supported formatters and linters
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
    config.sources = {
      -- Set a formatter
      -- null_ls.builtins.formatting.stylua,
      -- null_ls.builtins.formatting.prettier,
      -- null_ls.builtins.diagnostics.pylint.with { prefer_local = ".venv/bin" },
      -- null_ls.builtins.diagnostics.flake8.with { prefer_local = ".venv/bin" },
      -- null_ls.builtins.diagnostics.mypy.with { prefer_local = ".venv/bin" },

      -- null_ls.builtins.diagnostics.mypy.with(hack),
      -- null_ls.builtins.diagnostics.flake8.with(hack),
      -- null_ls.builtins.diagnostics.pylint.with(hack),
    }
    return config -- return final config table
  end,
}
