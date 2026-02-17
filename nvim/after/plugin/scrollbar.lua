require('scrollview').setup({
    excluded_filetypes = {},
    current_only = false,
    base = 'right',
    column = 1,
    --signs_overflow = 'right',
    signs_scrollbar_overlap = 'over',
    signs_max_per_row = 1,
    scrollview_winblend = 50,
    scrollview_winblend_gui = 50,
    signs_on_startup = {
        --'changelist',
        'conflicts',
        --'cursor',
        'diagnostics',
        --'folds',
        --'indent',
        --'latestchange',
        --'keywords',
        'loclist',
        --'marks'
        'quickfix',
        'search'
        --'spell',
        --'textwidth',
        --'trail',
    },
    --include_end_region = true,
    visibility = 'always',
    diagnostics_severities = {
        vim.diagnostic.severity.ERROR
    }
})

-- I have no idea why it changing these in the config above doesn't work.
vim.cmd([[
let g:scrollview_winblend = 30
let g:scrollview_winblend_gui = 30
]])
