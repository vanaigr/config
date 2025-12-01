-- add mappings to execute text objects as lua/vim/keys

local vim = vim -- fix lsp warning
local destr = table.unpack or unpack

local function luaFunc(str)
    local func, err = load(str)
    if func then func()
    else vim.notify('Cannot execute Lua chunk: ' .. err, vim.log.levels.ERROR, {}) end
end
local function vimFunc(str) vim.cmd(str) end
local function keyFunc(str) vim.fn.feedkeys(str) end

local function runBufferCommand(args, coords)
    local func = destr(args)
    local sl, sc, el, ec = destr(coords)
    local str = table.concat(vim.api.nvim_buf_get_text(0, sl, sc, el, ec, {}), '\n')
    vim.cmd.redraw() -- https://stackoverflow.com/a/19206860/18704284
    func(str)
end

local sel = require('main.getSelection')
local m = require('mapping')

local prefix = '<leader>r'
local expr = { expr = true }

for key, func in pairs({ l = luaFunc, v = vimFunc, k = keyFunc, }) do
    local args = { func }
    m.n(prefix..key..key, function() sel.callLine(runBufferCommand, args) end)
    m.n(prefix..key,function() return sel.callOpfunc(runBufferCommand, args) end, expr)
    m.x(prefix..key, function() sel.callVisual(runBufferCommand, args) end)
end
