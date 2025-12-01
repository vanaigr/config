local vim = vim

local _ = [==[
vim.keymap.set('n', 's', function ()
    require('leap')
    require('leap-by-word').leap() --.leap { target_windows = { vim.api.nvim_get_current_win() } }
end)

local function setColors()
  vim.api.nvim_set_hl(0, 'Cursor', { bg = 'white', fg = 'black' })
  vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
end

local group = vim.api.nvim_create_augroup('LeapHighlighting', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = setColors,
  group = group,
})

setColors()

if true then return end
]==]


--local easyword = require('easyword')
--easyword.apply_default_highlight()
--
--vim.keymap.set({ 'n' }, 's', function() easyword.jump{ recover_key = 's' } end)
--vim.keymap.set({ 'x', 'o' }, 'x', function() easyword.jump{ recover_key = 'x' } end)
--
--local group = vim.api.nvim_create_augroup('EasywordHighlighting', { clear = true })
--vim.api.nvim_create_autocmd('ColorScheme', {
--    callback = function() easyword.apply_default_highlight() end,
--    pattern = '*', group = group,
--})
--
--if true then return end

local isSetup = false
local norm
local target_display

local labels = { -- qwerty
    's', 'j', 'k', 'd', 'l', 'f', 'c', 'n', 'i', 'e', 'w', 'r', 'o',
    'm', 'u', 'v', 'a', 'q', 'x', 'z',
}

--local left = vim.fn.split([==[123456!@#$%^qwertQWERTasdfgASDFGzxcvbZXCVB`~]==], '\\zs')
--local right = vim.fn.split([==[7890-=&*()_+yuiop[]YUIOP{}hjkl;'HJKL:"nm,./NM<>?\|]==], '\\zs')
local left = vim.fn.split([==[12345!@#$%qwertQWERTasdfgASDFGzxcvZXCV`~]==], '\\zs')
local right = vim.fn.split([==[7890-=&*()_+uiop[]UIOP{}hjkl;'HJKL:"nm,./NM<>?\|]==], '\\zs')
local key_hands = {}
-- for _, key in ipairs(left) do key_hands[key] = 0 end
-- for _, key in ipairs(right) do key_hands[key] = 1 end

local function setup(easyword)
    local normList = {}
    local charRegex = {}

    normList['\t'] = ' '
    normList['\n'] = ' '
    normList['\r'] = ' '
    for i = 32, 64 do
        local ch = string.char(i)
        charRegex[ch] = vim.regex('^[[='..ch..'=]]$\\c')
        normList[ch] = ch
    end
    for i = 1, 26 do -- A-Z => a-z
        normList[string.char(64 + i)] = string.char(96 + i)
    end
    for i = 91, 126 do
        local ch = string.char(i)
        charRegex[ch] = vim.regex('^[[='..ch..'=]]$\\c')
        normList[ch] = ch
    end

    -- note: langmap doesn't work on getcharstr()
    local qwerty    = vim.fn.split([==[qwertyuiop[]asdfghjkl;'zxcvbnm,.`]==], '\\zs')
    local cyrillic  = vim.fn.split([==[йцукенгшщзхъфывапролджэячсмитьбюё]==], '\\zs')
    local cyrillicU = vim.fn.split([==[ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮЁ]==], '\\zs')

    -- no regex since vim doesn't support equivalence classes for cyrillic
    for i = 1, #cyrillic do
        normList[cyrillic [i]] = qwerty[i]
        normList[cyrillicU[i]] = qwerty[i]
    end
    normList['№'] = '#'

    norm = function(char)
        local v = normList[char]
        if v then return v end

        for k, pattern in pairs(charRegex) do
            if pattern:match_str(char) then
                normList[char] = k
                return k
            end
        end

        return ' '
    end

    local A = string.byte('A', 1)
    local Z = string.byte('Z', 1)
    target_display = function(char)
        if char == '\n' then return ' ' end
        local b = string.byte(char, 1)
        if #char == 1 and b >= A and b <= Z then return char end
        return norm(char)
    end

    easyword.apply_default_highlight()
end

local function jump(recover_key)
  local easyword = require('easyword')
  if not isSetup then
      isSetup = true
      setup(easyword)
  end

  easyword.jump({
    labels = labels,
    char_normalize = norm,
    recover_key = recover_key,
    key_groups = key_hands,
    target_display = target_display,
    cancel_key = {
        [vim.api.nvim_replace_termcodes('<Esc>', true, false, true)] = true,
        [vim.api.nvim_replace_termcodes('<A-i>', true, false, true)] = true,
        [vim.api.nvim_replace_termcodes('<A-e>', true, false, true)] = true,
        [vim.api.nvim_replace_termcodes('<A-q>', true, false, true)] = true,
    },
  })
end

local m = require('mapping')
m.n('s', function() jump('s') end)
m.xo('x', function() jump('x') end)
m.n('\\', function()
    local recover_key = 's'
    local easyword = require('easyword')
    if not isSetup then
        isSetup = true
        setup(easyword)
    end

    easyword.__test({
        labels = labels,
        char_normalize = norm,
        recover_key = recover_key,
        key_groups = key_hands,
        target_display = target_display,
        cancel_key = {
            [vim.api.nvim_replace_termcodes('<Esc>', true, false, true)] = true,
            [vim.api.nvim_replace_termcodes('<A-i>', true, false, true)] = true,
            [vim.api.nvim_replace_termcodes('<A-e>', true, false, true)] = true,
        },
    })
end)

local group = vim.api.nvim_create_augroup('EasywordHighlighting', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = '*',
    callback = function()
        if isSetup then require('easyword').apply_default_highlight() end
    end,
    group = group
})
