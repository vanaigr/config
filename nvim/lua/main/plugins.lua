local vim = vim -- fix lsp warning

local low_perf = _G.my_config.low_perf

require('lazy').setup({
    -- my fixes
    { 'vanaigr/targets.vim' },
    {
        'vanaigr/telescope.nvim',
        branch='help-tags-perf-11',
        dependencies = { 'nvim-lua/plenary.nvim', },
        event = 'User load-telescope',
    },
    { 'vanaigr/incselection.nvim' },

    { 'vanaigr/motion.nvim' },
    { 'vanaigr/mark-signs.nvim' },
    { 'vanaigr/easyword.nvim' },
    { 'brenoprata10/nvim-highlight-colors' },
    { 'rose-pine/neovim', name = 'rose-pine' },
    {
        'Wansmer/treesj',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        event = 'User load-treesj'
    },
    { 'jake-stewart/multicursor.nvim' },
    { 'tpope/vim-fugitive', command = 'Git', event = 'User load-fugitive' },
    { 'kylechui/nvim-surround' },
    { 'mbbill/undotree' },
    { 'numToStr/Comment.nvim', event = 'User load-comment' },
    { 'nvim-treesitter/nvim-treesitter', branch = 'main' },
    { 'bkad/CamelCaseMotion' },
    { 'dstein64/nvim-scrollview' },
    { 'nvim-lualine/lualine.nvim' },
    { 'echasnovski/mini.nvim' },
    { 'chrisgrieser/nvim-spider' },
    { 'simonmclean/triptych.nvim' },
    { 'FabijanZulj/blame.nvim' },
    { 'vanaigr/nvim-cmp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-cmdline' },
    { 'hrsh7th/cmp-nvim-lua' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'neovim/nvim-lspconfig' },
    { 'Hoffs/omnisharp-extended-lsp.nvim' },

    {
        'nacro90/numb.nvim',
        config = function()
            require('numb').setup()
        end,
    },

    --[[
        'jackMort/ChatGPT.nvim' - very buggy. <C-W> just crashes it, and all other floating windows die.
        If I close the window while it is doing it's thing, also dies.
        Reinventing the wheel (poorly) with floating windows. Why do I need tab if there's <C-w>?
        Why do I need to close it when I want to look at my code. And why are there these huge margins,
        (given that you can't access the window underneath).
        Would've been better to just open a new tab.
    ]]

    { 'https://github.com/vanaigr/gp.nvim.git' },

    {
        -- also buggy
        'HiPhish/rainbow-delimiters.nvim',
        enabled = not low_perf,
    },
    {
        "luckasRanarison/tailwind-tools.nvim",
        name = "tailwind-tools",
        build = ":UpdateRemotePlugins",
        enabled = not low_perf,
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            -- optional
            "nvim-telescope/telescope.nvim",
            "neovim/nvim-lspconfig",
        },
    },
    { 'yioneko/nvim-vtsls' },
    --[[{
        "pmizio/typescript-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
        opts = {},
    },]]
    { -- super slow (half the startup time)
        'williamboman/mason.nvim',
        cmd = {
            'Mason', 'MasonUpdate', 'MasonInstall',
            'MasonUninstall', 'MasonLog',
        },
        config = function() require('mason').setup{} end,
    },
}, {
    install = {
        missing = false,
        colorscheme = { "habamax" },
    },
    performance = {
        rtp = {
            disabled_plugins = {
                'gzip', 'matchit', 'matchparen',
                'tarPlugin', 'tohtml', 'tutor',
                'zipPlugin',
            },
        },
    },
    change_detection = { enabled = false },
})
