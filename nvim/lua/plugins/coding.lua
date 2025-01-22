-- Copilot
return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        build = ":Copilot auth",
        event = "InsertEnter",
        opts = {
            suggestion = {
                enabled = not vim.g.ai_cmp,
                auto_trigger = true,
                keymap = {
                    accept = "<Tab>", -- handled by nvim-cmp / blink.cmp
                    next = "<M-]>",
                    prev = "<M-[>",
                },
            },
            panel = { enabled = false },
            filetypes = {
                markdown = true,
                help = true,
            },
        },
    },
    {
        "williamboman/mason.nvim",
        opts = { ensure_installed = { "gitui" } },
        keys = {
            {
                "<leader>gG",
                function()
                    Snacks.terminal({ "gitui" })
                end,
                desc = "GitUi (cwd)",
            },
            {
                "<leader>gg",
                function()
                    Snacks.terminal({ "gitui" }, { cwd = LazyVim.root.get() })
                end,
                desc = "GitUi (Root Dir)",
            },
        },
        init = function()
            -- delete lazygit keymap for file history
            vim.api.nvim_create_autocmd("User", {
                pattern = "LazyVimKeymaps",
                once = true,
                callback = function()
                    pcall(vim.keymap.del, "n", "<leader>gf")
                    pcall(vim.keymap.del, "n", "<leader>gl")
                end,
            })
        end,
    },
    {
        'numToStr/Comment.nvim',
        opts = {
            opleader = {
                ---Line-comment keymap
                line = 'gc',
                ---Block-comment keymap
                block = 'gb',
            },

        }

    }
}
