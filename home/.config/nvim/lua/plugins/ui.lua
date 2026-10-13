return {
    {
        "tamton-aquib/duck.nvim",
        config = function()
            vim.keymap.set("n", "<leader>dd", function()
                require("duck").hatch()
            end, {})
            vim.keymap.set("n", "<leader>dk", function()
                require("duck").cook()
            end, {})
            vim.keymap.set("n", "<leader>da", function()
                require("duck").cook_all()
            end, {})
        end,
    },
    {
        "saghen/blink.cmp",
        opts = {
            completion = {
                documentation = {
                    auto_show = false,
                    auto_show_delay_ms = 500, -- Delay doc popup
                },
            },
            sources = {
                min_keyword_length = 2, -- Require 2 chars before triggering
            },
        },
    },
}
