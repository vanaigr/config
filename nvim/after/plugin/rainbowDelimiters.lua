local function initColors()
    local function h(name, fg)
        vim.api.nvim_set_hl(0, 'RainbowDelimiter'..name, { fg = fg })
    end
    h('Red', '#cf2a00')
    h('Yellow', '#cfc730')
    h('Green', '#53bb2a')
    h('Cyan', '#307f7f')
    h('Blue', '#334edb')
    h('Violet', '#f33e6a')
end

local group = vim.api.nvim_create_augroup('RainbowHighlighting', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = '*',
    callback = initColors,
    group = group
})

initColors()
