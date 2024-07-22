return {
  'andythigpen/nvim-coverage',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    commands = true, -- create commands
    auto_reload = true,
    auto_reload_time = 1000,

    highlights = {
      -- customize highlight groups created by the plugin
      covered = { fg = '#C3E88D' }, -- supports style, fg, bg, sp (see :h highlight-gui)
      uncovered = { fg = '#F07178' },
      partial = { fg = '#FFCB6B' },
    },
    signs = {
      -- use your own highlight groups or text markers
      covered = { hl = 'CoverageCovered', text = 'C' },
      uncovered = { hl = 'CoverageUncovered', text = 'U' },
      partial = { hl = 'CoveragePartiallyCovered', text = 'P' },
    },
    summary = {
      -- customize the summary pop-up
      min_coverage = 80.0, -- minimum coverage threshold (used for highlighting)
    },
    lang = {
      -- customize language specific settings
    },
  },
  keys = {
    { '<leader>ul', '<cmd>Coverage<CR>', desc = 'Load coverage' },
    { '<leader>us', '<cmd>CoverageSummary<CR>', desc = 'Display coverrage summary' },
    { '<leader>ut', '<cmd>CoverageToggle<CR>', desc = 'Toggle coverage signs' },
  },
}
