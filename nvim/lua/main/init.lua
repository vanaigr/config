local vim = vim -- fix lsp warning

-----vim.on_key(function(a, b) print(a, b) end)

pcall(vim.api.nvim_exec2, 'language en_US', {})

function LoadModule(name)
    local loaded, result = pcall(require, name)

    if not loaded then
        print("ERROR. `" .. name .. "` not loaded: " .. result .. '\n')
        return false, result
    else
        return true, result
    end
end

function P(v)
    print(vim.inspect(v))
    return v
end

_G.my_keys = {}
vim.on_key(function(key)
    local pos = vim.fn.getcurpos()
    table.insert(_G.my_keys, { key = key, position = pos })
end)
vim.keymap.set('n', ']', function()
    _G.my_keys2 = _G.my_keys
    _G.my_keys = {}
    print("DONE")
end)

vim.api.nvim_create_user_command('OpenConfig', function()
    vim.cmd('tabe ' .. vim.fn.stdpath('config'))
end, {})

vim.api.nvim_create_user_command('UP' , "call search('[A-Z][A-Z]', 'besW')", {})
vim.api.nvim_create_user_command('UPN', "call search('[A-Z][A-Z]', 'esW')", {})

--vim.g.editorconfig = false

vim.g.clipboard = 'xclip'

vim.g.mapleader = ' '

vim.opt.langremap = false

vim.opt.number = true
vim.opt.relativenumber = true -- supposedly faster (some nvim issue)

if true then
    vim.opt.tabstop = 4
    vim.opt.softtabstop = 4
    vim.opt.shiftwidth = 4
else
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
    vim.opt.shiftwidth = 2
end
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.smarttab = true
vim.opt.inccommand = 'nosplit'

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 4

vim.opt.virtualedit = 'onemore,block'
vim.opt.selection = 'exclusive'
-- vim.opt.mouse = '' -- don't move cursor when focusing nvim-qt window

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.cmdheight = 2 -- for remapping ; to open c_CTRL-f
--vim.opt.breakindent = true -- breakindent will forever be slow :(

vim.opt.undofile = true

local group = vim.api.nvim_create_augroup('MainInigAutocmds', { clear = true })

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    group = group,
    callback = function()
        -- why does tabstop work and this doesn't (buth buffer-local)
        -- why I have to set it for every new buffer.
        if vim.api.nvim_get_option_value('modifiable', { scope = 'local' }) then
            -- somehow VERY important that buffer is modifiable
            vim.opt.fileformat = 'unix'
        end
    end
})

-- why is this here, and fileformat is up there???????
vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
        vim.opt.formatoptions = vim.opt.formatoptions - { "c","r","o" }
        -- 4 should be tabstop
        vim.opt.cinoptions = 'L0(4m1'
    end
})

vim.api.nvim_create_autocmd("TextYankPost", {
    pattern = { '*' }, group = group,
    callback = function()
        local hi_group = 'YankHighlight'

        local ok, op, name = pcall(function()
            return vim.v.event.operator, vim.v.event.regname
        end)
        if ok and op ~= 'y' then return end

        if ok then
            if (name == '+' or name == '*') then
                hi_group = 'ClipYankHighlight'
            elseif name ~= '' then
                hi_group = 'RegYankHighlight'
            end
        end

        vim.hl.on_yank({ higroup = hi_group, timeout = 400 })
    end
})

-- remove trailing whitespace
local cursorNs = vim.api.nvim_create_namespace("Cursor@init.lua")
vim.g.my_autoformat = true
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = group, pattern = { "*" },
    callback = function(ev)
        if not vim.g.my_autoformat then
            return
        end
        local bufId = ev.buf
        vim.api.nvim_buf_call(bufId, function()
            local lastCursor = vim.api.nvim_win_get_cursor(0)
            local id = vim.api.nvim_buf_set_extmark(
                0, cursorNs, lastCursor[1]-1, lastCursor[2], {}
            )
            vim.cmd[=[%s/\s\+$//e]=]
            local newPos = vim.api.nvim_buf_get_extmark_by_id(0, cursorNs, id, {})
            newPos[1] = newPos[1] + 1
            vim.api.nvim_win_set_cursor(0, newPos)
            vim.api.nvim_buf_clear_namespace(0, cursorNs, 0, -1)
        end)
    end,
})

vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
        vim.opt_local.spelloptions:remove('noplainbuffer')
    end
})

LoadModule('main.plugins')
LoadModule('main.remap')

vim.g._ts_force_sync_parsing = true
