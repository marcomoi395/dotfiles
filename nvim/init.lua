-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- No save swap file
vim.o.swapfile = false

vim.o.termguicolors = true

-- vim.cmd("colorscheme rose-pine-main")
vim.g.sonokai_transparent_background = 1

-- vim.cmd("colorscheme onelight")
-- vim.cmd("colorscheme onedark")
vim.cmd [[colorscheme sonokai]]


-- vim.api.nvim_exec([[
--   augroup TransparentBackground
--     autocmd!
--     autocmd GUIEnter * hi Normal guibg=NONE ctermbg=NONE
--     autocmd GUIEnter * hi NonText guibg=NONE ctermbg=NONE
--     autocmd GUIEnter * hi SignColumn guibg=NONE ctermbg=NONE
--     autocmd GUIEnter * hi StatusLine guibg=NONE ctermbg=NONE
--     autocmd GUIEnter * hi VertSplit guibg=NONE ctermbg=NONE
--     autocmd GUIEnter * hi TabLine guibg=NONE ctermbg=NONE
--   augroup END
-- ]], false)

vim.o.tabstop = 4      -- A TAB character looks like 4 spaces
vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4  -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4   -- Number of spaces inserted when indenting
