return {
  {
    'tpope/vim-fugitive',
    cmd = { 'G', 'Git' },
  },
  {
    'sindrets/diffview.nvim',
    opts = {
      keymaps = {
        file_history_panel = { ['q'] = '<cmd>DiffviewClose<cr>' },
        file_panel = { ['q'] = '<cmd>DiffviewClose<cr>' },
        view = { ['q'] = '<cmd>DiffviewClose<cr>' },
      },
    },
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    --stylua: ignore
    keys = {
      {'<leader>gd', "<cmd>DiffviewOpen<cr>", desc = 'Diffview open' },
      {'<leader>gf', "<cmd>DiffviewFileHistory %<cr>", desc = 'Diffview file history' },
    },
  },
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      'sindrets/diffview.nvim', -- optional - Diff integration
      -- Only one of these is needed, not both.
      'nvim-telescope/telescope.nvim', -- optional
      'ibhagwan/fzf-lua', -- optional
    },
    opts = {},
    cmd = { 'Neogit' },

    --stylua: ignore
    keys = {
      { '<leader>gg', function() require('neogit').open() end, desc = 'Neogit' },
      { '<leader>gc', function() require('neogit').open { 'commit' } end, desc = 'Neogit Commit' },
      { '<leader>gP', function() require('neogit').open { 'push' } end, desc = 'Neogit Push' },
      { '<leader>gp', function() require('neogit').open { 'pull' } end, desc = 'Neogit Pull' },
      { '<leader>gl', function() require('neogit').open { 'log' } end, desc = 'Neogit Log' },
      { '<leader>gD', function() require('neogit').open { 'diff' } end, desc = 'Neogit Diff' },
      { '<leader>gb', function() require('neogit').open { 'branch' } end, desc = 'Neogit Branch' },
      { '<leader>gz', function() require('neogit').open { 'stash' } end, desc = 'Neogit Stash' },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
    opts = {
      signs = {
        add = { text = '┃', priority = 20 },
        change = { text = '┃', priority = 20 },
        delete = { text = '_', priority = 20 },
        topdelete = { text = '‾', priority = 20 },
        changedelete = { text = '~', priority = 20 },
        untracked = { text = '┆', priority = 20 },
      },
      signs_staged = {
        add = { text = '┃', priority = 30 },
        change = { text = '┃', priority = 30 },
        delete = { text = '_', priority = 30 },
        topdelete = { text = '‾', priority = 30 },
        changedelete = { text = '~', priority = 30 },
        untracked = { text = '┆', priority = 30 },
      },

      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to Next Git Change' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Jump to Previous Git Change' })

        -- Actions
        -- visual mode
        map('v', '<leader>hs', function()
          gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'Stage Git Hunk' })
        map('v', '<leader>hr', function()
          gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'Reset Git Hunk' })

        -- normal mode
        map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Stage Hunk' })
        map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Reset Hunk' })
        map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'Stage Buffer' })
        map('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'Undo Stage Hunk' })
        map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'Reset Buffer' })
        map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'Preview Hunk' })
        map('n', '<leader>hb', gitsigns.blame_line, { desc = 'Blame Line' })
        map('n', '<leader>hd', gitsigns.diffthis, { desc = 'Diff Against Index' })
        map('n', '<leader>hD', function()
          gitsigns.diffthis '@'
        end, { desc = 'Diff Against Last Commit' })
        -- Toggles
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle Git Show Blame Line' })
        map('n', '<leader>tD', gitsigns.toggle_deleted, { desc = 'Toggle Git Show Deleted' })
      end,
    },
  },
}
