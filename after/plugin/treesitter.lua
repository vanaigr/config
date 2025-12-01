local pcall = copcall or pcall

local path = vim.fn.stdpath("data") .. '/parsers'

local parsers = require('nvim-treesitter.parsers')
local config = require('nvim-treesitter.config')
local install = require('nvim-treesitter.install')
local async = require('nvim-treesitter.async')

require('nvim-treesitter').setup{
    install_dir = path,
}

local function getLoadingFiletype(buf)
    local ok, value = pcall(vim.api.nvim_buf_get_var, buf, 'my_loading_filetype')
    if not ok then
        value = 0
    end
    return value
end

local installing = nil

---@async
local function loadParser(buf)
    local value = getLoadingFiletype(buf)
    value = value + 1
    vim.api.nvim_buf_set_var(buf, 'my_loading_filetype', value)

    local filetype = vim.api.nvim_get_option_value('ft', { buf = buf })
    if filetype == 'typescriptreact' then
        filetype = 'tsx'
    end

    local parserInfo = parsers[filetype]
    if parserInfo == nil then
        return
    end

    local installed = config.get_installed('parsers')
    local found = false
    for _, name in ipairs(installed) do
        if name == filetype then
            found = true
            break
        end
    end
    if not found then
        if installing then -- bug: it locks neovim if installing the same language twice
            pcall(async.await, installing)
        end

        installing = install.install({ filetype }, { summary = true })
        if not async.await(installing) then
            return
        end
    end

    if getLoadingFiletype(buf) ~= value then
        return
    end

    vim.treesitter.start(buf, filetype)
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
        async.arun(function()
            local ok, err = pcall(loadParser, args.buf)
            if not ok then
                vim.notify('Error loading parser: ' .. err, vim.log.levels.ERROR)
            end
        end)
    end,
})
