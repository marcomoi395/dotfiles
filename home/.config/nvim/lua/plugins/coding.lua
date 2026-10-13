return {
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup({
                toggler = {
                    ---Line-comment keymap
                    line = "gc",
                    ---Block-comment keymap
                    block = "gb",
                },
            })
        end,
    },
    { "mg979/vim-visual-multi" },
    {
        "CRAG666/code_runner.nvim",
        config = function()
            require("code_runner").setup({
                -- mode = "tab",
                filetype = {
                    cpp = "cd $dir && g++ $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt && rm $fileNameWithoutExt",
                    python = "python3 -u",
                    go = "go run",
                    typescript = "deno run",
                },
                term = {
                    position = "vsplit",
                    size = 0.1,
                },
            })
        end,
    },
}
