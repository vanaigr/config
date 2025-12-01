local surround = require("nvim-surround")
local config = require('nvim-surround.config')

local surrounds = {}
for _, data in pairs({
    { '(', ')' },
    { '<', '>' },
    { '[', ']' },
}) do
    local opening = data[1]
    local closing = data[2]

    surrounds[closing] = {
        add = { opening.." ", " "..closing },
        find = function() return config.get_selection({ motion = "a"..closing }) end,
        delete = "^(. ?)().-( ?.)()$",
    }
    surrounds[opening] = {
        add = { opening, closing },
        find = function() return config.get_selection({ motion = "a"..opening }) end,
        delete = "^(.)().-(.)()$",
    }
end

surrounds['b'] = {
    add = { "(", ")" },
    find = function() return config.get_selection({ motion = "ab" }) end,
    delete = "^(. ?)().-( ?.)()$",
}

surrounds['a'] = {
    add = { "<", ">" },
    find = function() return config.get_selection({ motion = "aa" }) end,
    delete = "^(. ?)().-( ?.)()$",
}

surround.setup{
    keymaps = { visual = 's' },
    aliases = {
        ['a'] = { '>' },
        ["b"] = { ")", "}", "]", ">" },
        ['s'] = { ')', '}', ']', '>', "'", '"', '`' }, -- required to be closing as they alse delete spaces (current == config, but put in case it changes)
    },
    surrounds = surrounds,
    move_cursor = false,
}
