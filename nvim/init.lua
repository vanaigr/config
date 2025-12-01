local vim = vim -- fix lsp warning

local ok, config = pcall(require, 'localSettings')

if ok then
    _G.my_config = config
else
    _G.my_config = { low_perf = false }
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    print('Downloading Lazy.nvim')
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require('main')
