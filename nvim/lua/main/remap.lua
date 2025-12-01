local vim = vim -- fix lsp warning

local m = require('mapping')

m.ci('<A-w>', '<bs>')

m.ci('<A-space>', '_')

m.n('q', '')
m.n('Q', 'q')

local _ = [===[
this breaks neovim. It just starts randomly moving the cursor
sometimes. And also breaks multicursor

-- i HAVE to do this, so that it executes before any other autocmd
local esc_pos
vim.api.nvim_create_autocmd('ModeChanged', {
    callback = function()
        if esc_pos ~= nil then
            vim.api.nvim_win_set_cursor(0, esc_pos)
            esc_pos = nil
        end
    end,
})

local function make_esc(key, retKey)
    m.i(key, function()
        esc_pos = vim.api.nvim_win_get_cursor(0)
        return retKey
    end, { remap = false, expr = true })
end
]===]

local function make_esc(key, retKey)
    m.i(key, retKey .. '`^')
end

make_esc('<esc>', '<esc>') -- prevent cursor from moving when exiting insert mode
make_esc('<C-c>', '<C-c>')
make_esc('<A-i>', '<Esc>')
make_esc('<A-u>', '<Esc>')

m.nx('<A-i>', '<esc>')
m.c('<A-i>', '<C-c>')
m.nx('<A-u>', '<esc>')
m.c('<A-u>', '<C-c>')

m.n('<A-w>', '<C-w>')
m.n('<bs>', '<C-w>') -- for system-wide remapped A-w

m.n('<A-s>', '<cmd>w<cr>')
m.n('<A-q>', '<cmd>q<cr>')
m.n('<A-a>', '<cmd>so<cr>')

for _, key in ipairs{ 'E', 'gE' } do
  m.n(key, '<cmd>silent! normal! h'..key..'l<cr>')
end

-- make move-to-end mapping move one past end
m.n('$', 'g$') -- why does g$ already do 'l' with onemore ?? regular $ would be '$l'
m.n('_', 'g^')

m.n('r', 'gr')
m.n('a', 'A')
m.n('A', 'I')
m.n('x', '"_x')

-- add indentation when entering insert mode
m.n('i', function() -- https://stackoverflow.com/a/3020022/18704284
    if vim.v.count <= 1 and vim.fn.match(vim.fn.getline('.'), '\\v[^[:space:]]') == -1 then
        return '"_cc'
    else
        return 'i'
    end
end, { expr = true })

m.n('<space>', '')

m.i('<A-m>', '<cr>')
m.c('<A-m>', '<cr>')

m.n('<A-n>', '<cmd>noh<cr>')

m.n('<A-t>', 'gt')
m.n('<A-g>', 'gT')

m.ic('<C-bs>', '<C-w>')

m.n('<C-s>', ':%s//gc<left><left><left>')
m.x('<C-s>', ':s//gc<left><left><left>')

m.n('>>', 'i<C-t><Esc>`^') --tabs keep cursor in the same place
m.n('<<', 'i<C-d><Esc>`^')
m.n('<A-.>', 'i<C-t><Esc>`^')
m.n('<A-,>', 'i<C-d><Esc>`^')
m.i('<Tab>', '<C-t>')
m.i('<S-Tab>', '<C-d>')

local ns = vim.api.nvim_create_namespace('')
local function keepSelection(command)
    local startPos = vim.fn.getpos('v')
    local endPos   = vim.fn.getpos('.')
    local sMark = vim.api.nvim_buf_set_extmark(0, ns, startPos[2]-1, startPos[3]-1, {})
    local eMark = vim.api.nvim_buf_set_extmark(0, ns, endPos  [2]-1, endPos  [3]-1, {})

    vim.cmd(command)

    local sPos = vim.api.nvim_buf_get_extmark_by_id(0, ns, sMark, {})
    local ePos = vim.api.nvim_buf_get_extmark_by_id(0, ns, eMark, {})
    vim.api.nvim_buf_del_extmark(0, ns, sMark)
    vim.api.nvim_buf_del_extmark(0, ns, eMark)

    vim.fn.setpos(".", { 0, sPos[1]+1, sPos[2]+1, 0 })
    vim.cmd('normal! '..vim.fn.visualmode())
    vim.fn.setpos(".", { 0, ePos[1]+1, ePos[2]+1, 0 })
end

-- keep visual selection when changing indentation
m.x('<A-.>', function() keepSelection('normal! >') end)
m.x('<A-,>', function() keepSelection('normal! <') end)

