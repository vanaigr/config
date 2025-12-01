local s = require("spider")

s.setup {
    skipInsignificantPunctuation = true,
    subwordMovement = false,
    consistentOperatorPending = true,
}

local m = require('mapping')

local opts = { customPatterns = { patterns = { '$' }, overrideDefault = false } }
m.nxo('w', function() s.motion('w', opts) end)
m.nx('e', function()
    -- breaks for 1 letter word at start of line
    local old_count = vim.v.count1
    vim.cmd([=[silent! normal! h]=])
    for _ = 1, old_count do
        s.motion('e', opts)
    end
    vim.cmd([=[silent! normal! l]=])
end)
m.o('e', function() s.motion('e', opts) end)
m.nxo('b', function() s.motion('b') end)
