local m = require('mapping')

local function ll(keymap) return '<leader><leader>' .. keymap end
local function ins(off, ...)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    --if vim.api.nvim_buf_get_lines(0, cursor_pos[1], cursor_pos[1]+1, false, {})
    local line = cursor_pos[1] + off
    vim.api.nvim_buf_set_lines(0, line, line, false, { ... })
end

m.n(ll('t'), function() ins(-1, 'if true then return end') end)
m.n(ll('ss'), function() ins(0, 'local ss = vim.uv.hrtime()') end)
m.n(ll('ee'), function() ins(0, 'local ee = vim.uv.hrtime()', 'print("Time:", (ee - ss) * 0.001)') end)
