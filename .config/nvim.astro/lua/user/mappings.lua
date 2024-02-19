-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map

    -- navigate buffer tabs with `H` and `L`
    -- L = {
    --   function() require("astronvim.utils.buffer").nav(vim.v.count > 0 and vim.v.count or 1) end,
    --   desc = "Next buffer",
    -- },
    -- H = {
    --   function() require("astronvim.utils.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1)) end,
    --   desc = "Previous buffer",
    -- },

    -- mappings seen under group name "Buffer"
    ["<leader>bD"] = {
      function()
        require("astronvim.utils.status").heirline.buffer_picker(
          function(bufnr) require("astronvim.utils.buffer").close(bufnr) end
        )
      end,
      desc = "Pick to close",
    },
    -- tables with the `name` key will be registered with which-key if it's installed
    -- this is useful for naming menus
    ["<leader>b"] = { name = "Buffers" },
    -- quick save
    ["<C-s>"] = { ":w!<cr>", desc = "Save File" }, -- change description but the same command

    ---------------------------------------------------------------------------
    -- MY MAPPINGS
    ---------------------------------------------------------------------------
    -- trigger `:WhichKey` to see all root mappings
    ["<leader>i"] = {
      ":WhichKey<cr>",
      desc = "WhichKey",
    },

    -- save all buffers
    ["<leader>W"] = {
      ":wall<cr>",
      desc = "Save All",
    },

    -- ["<leader>a"] = { desc = " LSP" },

    ["<C-n>"] = {
      function() require("astronvim.utils.buffer").nav(vim.v.count > 0 and vim.v.count or 1) end,
      desc = "Next buffer",
    },
    ["<C-p>"] = {
      function() require("astronvim.utils.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1)) end,
      desc = "Previous buffer",
    },

    -- disable home screen mapping
    ["<leader>h"] = {
      function() print "This is not your home" end,
      desc = "This is not your home",
    },

    -- toggle diagnostics
    ["<leader>lt"] = {
      function()
        local prev = vim.diagnostic.config().virtual_text
        local next = not prev

        vim.diagnostic.config { virtual_text = next }
      end,
      desc = "Toggle Diagnostics",
    },

    -- toggle copilot
    ["<leader>lc"] = {
      function() require("copilot.suggestion").toggle_auto_trigger() end,
      desc = "Toggle Copilot",
    },

    -- swap \ and | for easier access
    ["\\"] = { "<cmd>vsplit<cr>", desc = "Vertical Split" },
    ["|"] = { "<cmd>split<cr>", desc = "Horizontal Split" },
    ---------------------------------------------------------------------------
    -- Testing
    ---------------------------------------------------------------------------
    -- ["<leader>j"] = { desc = "Jesting" },
    --
    -- -- Run the nearest test
    -- ["<leader>jc"] = {
    --   function() require("neotest").run.run() end,
    --   desc = "Run the nearest test",
    -- },
    --
    -- -- Run the current file
    -- ["<leader>jf"] = {
    --   function() require("neotest").run.run(vim.fn.expand "%") end,
    --   desc = "Run the current file",
    -- },
    --
    -- -- Debug the nearest test
    -- ["<leader>jd"] = {
    --   function() require("neotest").run.run { strategy = "dap" } end,
    --   desc = "Debug the nearest test",
    -- },
    --
    -- -- Stop the nearest test
    -- ["<leader>js"] = {
    --   function() require("neotest").run.stop() end,
    --   desc = "Stop the nearest test",
    -- },
    --
    -- -- Attach to the nearest test
    -- ["<leader>ja"] = {
    --   function() require("neotest").run.attach() end,
    --   desc = "Attach to the nearest test",
    -- },
    --
    -- -- Consumers
    -- -----------------------------------
    --
    -- -- Toggle watch
    -- ["<leader>jw"] = {
    --   function() require("neotest").watch.toggle() end,
    --   desc = "Toggle watch",
    -- },
    --
    -- -- Output window
    -- ["<leader>jo"] = {
    --   function() require("neotest").output.open() end,
    --   desc = "Output window",
    -- },
    --
    -- -- Output panel
    -- ["<leader>jp"] = {
    --   function() require("neotest").output_panel.toggle() end,
    --   desc = "Output panel",
    -- },
    --
    -- -- Summary window
    -- ["<leader>jt"] = {
    --   function() require("neotest").summary.toggle() end,
    --   desc = "Summary window",
    -- },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
  },
}
