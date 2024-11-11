return {
  "lervag/vimtex",
  lazy = false, -- lazy-loading will disable inverse search
  config = function()
    vim.g.vimtex_compiler_latexmk = {
      aux_dir = "aux",
      out_dir = "out",
    }

    -- vim.g.vimtex_view_method = mac_texshop
    vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
    vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
  end,
  keys = {
    { "<localleader>l", "", desc = "Latex" },
  },
}
