return {
    "stevearc/conform.nvim",
    opts = {
        formatters = {
            prettier = {
                args = { "--stdin-filepath", "$FILENAME" },
            },
        },
        formatters_by_ft = {
            javascript = { "prettier" },
            typescript = { "prettier" },
            javascriptreact = { "prettier" },
            typescriptreact = { "prettier" },
        },
    },
}