m.nx(')', '<C-y>') -- move screen but not cursor
m.nx('(', '<C-e>')

m.nx('<A-0>', '<C-y>')
m.nx('<A-9>', '<C-e>')

m.t('<C-q>', '<C-\\><C-n>') -- go to normal mode in terminal

m.n('n', '<cmd>keepjumps normal! n<cr>')
m.n('N', '<cmd>keepjumps normal! N<cr>')


-- add insert and normal modes to command mode
local commandGoup = vim.api.nvim_create_augroup('CommandGoup', { clear = true })

local function setup_cmd()
    local winId = vim.api.nvim_get_current_win()
    local bufId = vim.api.nvim_win_get_buf(winId)

    local cmdOpt = { scope = 'local' }
    local height = vim.api.nvim_get_option_value('cmdheight', cmdOpt)
    local newHeight = math.max(height-2, 0)

    local bs = vim.api.nvim_get_option_value('backspace', {})
    local new_bs = 'indent,start'

    vim.api.nvim_create_autocmd('CmdwinLeave', {
        group = commandGoup, once = true,
        callback = function()
            if vim.api.nvim_get_option_value('cmdheight', cmdOpt) == newHeight then
                vim.api.nvim_set_option_value('cmdheight', height, cmdOpt)
            end
            if vim.api.nvim_get_option_value('backspace', {}) == new_bs then
                vim.api.nvim_set_option_value('backspace', bs, {})
            end
        end,
    })

    vim.api.nvim_set_option_value('cmdheight', newHeight, cmdOpt)
    vim.api.nvim_set_option_value('backspace', new_bs, {})


    vim.api.nvim_exec_autocmds('User', { pattern = 'SetupCommandCMP' })

    -- nvim buf set opt backspace - eol

    vim.api.nvim_win_set_height(winId, 1)
    vim.api.nvim_win_set_option(winId, 'number', false)
    vim.api.nvim_win_set_option(winId, 'relativenumber', false)

    local mapOpts = { buffer = bufId }

    m.i('<A-q>', '<Esc><cmd>q<cr>', mapOpts)
    m.n('<A-e>', '', mapOpts)
    m.n(';', function() vim.api.nvim_feedkeys(':', 'n', false) end, mapOpts)
    m.n('<cr>', '<cr>', mapOpts) -- default cr behavior
    m.n('<A-m>', '<Enter>', mapOpts)
    m.i('<A-m>', '<Esc><Enter>', mapOpts)

    vim.cmd.startinsert()
end

local function command_mode()
    vim.api.nvim_create_autocmd('CmdwinEnter', { group = commandGoup, once = true, callback = setup_cmd })
    return 'q:'
end
local cmd_opts = { expr = true, remap = false }

m.nx('<A-e>', command_mode, cmd_opts)
--m.i('<A-e>', function() return '<Esc>' .. command_mode() end, cmd_opts)


-- scroll
local ctrlY = vim.api.nvim_replace_termcodes('<C-y>', true, false, true)
local ctrlE = vim.api.nvim_replace_termcodes('<C-e>', true, false, true)

local function scroll(m1)
    return function()
        local start_row = vim.fn.winline()

        local distance = math.floor(vim.fn.winheight(0) * 0.4)
        vim.api.nvim_feedkeys(distance .. m1, 'nx', false)
        local target_lnum = vim.api.nvim_win_get_cursor(0)[1]

        local seen = { [start_row] = true }
        while true do
            local cur_row = vim.fn.winline()
            if seen[cur_row] then break end
            seen[cur_row] = true
            if cur_row < start_row then
                vim.api.nvim_feedkeys(ctrlY, 'nx', false)
            else
                vim.api.nvim_feedkeys(ctrlE, 'nx', false)
            end
            local cur_lnum = vim.api.nvim_win_get_cursor(0)[1]
            if target_lnum ~= cur_lnum then
                local diff = target_lnum - cur_lnum
                local dir
                if diff < 0 then
                    diff = -diff
                    dir = 'gk'
                else
                    dir = 'gj'
                end
                vim.api.nvim_feedkeys(diff .. dir, 'nx', false)
                break
            end
        end
    end
end

m.nx('<A-k>', scroll('gk'))
m.nx('<A-j>', scroll('gj'))

-- <A-j> and <A-k> are remapped system-wide to these keys
m.nx('<Up>', scroll('gk'))
m.nx('<Down>', scroll('gj'))

