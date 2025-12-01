local done
local function setup()
    if done then return end
    done = true
    vim.api.nvim_exec_autocmds('User', { pattern = 'load-comment' })

    require("Comment").setup{
        padding = false,
        sticky = true,
        toggler = { line = '<Plug>I_LOVE_HACKS_1' },
        opleader = { line = '<Plug>I_LOVE_HACKS_2' },
    }
end

local m = require('mapping')
m.n(
    'gcc',
    function() setup(); return '<Plug>I_LOVE_HACKS_1' end,
    { expr = true, remap = true }
) -- not recursive!
m.n(
    'gc',
    function() setup(); return '<Plug>(comment_toggle_linewise)' end,
    { expr = true, remap = true }
)
m.ox(
    'gc',
    function() setup(); return '<Plug>I_LOVE_HACKS_2' end,
    { expr = true, remap = true }
)

local this_doesnt_work = [==[
function! Test()
    nnoremap abc <cmd>echo 'Hi!'<cr>
    return 'abc'
endfun

nmap <expr> abc Test()
]==]
