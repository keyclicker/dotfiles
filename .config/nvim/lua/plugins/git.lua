return {
  -- {
  --   'tpope/vim-fugitive',
  --   cmd = { 'G', 'Git' },
  --
  --   init = function()
  --     vim.keymap.set('n', '<leader>gs', '<cmd>Git<CR>', { desc = 'Git status' })
  --   end,
  -- },
  {
    'sindrets/diffview.nvim',

    opts = {},
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
      { '<leader>gs', function() require('neogit').open() end, desc = 'Neogit' },
      { '<leader>gc', function() require('neogit').open { 'commit' } end, desc = 'Neogit commit' },
      { '<leader>gP', function() require('neogit').open { 'push' } end, desc = 'Neogit push' },
      { '<leader>gp', function() require('neogit').open { 'pull' } end, desc = 'Neogit pull' },
      { '<leader>gl', function() require('neogit').open { 'log' } end, desc = 'Neogit log' },
      { '<leader>gD', function() require('neogit').open { 'diff' } end, desc = 'Neogit diff' },
      { '<leader>gb', function() require('neogit').open { 'branch' } end, desc = 'Neogit branch' },
      { '<leader>gz', function() require('neogit').open { 'stash' } end, desc = 'Neogit stash' },
    },
  },

  -- Here is a more advanced example where we pass configuration
  -- options to `gitsigns.nvim`. This is equivalent to the following Lua:
  --    require('gitsigns').setup({ ... })
  --
  -- See `:help gitsigns` to understand what the configuration keys do

  -- Adds git related signs to the gutter, as well as utilities for managing changes
  -- NOTE: gitsigns is already included in init.lua but contains only the base
  -- config. This will add also the recommended keymaps.
  {
    'lewis6991/gitsigns.nvim',
    -- event = 'LazyFile',
    opts = {
      signs = {
        add = { text = '┃' },
        change = { text = '┃' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
        untracked = { text = '┆' },
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
        end, { desc = 'Jump to next git [c]hange' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Jump to previous git [c]hange' })

        -- Actions
        -- visual mode
        map('v', '<leader>hs', function()
          gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'stage git hunk' })
        map('v', '<leader>hr', function()
          gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'reset git hunk' })

        -- normal mode
        map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Stage hunk' })
        map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Reset hunk' })
        map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'Stage buffer' })
        map('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'Undo stage hunk' })
        map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'Reset buffer' })
        map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'Preview hunk' })
        map('n', '<leader>hb', gitsigns.blame_line, { desc = 'Blame line' })
        map('n', '<leader>hd', gitsigns.diffthis, { desc = 'Diff against index' })
        map('n', '<leader>hD', function()
          gitsigns.diffthis '@'
        end, { desc = 'Diff against last commit' })
        -- Toggles
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle git show blame line' })
        map('n', '<leader>tD', gitsigns.toggle_deleted, { desc = 'Toggle git show Deleted' })
      end,
    },
  },
}
