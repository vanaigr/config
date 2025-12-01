if false then
require("scrollbar").setup{
    max_lines = 10000,
    handle = {
        text = " ",
        blend = 10,
        highlight = "CursorColumn",
        hide_if_all_visible = false,
    },
    marks = {
        Search = { priority = 1 },
        Error = { priority = 2 },
        Warn = { priority = 3 },
        Info = { priority = 5 },
        Hint = { priority = 4 },
        Misc = { priority = 6 },
    },
    excluded_buftypes = { },
    handlers = {
        cursor = false,
        diagnostic = true,
        gitsigns = false,
        handle = true,
        search = false,
        ale = false,
    },
}
end

require('scrollview').setup({
    excluded_filetypes = {},
    current_only = false,
    base = 'right',
    column = 1,
    --signs_overflow = 'right',
    signs_scrollbar_overlap = 'over',
    signs_max_per_row = 1,
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
