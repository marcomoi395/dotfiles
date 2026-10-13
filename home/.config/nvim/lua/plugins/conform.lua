return {
    "stevearc/conform.nvim",
    opts = {
        formatters = {
            prettier = {
                args = {
                    "--semi",
                    "--single-quote",
                    "--tab-width",
                    "4",
                    "--trailing-comma",
                    "es5",
                },
            },
        },
        formatters_by_ft = {
            javascript = { "prettier" },
            typescript = { "prettier" },
            json = { "prettier" },
            html = { "prettier" },
            css = { "prettier" },
        },
    },
}
