return {
    {
        "sainnhe/sonokai",
        priority = 1000,
        config = function()
            vim.g.sonokai_transparent_background = true
            vim.g.sonokai_enable_italic = "1"
            vim.g.sonokai_style = "andromeda"
            -- vim.cmd.colorscheme("sonokai")
        end,
    },
    {
        "olimorris/onedarkpro.nvim",
        priority = 1000, -- Ensure it loads first
    },
    {
        "zenbones-theme/zenbones.nvim",
        -- Optionally install Lush. Allows for more configuration or extending the colorscheme
        -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
        -- In Vim, compat mode is turned on as Lush only works in Neovim.
        dependencies = "rktjmp/lush.nvim",
        lazy = false,
        priority = 1000,
        -- you can set set configuration options here
        -- config = function()
        --     vim.g.zenbones_darken_comments = 45
        --     vim.cmd.colorscheme('zenbones')
        -- end
    },
    {
        "scottmckendry/cyberdream.nvim",
        lazy = false,
        priority = 1000,
    },
    {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function()
            vim.cmd("colorscheme rose-pine")
        end,
    },
    {
        "shaunsingh/nord.nvim",
        lazy = false,
        priority = 1000,
    },

    { "projekt0n/github-nvim-theme", name = "github-theme" },
    { "marko-cerovac/material.nvim", name = "material-theme" },
    {
        "loctvl842/monokai-pro.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("monokai-pro").setup({
                transparent_background = true,
                terminal_colors = true,
                filter = "ristretto", -- classic | octagon | pro | ristretto
            })
            -- vim.cmd.colorscheme("monokai-pro")
        end,
    },
}
