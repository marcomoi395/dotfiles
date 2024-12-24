-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- No save swap file
vim.o.swapfile = false

vim.o.termguicolors = true

vim.cmd("colorscheme rose-pine-main")


vim.api.nvim_exec([[
  augroup TransparentBackground
    autocmd!
    autocmd GUIEnter * hi Normal guibg=NONE ctermbg=NONE
    autocmd GUIEnter * hi NonText guibg=NONE ctermbg=NONE
    autocmd GUIEnter * hi SignColumn guibg=NONE ctermbg=NONE
    autocmd GUIEnter * hi StatusLine guibg=NONE ctermbg=NONE
    autocmd GUIEnter * hi VertSplit guibg=NONE ctermbg=NONE
    autocmd GUIEnter * hi TabLine guibg=NONE ctermbg=NONE
  augroup END
]], false)
