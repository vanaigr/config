local vim = vim -- fix lsp warning
local destr = table.unpack or unpack

local M = {}

function M.printError(msg)
    vim.cmd.redraw() -- https://stackoverflow.com/a/19206860/18704284
    vim.notify(msg, vim.log.levels.ERROR, {})
end

function M.fixMarkerCoords(sl, sc, el, ec) -- pray that this will work
    sl = sl - 1
    el = el - 1
    sc = sc - 1
    ec = ec - 1

    local lastCharLen = vim.fn.len(vim.fn.strpart(vim.fn.getline(el+1), ec, 1, true))
    ec = ec + lastCharLen

    return { sl, sc, el, ec }
end

-- https://github.com/neovim/neovim/issues/14157#issuecomment-1320787927
local set_opfunc = vim.fn[vim.api.nvim_exec([[
  func s:set_opfunc(val)
    let &opfunc = a:val
  endfunc
  echon get(function('s:set_opfunc'), 'name')
]], true)]

-- we need to do expr + return 'g@' instead of feedkeys because ?
--run command with text object
function M.callOpfunc(func, args)
    local cursorPos = vim.fn.getpos('.')

    local function opfunc(type)
        vim.fn.setpos('.', cursorPos)

        if type ~= 'line' and type ~= 'char' then M.printError('Opfunc type '..type..' is not supported'); return end
        local sl, sc = destr(vim.fn.getpos("'["), 2, 3)
        local el, ec = destr(vim.fn.getpos("']"), 2, 3)
        if type == 'line' then
            sc = 1
            ec = 2147483647 -- ec = -1 counts backwards
        end -- selecting 'ap' paragraph text object at the end of file
            -- includes only the first character of the last line.

        func(args, M.fixMarkerCoords(sl, sc, el, ec))
    end

    set_opfunc(opfunc)
    return 'g@'
end

--run command with visual selection
function M.callVisual(func, args)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', true)
    local type = vim.fn.visualmode()
    if type ~= 'v' and type ~= 'V' then M.printError('Visual mode '..type..' is not supported'); return end -- visual block

    local sl, sc = destr(vim.fn.getpos("'<"), 2, 3)
    local el, ec = destr(vim.fn.getpos("'>"), 2, 3)

    if vim.api.nvim_get_option('selection') == 'exclusive' then
        sl = sl - 1
        sc = sc - 1
        el = el - 1
        ec = ec - 1 -- end is already exclusive
    else
        sl, sc, el, ec = destr(M.fixMarkerCoords(sl, sc, el, ec))
    end

    func(args, { sl, sc, el, ec })
end

--run command with current line
function M.callLine(func, args)
    local l = vim.fn.getpos('.')[2]
    local len = vim.fn.len(vim.fn.getline(l))

    func(args, {  l-1, 0, l-1, len })
end

return M
