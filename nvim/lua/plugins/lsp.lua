return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                pylsp = {
                    settings = {
                        pylsp = {
                            plugins = {
                                rope_autoimport = {
                                    enabled = true,
                                },
                            },
                        },
                    },
                },
            },
        },
    },
    {
        "williamboman/mason-lspconfig.nvim",
        opts = {
            ensure_installed = {}, -- Disable auto-install của gopls và clangd
            automatic_installation = false, -- Disable auto-install
        },
    },
}