local function eol()
    vim.api.nvim_feedkeys('g_', 'nx', false)
    local pos = vim.api.nvim_win_get_cursor(0)
    pos[2] = pos[2] + 1
    vim.api.nvim_win_set_cursor(0, pos)
end

m.nx('<A-h>', '_')
m.nx('<A-l>', eol)
m.nx('<left>', '_')
m.nx('<right>', eol)

m.nx('j', function()
    if vim.v.count == 0 and vim.v.count1 == 1 then
        return 'gj'
    else
        print('j Executed with count', vim.v.count)
        return 'j'
    end
end, { expr = true })

m.nx('k', function()
    if vim.v.count == 0 and vim.v.count1 == 1 then
        return 'gk'
    else
        print('k Executed with count', vim.v.count)
        return 'k'
    end
end, { expr = true })

m.nxo('J', '5gj')
m.nxo('K', '5gk')

m.n('gj', 'J')

m.n('<leader>u', "<cmd>UndotreeShow<cr>")

m.o('_', function() vim.cmd'keepjumps silent! normal! _' end)

-- work with system clipboard without mentioning the register
m.nx('<leader>y', "\"+y")
m.nx('<leader>d', "\"+d")

-- haha Y is not Y but y$, because Y is yy RTFM
-- https://github.com/neovim/neovim/issues/416
m.nx('<leader>Y', "\"+y$")
m.nx('<leader>D', "\"+d$")

-- line without indentation and newline
m.n('d<leader>l', "_vg_d\"_dd")
m.n('y<leader>l', "_vg_y`^")
m.o('<leader>l', "<cmd>normal! _vg_l<cr>")
m.x('<leader>l', "<esc>_vg_")

m.n('<A-y>', 'yy')
m.n('<A-d>', '"_dd')
m.x('<A-d>', '"_d')

m.o('gv', '<cmd>normal! `<v`><cr>')

-- paste
m.o('gp', function()
    --local pos = vim.fn.getpos('.')
    --vim.api.nvim_buf_set_mark(0, '`', pos[2], pos[3], {})
    local s = vim.api.nvim_buf_get_mark(0, '[')
    local e = vim.api.nvim_buf_get_mark(0, ']')
    print(vim.inspect({ s=s, e=e }))
    --vim.api.nvim_win_set_cursor(0, { s[1], s[2] })
    --vim.cmd('normal! v')
end)

m.n('gp', function() -- select last changed area
    local pos = vim.fn.getpos('.')
    vim.api.nvim_buf_set_mark(0, '`', pos[2], pos[3], {})
    local s = vim.api.nvim_buf_get_mark(0, '[')
    local e = vim.api.nvim_buf_get_mark(0, ']')
    vim.api.nvim_win_set_cursor(0, { s[1], s[2] })
    vim.cmd('normal! v')
    if vim.opt.selection._value == 'exclusive' and e[2] < 2147483647 then e[2] = e[2] + 1 end -- vim's position is inconsistent between yank/paste and insert https://superuser.com/q/1465550
    vim.api.nvim_win_set_cursor(0, { e[1], e[2] })
end)

local function check_nonsense(register)
    if vim.v.count1 > 1000 then
        error('[my] Pasting too much!')
    end
    if #vim.fn.getreg(register) > 100000 then
        error('[my] Paste too big!')
    end
end

