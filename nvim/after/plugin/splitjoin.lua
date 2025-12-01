local vim = vim

local load = true
local function setup(fLoad)
  if load then
    load = fLoad

    vim.api.nvim_exec_autocmds('User', { pattern = 'load-treesj' })

    local p = require('treesj')
    p.setup{
      use_default_keymaps = false,
      check_syntax_error = false,
      max_join_length = 5000, -- if called erroneously
      cursor_behavior = 'hold',
      notify = true,
      dot_repeat = false,
    }
    return p
  else
    load = fLoad
    return require('treesj')
  end
end

local m = require('mapping')

m.n('<leader>s', function()
  setup().toggle()
end)

m.n('<leader>S', function()
  setup().split()
end)
