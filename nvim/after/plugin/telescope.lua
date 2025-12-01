local vim = vim

-- and this is multiple hundred lines across several files in Neogit...
---@return string?
local function git_root(path)
    local stdout

    if vim.fn.isdirectory(path) == 0 then
        path = vim.fs.dirname(path)
    end

    local job = vim.fn.jobstart(
        { 'git', 'rev-parse', '--show-toplevel' },
        {
            clear_env = true,
            cwd = path,
            on_stdout = function(_, lines, _) stdout = lines end,
            stdout_buffered = true,
        }
    )

    local status = unpack(vim.fn.jobwait({ job }, 500))
    if status ~= 0 or #stdout < 1 then
        return
    end
    return stdout[1]
end

local search_root_fname = '.search-root'

local function search_root(path, stop)
    local res = vim.fs.find(search_root_fname, {
        upward = true,
        path = path,
        stop = stop,
        type = 'file',
        limit = 1,
    })
    if #res > 0 then
        return res[1]:sub(1, #res[1] - #search_root_fname)
    end
end

---@return string?
local function project_root(dir)
    local git_ok, git_res = pcall(git_root, dir)
    local root_ok, root_res = pcall(search_root, dir, git_ok and git_res or nil)

    git_ok = git_ok and (not not git_res)
    root_ok = root_ok and (not not root_res)


    if root_ok then
        return root_res
    elseif git_ok then
        return git_res
    end
end

local function buffer_dir()
    return vim.fn.expand("%:p:h")
end

local function getProjectDir()
    local root = project_root(vim.fn.expand("%:p"))
    if root and root ~= '' then
        return root
    else
        return buffer_dir()
    end
end

local m = require('mapping')

local builtin
local function setup()
    if builtin then return end
    vim.api.nvim_exec_autocmds('User', { pattern = 'load-telescope' })

    local actions = require('telescope.actions')
    require('telescope').setup{
        defaults = {
            mappings = {
                i = {
                    ['<A-k>'] = actions.move_selection_previous,
                    ['<A-j>'] = actions.move_selection_next,

                    ['<A-l>'] = actions.select_tab,
                    ['<right>'] = actions.select_tab,
                    ['<A-o>'] = actions.select_default,

                    ['<A-i>'] = { '<esc>', type = 'command' },
                    ['<A-q>'] = actions.close,
                },
                n = {
                    ['<A-k>'] = function(...)
                        for i = 1, 10 do
                            actions.move_selection_previous(...)
                        end
                    end,
                    ['<A-j>'] = function(...)
                        for i = 1, 10 do
                            actions.move_selection_next(...)
                        end
                    end,
                    ['<up>'] = function(...)
                        for i = 1, 10 do
                            actions.move_selection_previous(...)
                        end
                    end,
                    ['<down>'] = function(...)
                        for i = 1, 10 do
                            actions.move_selection_next(...)
                        end
                    end,

                    ['<A-o>'] = actions.select_default,

                    ['<esc>'] = { '', type = 'command' },
                    ['<A-q>'] = actions.close,

                    ['<leader>q'] = actions.send_to_qflist + actions.open_qflist,
                },
            }
        },
    }
    builtin = require('telescope.builtin')
end

local slash_num = ('/'):byte(1)
local backslash_num = ('\\'):byte(1)

-- currently (04/2024) a bug in transform_path()
-- that plenary Path doesn't make_relative() if
-- if slashes are different
local function fix_path_display(opts, path) -- expects utf8
    local cwd = opts.cwd
    local last_pos = 0
    for i = 1, math.min(#cwd + 1, #path) do
        local cb = cwd:byte(i) or slash_num
        local pb = path:byte(i)
        if (cb == slash_num or cb == backslash_num)
            and (pb == slash_num or pb == backslash_num) then
            last_pos = i
        elseif cb ~= pb then break end -- don't bother w/ windows case folding
    end
    return path:sub(last_pos + 1)
end

m.n('<leader>ff', function()
  setup()
  builtin.find_files{
    cwd = getProjectDir(),
    path_display = fix_path_display,
    --no_ignore = false,
    --hidden = false,
    results_title = 'project files',
  }
end)
m.n('<leader>Ff', function()
  setup()
  builtin.find_files{
    cwd = buffer_dir(),
    path_display = fix_path_display,
    --no_ignore = false,
    --hidden = false,
    results_title = 'project files',
  }
end)
m.n('<leader>fa', function()
  setup()
  builtin.find_files{
    cwd = getProjectDir(),
    path_display = fix_path_display,
    no_ignore = true,
    hidden = true,
    results_title = 'project files',
  }
end)
m.n('<leader>fo', function()
  setup()
  builtin.find_files{
    cwd = vim.fn.stdpath('config'),
    hidden = false,
    results_title = 'config files',
  }
end)

local function fn(num, dir, desc)
    m.n('<leader>f'..num, function()
      setup()
      builtin.find_files{
        cwd = dir,
        no_ignore = true,
        hidden = true,
        results_title = desc,
      }
    end)
end
fn(1, '~/.config', 'User config files')
fn(2, '~/CCC', 'User CCC')
fn(3, '~/.local/share/nvim/lazy', 'User nvim lazy')

m.n('<leader>fO', function()
  setup()
  builtin.oldfiles{ results_title = 'old files', }
end)
m.n('<leader>fh', function()
  setup()
  builtin.help_tags{ results_title = 'help', }
end)
m.n('<leader>fr', function()
  setup()
  builtin.reloader{ results_title = 'reload', }
end)
m.n('<leader>fw', function()
  setup()
  builtin.lsp_workspace_symbols{ results_title = 'symbols', }
end)

local function getSelectionText()
    setup()
    local p1 = vim.fn.getpos('v')
    local p2 = vim.fn.getpos('.')
    return table.concat(vim.api.nvim_buf_get_text(
        0,
        p1[2] - 1,
        p1[3] - 1,
        p2[2] - 1,
        p2[3] - 1,
        {}
    ), '\n') -- does telescope accept \n ?
end

m.n('<leader>fs', function()
    setup()
    builtin.live_grep{
        cwd = getProjectDir(),
        path_display = fix_path_display,
        results_title = 'grep',
    }
end)
m.x('<leader>fs', function()
    setup()
    builtin.live_grep{
        cwd = getProjectDir(),
        default_text = getSelectionText(),
        path_display = fix_path_display,
        results_title = 'grep',
    }
end)
m.n('<leader>Fs', function()
    setup()
    builtin.live_grep{
        cwd = buffer_dir(),
        path_display = fix_path_display,
        results_title = 'grep',
    }
end)
m.x('<leader>Fs', function()
    setup()
    builtin.live_grep{
        cwd = buffer_dir(),
        default_text = getSelectionText(),
        path_display = fix_path_display,
        results_title = 'grep',
    }
end)

m.n('<leader>fS', function()
    setup()
    builtin.live_grep{
        cwd = getProjectDir(),
        path_display = fix_path_display,
        results_title = 'grep',
        additional_args = { '--hidden', '--ignore-vcs' },
    }
end)
m.x('<leader>fS', function()
    builtin.live_grep{
        cwd = getProjectDir(),
        default_text = getSelectionText(),
        path_display = fix_path_display,
        results_title = 'grep',
        additional_args = { '--hidden', '--ignore-vcs' },
    }
end)

vim.api.nvim_create_user_command('Apt', function()
--m.n('<leader>qq', function()
    local handle = io.popen('apt-cache pkgnames')
    if not handle then
        vim.notify('ERROR: could not run apt-cache', vim.log.levels.ERROR, {})
        return
    end

    local out = handle:read('*a')
    local results = vim.split(out, '\n', { plain = true })

    local finder = require('telescope.finders').new_table{
        results = results,
        entry_maker = function(e)
            return { value = e, display = e, ordinal = e }
        end,
    }
    local opts = {}
    require('telescope.pickers').new(opts, {
        finder = finder,
        prompt_title = 'apt packages',
        sorter = require('telescope.config').values.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr)
            local actions = require('telescope.actions')

            local function select()
                local action_state = require('telescope.actions.state')
                local selection = action_state.get_selected_entry()
                if selection == nil then return end
                vim.fn.setreg('+', selection.value, 'c')
                actions.close(prompt_bufnr)
            end

            actions.select_default:replace(select)
            actions.select_tab:replace(select)

            return true
        end
    }):find()
end, {})

--require('telescope.builtin').find_files{ default_text = {} }
--require('telescope.builtin').find_files{ results_title = {1} }
