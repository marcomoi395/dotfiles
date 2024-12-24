-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Shift-Enter --
keymap.set('i', '<S-Enter>', '<Esc>o', opts)
keymap.set('n', '<S-Enter>', 'o', opts)

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")
-- keymap.set("i", "<C-a>", "<Esc>gg<S-v>G")

-- Duplication
keymap.set("v", "<C-d>", "<Esc>yyPi")

-- Quit
-- keymap.set("i", "<c-q>", "<esc><c-z>")
-- keymap.set("n", "<c-q>", "<c-z>")
keymap.set('n', '<Leader>w', ":update<Return>")
keymap.set('n', '<Leader>q', ":quit<Return>")
keymap.set('n', '<Leader>Q', ":qa<Return>")

-- Delete a word backwards
keymap.set("n", "dw", "vb_d")

-- Copy/Paste
-- keymap.set("v", "<C-S-c>", "y", opts)

-- New tab
keymap.set('n', "te", ":tabedit", opts)
keymap.set('n', "<tab>", ":tabnext<Return>", opts)
keymap.set('n', "<s-tab>", ":tabprev<Return>", opts)
keymap.set('n', "tw", ":tabclose<Return>", opts)


-- Split window
keymap.set('n', 'ss', ':split<Return>', opts)
keymap.set('n', 'sv', ':vsplit<Return>', opts)
-- Move window
keymap.set('n', 'sh', '<C-w>h')
keymap.set('n', 'sk', '<C-w>k')
keymap.set('n', 'sj', '<C-w>j')
keymap.set('n', 'sl', '<C-w>l')

-- Resize window
keymap.set('n', '<C-w><left>', '<C-w><')
keymap.set('n', '<C-w><right>', '<C-w>>')
keymap.set('n', '<C-w><up>', '<C-w>+')
keymap.set('n', '<C-w><down>', '<C-w>-')

-- Undo
keymap.set('n', '<C-z>', 'u')
keymap.set('i', '<C-z>', '<Esc>ui')

-- Run python
keymap.set('n', '<leader>r', ':!python3 %<Return>', opts)
-- -- Redo
-- keymap.set('n', '<C-S-Z', 'C-r')
-- keymap.set('i', '<C-S-Z', 'C-r')

-- Diagnostics
keymap.set('n', 'C-j', function()
  vim.diagnostic.goto_next()
end, opts)
