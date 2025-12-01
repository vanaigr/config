require('mini.cursorword').setup()

local palette = require('rose-pine.palette')

local function initColors()
    vim.api.nvim_set_hl(0, 'MiniCursorword', { sp=palette.gold, underline = true, bold = true })
    vim.api.nvim_set_hl(0, 'MiniCursorwordCurrent', {})
end

local group = vim.api.nvim_create_augroup('WordHighlighting', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = '*',
    callback = initColors,
    group = group
})

initColors()
