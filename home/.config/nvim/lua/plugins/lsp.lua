return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            -- Disable duplicate Python LSP (keep only pyright from LazyVim extra)
            servers = {
                pylsp = {
                    enabled = false, -- Disable to avoid conflict with pyright
                },
            },
            -- Debounce diagnostics to reduce lag
            diagnostics = {
                update_in_insert = false, -- Don't update diagnostics while typing
            },
        },
    },
    {
        "mason-org/mason-lspconfig.nvim",
        opts = {
            ensure_installed = {}, -- Disable auto-install của gopls và clangd
            automatic_installation = false, -- Disable auto-install
        },
    },
}
