return {
  -- You can also add new plugins here as well:
  -- Add plugins, the lazy syntax
  -- "andweeb/presence.nvim",
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("lsp_signature").setup()
  --   end,
  -- },

  -----------------------------------------------------------------------------
  -- Themes
  -----------------------------------------------------------------------------

  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },

  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },

  -----------------------------------------------------------------------------
  -- Games
  -----------------------------------------------------------------------------
  {
    "ThePrimeagen/vim-be-good",
    lazy = false,
  },

  -----------------------------------------------------------------------------
  -- Plugins
  -----------------------------------------------------------------------------

  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup {
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup {
        panel = {
          enabled = true,
          auto_refresh = false,
          keymap = {
            jump_prev = "[[",
            jump_next = "]]",
            accept = "<CR>",
            refresh = "gr",
            open = "<M-CR>",
          },
          layout = {
            position = "right", -- | top | left | right
            ratio = 0.4,
          },
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            accept = "<C-l>",
            accept_word = false,
            accept_line = false,
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        filetypes = {
          -- yaml = false,
          markdown = true,
          -- help = false,
          -- gitcommit = false,
          -- gitrebase = false,
          -- hgcommit = false,
          -- svn = false,
          -- cvs = false,
          ["."] = true,
        },
        copilot_node_command = "node", -- Node.js version must be > 18.x
        server_opts_overrides = {},
      }
    end,
  },

  -- {
  --   {
  --     "nvim-neotest/neotest",
  --     dependencies = {
  --       "nvim-lua/plenary.nvim",
  --       "antoinemadec/FixCursorHold.nvim",
  --       "nvim-treesitter/nvim-treesitter",
  --       "nvim-neotest/neotest-jest",
  --     },
  --     config = function()
  --       require("neotest").setup {
  --         adapters = {
  --           require "neotest-jest" {
  --             jestCommand = "npm run test",
  --             jestConfigFile = "jest.config.ts",
  --             env = { CI = true },
  --             cwd = function(path) return vim.fn.getcwd() end,
  --           },
  --         },
  --       }
  --     end,
  --   },
  -- },

  {
    "andythigpen/nvim-coverage",
    event = "User AstroFile",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      function()
        require("coverage").setup {
          commands = true, -- create commands
          highlights = {
            -- customize highlight groups created by the plugin
            covered = { fg = "#C3E88D" }, -- supports style, fg, bg, sp (see :h highlight-gui)
            uncovered = { fg = "#F07178" },
          },
          signs = {
            -- use your own highlight groups or text markers
            covered = { hl = "CoverageCovered", text = "▎" },
            uncovered = { hl = "CoverageUncovered", text = "▎" },
          },
          summary = {
            -- customize the summary pop-up
            min_coverage = 80.0, -- minimum coverage threshold (used for highlighting)
          },
          lang = {
            -- customize language specific settings
          },
        }
      end,
    },
  },
}
