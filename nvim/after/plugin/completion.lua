local vim = vim

local cmp = require('cmp')

local menus = {
    ['buffer'] = 'buf',
    ['nvim_lua'] = 'vim',
    ['nvim_lsp'] = 'lsp',
    ['cmdline'] = 'cmd',
}

local low_perf = _G.my_config.low_perf

local format = {
    fields = { 'abbr', 'kind', 'menu' },
    format = function(entry, item)
        if not low_perf then
            item = require("tailwind-tools.cmp").lspkind_format(entry, item)
        end
        item.menu = menus[entry.source.name]
        return item
    end
}

local mapping = {
    ['<A-k>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
    ['<A-j>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    -- <a-j> are remapped system-wide
    ['<Up>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
    ['<Down>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    --['<A-l>'] = cmp.mapping.confirm({ select = true }), -- no snipped engine configured ... (who uses snippets anyway?)
    ['<A-h>'] = cmp.mapping.abort(),
}

local cmd_mapping = {
    ['<A-k>']  = cmp.mapping(cmp.mapping.select_prev_item(), { 'c' }),
    ['<A-j>']  = cmp.mapping(cmp.mapping.select_next_item(), { 'c' }),
    ['<Up>']   = cmp.mapping(cmp.mapping.select_prev_item(), { 'c' }),
    ['<Down>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'c' }),
    ['<A-h>']  = cmp.mapping(cmp.mapping.abort(), { 'c' }),
}

local snippetKind = cmp.lsp.CompletionItemKind.Snippet

cmp.setup{
    snippet = {
        expand = function(args)
            print('should not pe triggered')
        end
    },
    sources = cmp.config.sources{
        { name = 'nvim_lua', max_item_count = 5 },
        {
            name = 'nvim_lsp',
            max_item_count = 8,
            entry_filter = function(entry) return entry:get_kind() ~= snippetKind end,
        },
        { name = 'buffer', max_item_count = 8 },
    },
    mapping = mapping,
    formatting = format,
}

cmp.setup.cmdline({ '/', '?' }, {
    sources = cmp.config.sources{ { name = 'buffer', max_item_count = 5 } },
    mapping = cmd_mapping,
    formatting = {
        fields = { 'abbr' },
        format = function(_, item)
            return item
        end
    },
})

local group = vim.api.nvim_create_augroup('SetupCommandCMPGroup', { clear = true })
vim.api.nvim_create_autocmd('User', {
    group = group, pattern = 'SetupCommandCMP',
    callback = function(_)
        cmp.setup.buffer({
            sources = {
                {
                    name = 'cmdline',
                    option = { ignore_cmds = { 'Man', '!' } },
                    max_item_count = 3,
                },
                { name = 'nvim_lua', max_item_count = 3 },
                { name = 'buffer', max_item_count = 3 },
            }
        })
    end,
})
