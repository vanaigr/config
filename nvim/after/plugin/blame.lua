local p = require('rose-pine.palette')

vim.api.nvim_set_hl(0, 'Iris_fg', { fg =  p.iris })
vim.api.nvim_set_hl(0, 'Foam_fg', { fg =  p.foam })
vim.api.nvim_set_hl(0, 'Text_fg', { fg =  p.highlight_high })

require('blame').setup {
    virtual_style = "right_align",
    focus_blame = true,
    merge_consecutive = true,
    colors = nil,
    blame_options = nil,
    commit_detail_view = "vsplit",
    format_fn = function(a, b, idx)

        local summary = a.summary
        if #summary > 30 then
            summary = string.sub(summary, 1, 30)
        end

        return {
            idx = idx,
            values = {
                {
                    textValue = os.date('%d.%m.%y', a.committer_time),
                    hl = 'Text_fg',
                },
                { textValue = (a.author):sub(1, 5), hl = 'Foam_fg' },
                { textValue = summary, hl = 'Iris_fg' },
            },
            format = "%s %s | %s",
        }
    end,
    mappings = {
        commit_info = "i",
        stack_push = "<right>",
        stack_pop = "<left>",
        show_commit = "<CR>",
        close = "<a-q>",
    }
}