-- TODO: rewrite with vim.api.nvim_put() / nvim_paste()
local function linewise_paste(register)
    check_nonsense(register)
    -- yes, a loop. How else would I do that?
    for i = 1, vim.v.count1 do
        vim.cmd('put '..register)
    end
    vim.cmd([=[keepjumps normal! `]l]=])
end
local function charwise_paste(register)
    check_nonsense(register)
    local regInfo = vim.fn.getreginfo(register)
    local regValue = vim.fn.getreg(register)
    vim.fn.setreg(register, regValue, 'v')
    vim.cmd('normal! '..vim.v.count1..'"'..register .. 'gP')
    if register ~= '+' then
        vim.fn.setreg(register, regInfo) -- may not work, but I don't know
    end
end
local function visual_paste(register)
    check_nonsense(register)
    -- visual replaces that register
    local preserved = '"'
    local regtype = vim.fn.getregtype(preserved)
    local regContent = vim.fn.getreg(preserved)
    vim.cmd('keepjumps normal! ' .. vim.v.count1 .. '"' .. register .. 'gp')
    if register ~= '+' then
        vim.fn.setreg(preserved, regContent, regtype)
    end
end

m.n('<leader>p', function() linewise_paste('+') end)
m.n('<leader><A-p>', function() charwise_paste('+') end)
m.x('<leader>p', function() visual_paste('+') end)
m.x('<leader><A-p>', function() visual_paste('+') end)

m.n('p', function() linewise_paste(vim.api.nvim_get_vvar('register')) end)
m.n('<A-p>', function() charwise_paste(vim.api.nvim_get_vvar('register')) end)
m.x('p', function() visual_paste(vim.api.nvim_get_vvar('register')) end)

m.i('<A-p>', '<C-o><A-p>', { remap = true })

m.x('v', function()
    local mode = vim.fn.mode():sub(1,1)
    if mode == 'v' then return 'V'
    elseif mode == 'V' then return 'v'
    else return mode end
end, { expr = true })

m.o('f', '<cmd>norm! gg0vG$<cr>')
m.x('f', '<esc>gg0vG$')

m.n('<A-f>', '==')
m.x('<A-f>', function() keepSelection('norm! =') end)


local function adjustFontSize(amount)
    if vim.fn.has('gui_running') == 0 then return end

    local orig_font = vim.api.nvim_get_option_value('guifont', {})
    local parts = vim.split(orig_font, ':h')
    assert(#parts == 2)

    local font_size = tonumber(parts[2])
    local new_size = font_size + amount
    if new_size < 4 then new_size = 4
    elseif new_size > 40 then new_size = 40 end

    vim.opt.guifont = parts[1] .. ':h' .. new_size
end

m.n('<C-=>', function() adjustFontSize( 1) end)
m.n('<C-->', function() adjustFontSize(-1) end)


local quickfixGroup = vim.api.nvim_create_augroup('QuickfixListMappings', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = function()
        m.n('<cr>', '<cmd>.cc<cr><C-w>p', { buffer = true })
        m.n('o', '<cmd>.cc<cr>', { buffer = true })
    end,
    group = quickfixGroup
})


do -- help
    local selection = require('main.getSelection')

    local function getHelp(args, s)
        local str = table.concat(vim.api.nvim_buf_get_text(0, s[1], s[2], s[3], s[4], {}), '\n')
        vim.cmd('help '..str)
    end

    m.n('<leader>H', 'K')
    m.n('<leader>h', function() return selection.callOpfunc(getHelp, nil) end, { expr = true })
    m.x('<leader>h', function() selection.callVisual(getHelp, nil) end)
    m.n('<leader>hh', function() return selection.callOpfunc(getHelp, nil)..'iw' end, { expr = true })
end


LoadModule('main.runBuf')

local motion = require('motion')

local var_decl_regex = vim.regex([[\M\(=\@<!==\@!\|:\@<!::\@!\)]]) -- = or : but not == or ::
local val_start_regex = vim.regex([[\S]])
local skip_regex = vim.regex([[\M\((\|{\|[\|;\|,\)]])
local paren, brace, bracket = ('('):byte(1), ('{'):byte(1), ('['):byte(1)
local function select_variable_value()
    local initial_pos = vim.api.nvim_win_get_cursor(0)
    initial_pos[1] = initial_pos[1] - 1

    -- 0-indexed
    local start_lnum = initial_pos[1]

    -- 0-indexed
    local start_col = var_decl_regex:match_line(0, start_lnum)
    if start_col then
        local col_off = val_start_regex:match_line(0, start_lnum, start_col+1)
        if col_off then
            start_col = start_col+1 + col_off
        end
    end
    if not start_col then
        vim.notify("Could not find variable declaration", vim.log.levels.ERROR, {})
        return
    end

    local cur_lnum = start_lnum
    local cur_col = start_col
    while true do
        local next_col_off = skip_regex:match_line(0, cur_lnum, cur_col)
        if not next_col_off then
            cur_col = #vim.fn.getline(1 + cur_lnum)
            break
        end
        cur_col = cur_col + next_col_off -- just in case

        local byte = vim.fn.getline(1 + cur_lnum):byte(1 + cur_col)
        if byte == paren or byte == brace or byte == bracket then
            vim.api.nvim_win_set_cursor(0, { 1 + cur_lnum, cur_col })
            vim.cmd('keepjumps silent! normal! %')

            local new_pos = vim.api.nvim_win_get_cursor(0)
            local new_lnum = new_pos[1] - 1
            local new_col = new_pos[2]

            if new_lnum > cur_lnum or (new_lnum == cur_lnum and new_col > cur_col) then
                cur_lnum = new_lnum
                cur_col = new_col + 1
            else
                cur_col = cur_col + 1
            end
        else
            break
        end
    end

    local p1 = { 1 + start_lnum, start_col }
    local p2 = { 1 + cur_lnum, cur_col }

    local mode = vim.api.nvim_get_mode().mode
    if mode == 'v' or mode == 'V' or mode == '' then
        if mode ~= 'v' then vim.cmd('norm! v') end
        if motion.range_to_visual(p1, p2) then
            motion.util.visual_start(p1, p2, 'v')
            return true
        end
    else
        if motion.textobj_set_endpoints(p1, p2) then
            return true
        end
    end

    -- return cursor to initial position
    vim.api.nvim_win_set_cursor(0, { 1 + initial_pos[1], initial_pos[2] })
    return false
end

m.n('d<leader>v', function()
    local start_lnum = vim.fn.line('.') - 1
    if not select_variable_value() then return end
    local register = vim.api.nvim_get_vvar('register')
    vim.cmd('silent! norm! "'..register..'d')
    vim.api.nvim_buf_set_lines(0, start_lnum, start_lnum+1, false, {})
end)
m.n('y<leader>v', function()
    local pos = vim.api.nvim_win_get_cursor(0)
    if not select_variable_value() then return end
    local register = vim.api.nvim_get_vvar('register')
    vim.cmd('norm! "'..register..'y')
    vim.api.nvim_win_set_cursor(0, pos)
end)
m.ox('<leader>v', function() select_variable_value() end)

m.x('<A-/>', '""y/<C-r>"<cr>')



-- alt is now shift

-- already mapped by pairs
-- m.ic('<A-9>', '(')
-- m.ic('<A-0>', ')')

-- m.ic('<A-[>', '{')
-- m.ic('<A-]>', '}')

m.ic('<A-,>', '<')
m.ic('<A-.>', '>')

--m.ic('<A-->', '_')
m.ic('<A-->', '')
m.ic('<A-=>', '+')

m.n('<A-3>', '#')
m.n('<A-8>', '*')

m.ic("<A-'>", '"')


m.n('<leader>tt', function()
    local path = vim.fn.stdpath('data') .. '/tests/'
    vim.cmd.tabe(path)
end)

m.n('<leader>nn', function()
    local path = vim.fn.stdpath('data') .. '/notes.txt'
    vim.cmd.tabe(path)
end)


local leaderi_group = vim.api.nvim_create_augroup('leaderi_group', { clear = true })
local leaderi_ns = vim.api.nvim_create_namespace('leaderi_group')
m.n('<leader>i', function()
    local ns = leaderi_ns
    local group = leaderi_group

    local start_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd('norm! j')
    local next_pos = vim.api.nvim_win_get_cursor(0)
    local next_id = vim.api.nvim_buf_set_extmark(0, ns, next_pos[1] - 1, next_pos[2], {})
    P(start_pos)
    P(next_pos)

    -- TODO: restore window?
    vim.api.nvim_win_set_cursor(0, start_pos)

    vim.api.nvim_create_autocmd('ModeChanged', {
        pattern = 'i:n',
        group = group,
        once = true,
        callback = function()
            local pos = vim.api.nvim_buf_get_extmark_by_id(0, ns, next_id, {})
            vim.api.nvim_buf_clear_namespace(0, ns, pos[1], pos[2] + 1)
            pos[1] = pos[1] + 1
            P(pos)
            vim.api.nvim_win_set_cursor(0, pos)
        end
    })

    vim.api.nvim_feedkeys('i', 'nx!', false)
end)


m.n('*', function()
    vim.fn.setreg('/', '\\<' .. vim.fn.expand('<cword>') .. '\\>', 'v')
    if vim.api.nvim_get_option_value('hlsearch', {}) then
        vim.cmd('set nohlsearch hlsearch')
    end
end)

m.n('<leader><leader>u', function()
    local buf = vim.api.nvim_get_current_buf()

    local ok, variable = pcall(vim.api.nvim_buf_get_var, buf, 'MyUndoCheckpoint')
    if ok then
        --print('reset', variable)
        vim.api.nvim_buf_del_var(buf, 'MyUndoCheckpoint')
        vim.cmd('undo ' .. variable)
        print('Reset undo position')
    else
        local pos = vim.fn.undotree().seq_cur
        vim.api.nvim_buf_set_var(buf, 'MyUndoCheckpoint', pos)
        print('Remembered undo position')
        --print('set', pos)
    end
end)

