local vim = vim -- fix lsp warning

local map = {}

local stats_path = vim.fn.stdpath('data') .. '/map_stats/'
local stats_fp = stats_path .. 'stats.txt'

map.__stats = {}

local alt_s  = [=[ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯфисвуапршолдьтщзйкыегмцчня]=]
local main_s = [=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]=]

vim.opt.langmap = alt_s .. ';' .. main_s

local key_map = {}

local alt = vim.fn.split(alt_s, '\\zs')
local main = vim.fn.split(main_s, '\\zs')
for i, main_key in ipairs(main) do
    key_map[main_key] = alt[i]
end

local function write(force)
    if true then return end

    -- technically there can be new keymaps that weren't used
    -- which wouln't be written
    if not force and not map.__added then return end

    local prev_stats

    local f = io.open(stats_fp, 'r+b')
    if f then
        local prev_stats_s = f:read('*a')
        if prev_stats_s ~= '' then
            local ok
            ok, prev_stats = pcall(function()
                return vim.json.decode(prev_stats_s)
            end)
            if not ok then
                -- who is going to see this??
                print("Warning: stats file is corrupded:", prev_stats)
                local msg = prev_stats
                prev_stats = nil
                pcall(function()
                    local bkp_fp = stats_path .. 'bkp' .. vim.loop.hrtime() .. '.txt'
                    local bkp_fd = io.open(bkp_fp, 'w+b')
                    bkp_fd:write(prev_stats_s)
                    bkp_fd:write('\n')
                    bkp_fd:write(msg)
                    bkp_fd:close()
                end)
            end
        end
    else
        print("Create the file yourself!")
        return
    end

    if prev_stats then
        for k, dv in pairs(map.__stats) do
            local v = prev_stats[k]
            prev_stats[k] = v and v + dv or dv
        end
    else
        prev_stats = map.__stats
    end
    map.__stats = {}

    f:seek("set", 0)
    f:write(vim.json.encode(prev_stats))
    f:close()
end

pcall(function()
    local group = vim.api.nvim_create_augroup('KeymapsStats', { clear = true })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        pattern = '*', group = group, callback = function() write() end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = 'WriteKeymapStats',
        group = group,
        callback = function() write(true) end ,
    })

    local period = 5 * 60 * 1000

    if KeymapsTimer then KeymapsTimer:stop() end
    KeymapsTimer = vim.loop.new_timer()
    KeymapsTimer:start(period, period, vim.schedule_wrap(function()
        local ok, msg = pcall(function() write() end)
        if not ok then
            KeymapsTimer:stop()
            vim.notify('keymap stats error: '..msg, vim.log.levels.ERROR, {})
        end
    end))
end)

function map.__profile(key)
    map.__added = true
    local s = map.__stats[key]
    if s then map.__stats[key] = s + 1
    else map.__stats[key] = 1 end
end

function map.__start_profile(key)
    if not map.__stats[key] then map.__stats[key] = 0 end
end

local function create_alt_keys(keys)
    local changed = false
    local alt_keys = {}

    local skip = false
    local i = 1
    while i <= #keys do
        local key = keys[i]

        if not skip and key == '<' then
            table.insert(alt_keys, key)
            i = i + 1

            key = keys[i]
            table.insert(alt_keys, key)
            i = i + 1

            if not (key == 'A' or key == 'C' or key == 'D'
                or key == 'M' or key == 'S' or key == 'T')
            then
                skip = true
                goto next
            end

            key = keys[i]
            table.insert(alt_keys, key)
            i = i + 1

            if key ~= '-' then
                skip = true
                goto next
            end

            key = keys[i]
            i = i + 1

            local alt_key = key_map[key]
            if not alt_key then
                table.insert(alt_keys, key)
                skip = true
                goto next
            end

            local key2 = keys[i]
            i = i + 1
            if key2 ~= '>'  then
                table.insert(alt_keys, key)
                table.insert(alt_keys, key2)
                skip = true
                goto next
            end

            changed = true
            table.insert(alt_keys, alt_key)
            table.insert(alt_keys, key2)
            goto next
        elseif skip and key == '>' then
            skip = false
        elseif not skip then
            local alt_key = key_map[key]
            if alt_key then
                changed = true
                i = i + 1
                table.insert(alt_keys, alt_key)
                goto next
            end
        end

        table.insert(alt_keys, key)
        i = i + 1
        ::next::
    end

    if changed then
        return table.concat(alt_keys, '')
    else
        return nil
    end
end

local function double_map(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, opts)
    local alt_keys = create_alt_keys(vim.fn.split(lhs, '\\zs'))
    if alt_keys then vim.keymap.set(mode, alt_keys, rhs, opts) end
end

function map.__qnoremap(mode, lhs, rhs, opts)
    -- I am not sure what exactly silend does, but it breaks 'c'
    -- mappings rendering: https://github.com/vim/vim/issues/6832
    local options = {
        noremap = true,
        desc = debug.traceback()
    } -- , silent = true
    if opts then options = vim.tbl_extend('keep', opts, options) end


    if type(rhs) == 'string' and options.expr then
        local mode_s = mode
        if type(mode_s) == 'table' then mode_s = vim.inspect(mode_s) end

        --print('Warning: not recordable keymap ' .. mode_s .. '-' .. lhs)
        double_map(mode, lhs, rhs, opts)
        return
    end

    if type(mode) == 'string' then
        local key = mode .. '-' .. lhs
        map.__start_profile(key)
        if type(rhs) == 'string' then
            options.expr = true
            double_map(mode, lhs, function()
                map.__profile(key)
                return rhs
            end, options)
        else
            double_map(mode, lhs, function()
                map.__profile(key)
                return rhs()
            end, options)
        end
    else
        for _, m in ipairs(mode) do
            map.__start_profile(m .. '-' .. lhs)
        end
        if type(rhs) == 'string' then
            options.expr = true
            double_map(mode, lhs, function()
                map.__profile(vim.fn.mode() .. '-' .. lhs)
                return rhs
            end, options)
        else
            double_map(mode, lhs, function()
                map.__profile(vim.fn.mode() .. '-' .. lhs)
                return rhs()
            end, options)
        end
    end
end


function map.qnoremap(mode, lhs, rhs, opts)
    local ok, msg = pcall(map.__qnoremap, mode, lhs, rhs, opts)
    if not ok then
        local mode_s = mode
        if type(mode_s) == 'table' then mode_s = vim.inspect(mode_s) end
        vim.notify(
            'Error creating mapping `'..mode_s..'-'..lhs..'`: '..msg,
            vim.log.levels.ERROR, {}
        )
    end
end

setmetatable(map, {
    __index = function(tab, key)
        local modes = vim.split(key, '')
        local func = function(...) map.qnoremap(modes, ...) end
        rawset(tab, key, func)
        return func
    end
})

return map
