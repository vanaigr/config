local vim = vim -- fix lsp warning

local low_perf = _G.my_config.low_perf

vim.diagnostic.config{
    -- show highest diagnostic on the line
    severity_sort = true,
    virtual_text = true,
}
-- there's also a different way, not sure what's the benefit
-- https://neovim.io/doc/user/diagnostic.html

-- see lsp-zero

local m = require('mapping')

local lualine_warned = false
local function lualine()
    local lualine_ok, err = pcall(function()
        require('lualine').refresh()
    end)
    if not lualine_ok and not lualine_warned then
        lualine_warned = true
        vim.notify_once('[MY] Lualine LSP notification error: ' .. vim.inspect(err), vim.log.levels.WARN)
    end
end

local g = vim.api.nvim_create_augroup('LSPGroup', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', {
    group = g,
    callback = function(event)
        local options = { buffer = event.buf }

        m.n('<A-;>a', function() vim.lsp.buf.code_action() end, options)

        -- still going to close after exiting insert mode bc of vim putting cursor
        -- one char to the left and me resetting it back
        m.n('<A-;>h', function() vim.lsp.buf.hover({ close_events = { 'CursorMoved' } }) end, options)
        m.n('<A-;>s', function() vim.lsp.buf.signature_help({ close_events = { 'CursorMoved' } }) end, options)

        m.n('<A-;>v', function() vim.lsp.buf.rename() end, options)
        m.n('<A-;>r', function()
            --require('omnisharp_extended').lsp_references()
            vim.lsp.buf.references()
        end, options)
        m.n('<A-;>d', function() vim.diagnostic.open_float() end, options)

        m.i('<A-;>h', function() vim.lsp.buf.hover() end, options)
        m.i('<A-;>s', function() vim.lsp.buf.signature_help() end, options)
        m.i('<A-;>d', function() vim.diagnostic.open_float() end, options)

        m.n('[d', function()
            vim.diagnostic.jump({
                count = -1,
                float = true,
                severity = vim.diagnostic.severity.E,
            })
        end, options)
        m.n(']d', function()
            vim.diagnostic.jump({
                count = 1,
                float = true,
                severity = vim.diagnostic.severity.E,
            })
        end, options)

        m.n('gd', function()
            vim.cmd('tab split')
            -- require('omnisharp_extended').lsp_definition()
            vim.lsp.buf.definition()
        end, options)
        m.n('gD', function() vim.cmd('tab split'); vim.lsp.buf.declaration() end, options)

        m.n('gi', function()
            vim.cmd('tab split')
            --require('omnisharp_extended').lsp_implementation()
            vim.lsp.buf.implementation()
        end, options)

        lualine()
    end
})

vim.api.nvim_create_autocmd('LspDetach', {
    group = g,
    callback = function(event)
        lualine()
    end
})

local ok, capabilities = pcall(function()
    -- This is not enough for some servers (lua_ls). So also check for them on cmp side
    return require('cmp_nvim_lsp').default_capabilities{ snippet_support = false }
end)
if not ok then capabilities = nil end

-- use mason path for lsps
local mason_path = vim.fn.stdpath('data') .. '/mason/bin'

-- Do this manually since Mason is slow
local lspconfig = require('lspconfig')

local function conf(name, f, skip)
    if skip then
        --vim.notify('SKIPPING: ' .. f, vim.log.levels.WARN, {})
        return
    end
    local ok, res = pcall(f)
    if not ok then
        vim.notify(name..' LSP ERROR: '..res, vim.log.levels.WARN, {})
    end
end

conf('lua', function()
    vim.lsp.config('lua_ls', {
        cmd = { mason_path .. '/lua-language-server' },
        capabilities = capabilities,
        settings = {
            Lua = {
                workspace = {
                    library = vim.api.nvim_get_runtime_file('', true),
                    checkThirdParty = false, -- LoOk At Me I aM aNnoYiNg Af!!!!!!11!!!1!1!
                },
            }
        }
    })
end)
conf('clang', function()
    vim.lsp.config('clangd', {
        cmd = { mason_path .. '/clangd' },
        capabilities = capabilities,
    })
end)

--require("lspconfig.configs").vtsls = require("vtsls").lspconfig
conf('typescript', function()
    require("vtsls")
    vim.lsp.enable('vtsls')
    vim.lsp.config('vtsls', {
        capabilities = capabilities,
    })
end)

--[[
conf('typescript-tools', function()
    local api = require("typescript-tools.api")

    require("typescript-tools").setup{
        settings = {
            separate_diagnostic_server = false,
            publish_diagnostic_on = "insert_leave",
            expose_as_code_action = { "add_missing_imports" },
            tsserver_max_memory = "auto",
            tsserver_locale = "en",
            complete_function_calls = false,
            --include_completions_with_insert_text = true,
            -- perf issue
            -- code_lens = "all",
            jsx_close_tag = {
                enable = false,
                filetypes = { "javascriptreact", "typescriptreact" },
            },
        },
        handlers = {
            ["textDocument/publishDiagnostics"] = api.filter_diagnostics{
                7016,
                80001,
                6133,
                --80006,
            },
        },
    }
end)
]]

-- NEVER complete : . Especially if you are trash and
-- complete it even when it already exists
-- conf('css', function() lspconfig.cssls.setup{} end)

conf('rust', function()
    vim.lsp.config('rust_analyzer', {
        cmd = { mason_path .. '/rust-analyzer' },
        capabilities = capabilities,
    })
end)

conf('cmake', function()
    vim.lsp.config('cmake', {
        cmd = { mason_path .. '/cmake-language-server' },
        capabilities = capabilities,
    })
end)

conf('tailwind', function()
    vim.lsp.config('tailwindcss', {
        cmd = { mason_path .. '/tailwindcss-language-server' },
        capabilities = capabilities,
    })
end, low_perf)

conf('csharp', function()
    -- https://github.com/OmniSharp/omnisharp-roslyn/issues/2577
    vim.lsp.config('omnisharp', {
        cmd = { mason_path .. '/omnisharp' },
        capabilities = capabilities,
    })
end)
