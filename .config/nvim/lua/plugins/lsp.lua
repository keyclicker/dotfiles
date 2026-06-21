local helpers = require 'utils.helpers'
return { -- LSP Configuration & Plugins
  'neovim/nvim-lspconfig',
  event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    -- NOTE: mason/mason-lspconfig repos moved to the `mason-org` org.
    { 'mason-org/mason.nvim', cmd = 'Mason', opts = { PATH = 'append' } }, -- NOTE: Must be loaded before dependants
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Useful status updates for LSP.
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    { 'j-hui/fidget.nvim', opts = {} },

    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis.
    -- (replaces the now-archived `folke/neodev.nvim`)
    { 'folke/lazydev.nvim', ft = 'lua', opts = {} },
  },
  config = function()
    -- Brief aside: **What is LSP?**
    --
    -- LSP is an initialism you've probably heard, but might not understand what it is.
    --
    -- LSP stands for Language Server Protocol. It's a protocol that helps editors
    -- and language tooling communicate in a standardized fashion.
    --
    -- In general, you have a "server" which is some tool built to understand a particular
    -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
    -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
    -- processes that communicate with some "client" - in this case, Neovim!
    --
    -- LSP provides Neovim with features like:
    --  - Go to definition
    --  - Find references
    --  - Autocompletion
    --  - Symbol Search
    --  - and more!
    --
    -- Thus, Language Servers are external tools that must be installed separately from
    -- Neovim. This is where `mason` and related plugins come into play.
    --
    -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
    -- and elegantly composed help section, `:help lsp-vs-treesitter`

    --  This function gets run when an LSP attaches to a particular buffer.
    --    That is to say, every time a new file is opened that is associated with
    --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
    --    function will be executed to configure the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a function is defined, etc.
        --  To jump back, press <C-t>.
        map('gd', require('telescope.builtin').lsp_definitions, 'Goto Definition')

        -- Find references for the word under your cursor.
        map('gr', require('telescope.builtin').lsp_references, 'Goto References')

        -- Jump to the implementation of the word under your cursor.
        --  Useful when your language has ways of declaring types without an actual implementation.
        map('gI', require('telescope.builtin').lsp_implementations, 'Goto Implementation')

        -- Jump to the type of the word under your cursor.
        --  Useful when you're not sure what type a variable is and you want to see
        --  the definition of its *type*, not where it was *defined*.
        map('gy', require('telescope.builtin').lsp_type_definitions, 'Type Definition')

        -- Fuzzy find all the symbols in your current document.
        --  Symbols are things like variables, functions, types, etc.
        map('<leader>sd', require('telescope.builtin').lsp_document_symbols, 'Document Symbols')

        -- Fuzzy find all the symbols in your current workspace.
        --  Similar to document symbols, except searches over your entire project.
        map('<leader>sw', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace Symbols')

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map('<leader>r', vim.lsp.buf.rename, 'Rename')

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('<leader>a', vim.lsp.buf.code_action, 'Code Action')

        -- Opens a popup that displays documentation about the word under your cursor
        --  See `:help K` for why this keymap.
        local float = { border = 'rounded', max_width = 80, max_height = 20 }
        map('K', function() vim.lsp.buf.hover(float) end, 'Hover Documentation')
        map('<leader>D', function() vim.lsp.buf.signature_help(float) end, 'Signature Help')

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map('gD', vim.lsp.buf.declaration, 'Goto Declaration')

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- The following autocommand is used to enable inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
          map('<leader>zh', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end, 'Toggle Inlay Hints')
        end

      end,
    })

    -- Fix pyright `"_x" is not accessed` noise.
    -- NOTE: `vim.lsp.diagnostic.on_publish_diagnostics` was removed in nvim 0.11,
    -- and re-assigning the handler inside LspAttach wrapped it on every attach.
    -- Wrap the default `publishDiagnostics` handler once, here in the config body.
    do
      local function pyright_accessed_filter(diagnostic)
        return not string.match(diagnostic.message, '"_.+" is not accessed')
      end
      local default_handler = vim.lsp.handlers['textDocument/publishDiagnostics']
      vim.lsp.handlers['textDocument/publishDiagnostics'] = function(err, result, ctx, config)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if client and client.name == 'pyright' and result and result.diagnostics then
          helpers.filter_inplace(result.diagnostics, pyright_accessed_filter)
        end
        return default_handler(err, result, ctx, config)
      end
    end

    -- Native completion uses Neovim's default capabilities (which already
    -- advertise snippetSupport). Only add resolveSupport so servers send
    -- auto-import edits / docs on resolve. Small delta keeps checkhealth lean.
    local capabilities = {
      textDocument = {
        completion = {
          completionItem = {
            resolveSupport = { properties = { 'documentation', 'detail', 'additionalTextEdits' } },
          },
        },
      },
    }

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    local servers = {
      gopls = {},
      rust_analyzer = {},
      clangd = {},

      pyright = {},
      ts_ls = {},
      eslint = {},
      cssls = {},
      html = {}, -- ??

      bashls = {},

      -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- But for many setups, the LSP (`tsserver`) will work just fine
      --

      lua_ls = {
        -- cmd = {...},
        -- filetypes = { ...},
        -- capabilities = {},
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
          },
        },
      },
    }

    -- Ensure the servers and tools above are installed
    --  To check the current status of installed tools and/or manually install
    --  other tools, you can run
    --    :Mason
    --
    --  You can press `g?` for help in this menu.
    require('mason').setup()

    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    -- NOTE: servers are installed via mason-lspconfig below (LazyVim style);
    -- tool-installer handles only the non-LSP tools (formatters/linters).
    local ensure_installed = {}
    vim.list_extend(ensure_installed, {
      'cspell',
      'markdownlint',

      'stylua', -- Used to format Lua code

      'stylelint',
      'prettierd',
      'jsonlint',

      'flake8',
      'pylint',
      'black',
      'mypy',
      'isort',

      'clang-format',
      'cpplint',

      'goimports',
      'gofumpt',

      'shfmt'
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    -- Mirror LazyVim's `config` body: register every server with the native
    -- `vim.lsp.config` API, let mason-lspconfig install + auto-enable the
    -- mason-provided servers, and `vim.lsp.enable` any server mason doesn't ship.

    -- The wildcard `*` config carries capabilities for every server: native
    -- completion + LazyVim's file-rename workspace ops.
    servers['*'] = {
      capabilities = vim.tbl_deep_extend('force', capabilities, {
        workspace = { fileOperations = { didRename = true, willRename = true } },
      }),
    }
    vim.lsp.config('*', servers['*'])

    -- Servers mason-lspconfig knows how to install (lspconfig name -> package).
    local mason_all = vim.tbl_keys(require('mason-lspconfig.mappings').get_mason_map().lspconfig_to_package)
    local mason_exclude = {} ---@type string[]

    ---@return boolean? use_mason  -- true => mason-lspconfig installs & auto-enables it
    local function configure(server)
      if server == '*' then
        return false
      end
      local sopts = servers[server]
      local use_mason = sopts.mason ~= false and vim.tbl_contains(mason_all, server)
      vim.lsp.config(server, sopts)
      -- mason-lspconfig auto-enables mason servers; enable the rest ourselves.
      if not use_mason then
        vim.lsp.enable(server)
      end
      return use_mason
    end

    local install = vim.tbl_filter(configure, vim.tbl_keys(servers))
    require('mason-lspconfig').setup {
      ensure_installed = install,
      automatic_enable = { exclude = mason_exclude },
    }
  end,
}
