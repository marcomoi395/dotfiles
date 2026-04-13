-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- No save swap file
vim.o.swapfile = false

vim.o.autoread = true

vim.o.termguicolors = true

vim.cmd([[colorscheme monokai-pro]])
-- vim.cmd("colorscheme material")
-- vim.cmd("colorscheme github_dark")

-- vim.g.github_dark_transparent_background = 1
-- vim.cmd([[colorscheme sonokai]])

-- vim.cmd("colorscheme onelight")
-- vim.cmd("colorscheme onedark")
-- vim.cmd([[colorscheme cyberdream ]])

-- vim.cmd("colorscheme rose-pine")
-- vim.cmd("colorscheme rose-pine-moon")
-- vim.cmd("colorscheme rose-pine-dawn")

-- vim.cmd("colorscheme nord")

vim.g.copilot_enabled = false
