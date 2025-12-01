--[[
local m = require('mapping')
local sel = require('incselection')

m.n('\'', function()
    sel.init_selection()
end)

m.x('\'', function()
    sel.node_incremental()
end)
m.x('<A-\'>', function()
    sel.node_decremental()
end)

m.n('\\', function()
    vim.api.nvim_feedkeys('v', 'nx', false)
    sel.scope_incremental()
end)
m.x('\\', function()
    sel.scope_incremental()
end)
]]
