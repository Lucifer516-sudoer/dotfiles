-- Basic UI & Behavior Options
vim.opt.number = true      -- Show line numbers
vim.opt.mouse = "a"        -- Enable mouse support
vim.opt.ignorecase = true  -- Case-insensitive search...
vim.opt.smartcase = true   -- ...unless capital letter is used
vim.opt.undofile = true    -- Save undo history across sessions
vim.opt.signcolumn = "yes" -- Always show sign column (prevents text shift)
vim.opt.updatetime = 250   -- Faster completion/diagnostics
vim.opt.timeoutlen = 300   -- Faster keymap trigger


-- Autocommand to start Neovim's built-in LSP client for C/C++
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "objc", "objcpp" },
    callback = function()
        vim.lsp.start({
            name = "clangd",
            cmd = { "clangd" },
            root_dir = vim.fs.dirname(vim.fs.find({ "compile_commands.json", ".git" }, { upward = true })[1]),
        })
    end,
})

-- Global diagnostic navigation
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })

-- LSP Keymaps (Active only when LSP is connected)
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local opts = { buffer = args.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)      -- Go to definition
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)            -- Show documentation hover
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)  -- Smart rename symbol
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts) -- Code actions
    end,
})
