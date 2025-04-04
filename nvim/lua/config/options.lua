-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])


return {
    "stevearc/conform.nvim",
    opts = {
        formatters = {
            prettier = {
                prepend_args = {
                    "--semi", "true",
                    "--single-quote", "true",
                    "--tab-width", "4",
                    "--trailing-comma", "es5",
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
