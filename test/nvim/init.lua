vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local got_path = vim.fn.stdpath("data") .. "/got/got.nvim"
if not vim.loop.fs_stat(got_path) then
    vim.fn.system({
        "git", "clone", "--depth", "1",
        "https://github.com/zuice/got.nvim.git",
        got_path,
    })
end
vim.opt.rtp:prepend(got_path)

require("got").setup("plugins", {
    root = vim.fn.stdpath("data") .. "/got",
    debug = true,
})
