local m = require('mapping')
require('triptych').setup{
    options = {
      show_hidden = true,
      file_icons = {
          enabled = true,
          directory_icon = '📁',
          fallback_file_icon = '📄',
      },
    },
    git_signs = {
        enabled = false,
    },
    diagnostic_signs = {
        enabled = false,
    }
}
m.n('<leader>e', '<cmd>Triptych<cr>')
m.n('<leader>te', '<cmd>tab split<cr><cmd>Triptych<cr>')
