local vim = vim -- fix lsp warning

vim.opt.cursorline = true

local grn = '#8bc798'
local pnk = '#ff76b5'

require('rose-pine').setup{
	variant = 'main',

    styles = {
        bold = false,
        italic = false,
        transparency = false,
    },

    enable = {
        terminal = false,
        legacy_highlights = false,
        migrations = false, -- Handle deprecated options automatically
    },

    highlight_groups = {
        --CursorLine = { bg = 'foam', blend = 10 },
        CursorLine = { bg = 'highlight_low' },
        LineNr = { fg = 'highlight_mid' },
        --Visual = { reverse = true, standout = true, bold = true },

        YankHighlight = { bg = 'pine', fg="#20202e", blend = 80 },
        ClipYankHighlight = { bg = 'love', fg="#20202e", blend = 80 },
        RegYankHighlight = { bg = 'iris', fg="#20202e", blend = 80 },

        Pmenu = { bg = 'overlay' },
        PmenuSel = { reverse = true },

        -- ['Normal'] = { bg = '#151027' },
        ['@parameter'] = { fg = 'iris' }, -- why was this removed?
        -- Use :Inspect<cr> with cursor on stuff under question
        ['@lsp.mod.global'] = { fg = pnk },
        ['@lsp.typemod.variable.globalScope'] = { fg = pnk },
        ['@lsp.typemod.variable.fileScope'] = { fg = grn },
        -- #f6c177
        ['@constant.builtin'] = { fg = '#f6c0a7' },
        ['DiagnosticUnnecessary'] = { fg = '#a99595' },

        ['@character.printf'] = { fg = 'foam' },
    }
}

vim.cmd('colorscheme rose-pine')
