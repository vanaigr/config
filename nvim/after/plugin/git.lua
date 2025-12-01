local vim = vim

local it
local function setup()
    if it then return end
    it = true
    vim.api.nvim_exec_autocmds('User', { pattern = 'load-fugitive' })
end

require('mapping').n('<leader>gg', function()
    setup()
    return '<cmd>Git<cr>'
end, { expr = true })
