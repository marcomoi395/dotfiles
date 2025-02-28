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

    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        opts = {
            mappings = {
                complete = {
                    insert = '<Tab>',
                },
                close = {
                    normal = 'q',
                    insert = '<C-q>',
                },
                reset = {
                    normal = '<C-l>',
                    insert = '<C-l>',
                },
                submit_prompt = {
                    normal = '<CR>',
                    insert = '<C-s>',
                },
                toggle_sticky = {
                    detail = 'Makes line under cursor sticky or deletes sticky line.',
                    normal = 'gr',
                },
                accept_diff = {
                    normal = '<C-y>',
                    insert = '<C-y>',
                },
                jump_to_diff = {
                    normal = 'gj',
                },
                quickfix_answers = {
                    normal = 'gqa',
                },
                quickfix_diffs = {
                    normal = 'gqd',
                },
                yank_diff = {
                    normal = 'gy',
                    register = '"', -- Default register to use for yanking
                },
                show_diff = {
                    normal = 'gd',
                    full_diff = false, -- Show full diff instead of unified diff when showing diff window
                },
                show_info = {
                    normal = 'gi',
                },
                show_context = {
                    normal = 'gc',
                },
                show_help = {
                    normal = 'gh',
                },
            },
        }
    }
}
