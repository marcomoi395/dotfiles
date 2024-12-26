-- plugins/telescope.lua:

local builtin = require('telescope.builtin')

return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    -- or                              , branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    -- keys = {
    --     {
    --         "<leader>fg",
    --         builtin.live_grep,
    --         desc = "Telescope live grep",
    --     },
    -- },
}
