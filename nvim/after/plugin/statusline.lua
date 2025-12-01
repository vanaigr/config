local p = require('rose-pine.palette')

local colors = {
  textLight = p.text,
  textDark = p.base,
  normalBg   = p.foam,
  insertBg  = p.gold,
  visualBg = p.iris,
  replaceBg   = p.pine,
  commandBg   = p.rose,
  background  = p.highlight_low,
  background2  = p.overlay,
}

local function active_lsps()
    local result = ''
    local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
    for _, client in pairs(clients) do
        result = (result ~= '' and (result .. ' | ') or result) .. client.name
    end
    return result
end

local colorScheme = {
  normal = {
    a = { fg = colors.textDark, bg = colors.normalBg, gui = 'bold' },
    b = { fg = colors.textLight, bg = colors.background },
    c = { fg = colors.textLight, bg = colors.background2 },
  },
  insert = {
    a = { fg = colors.textDark, bg = colors.insertBg, gui = 'bold' },
    b = { fg = colors.textLight, bg = colors.background },
  },
  visual = {
    a = { fg = colors.textDark, bg = colors.visualBg, gui = 'bold' },
    b = { fg = colors.textLight, bg = colors.background },
  },
  replace = {
    a = { fg = colors.textDark, bg = colors.replaceBg, gui = 'bold' },
    b = { fg = colors.textLight, bg = colors.background },
  },
  inactive = {
    a = { fg = colors.textLight, bg = colors.textDark, gui = 'bold' },
    b = { fg = colors.textLight, bg = colors.textDark },
    c = { fg = colors.textLight, bg = colors.background2 },
  },
  command = {
    a = { fg = colors.textDark, bg = colors.commandBg, gui = 'bold' },
    b = { fg = colors.textLight, bg = colors.background },
    c = { fg = colors.textLight, bg = colors.background2 },
  },
}

require('lualine').setup{
  options = {
    icons_enabled = false,
    theme = colorScheme,
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    globalstatus = true,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { { 'filename', path = 2 }, 'diff' },
    lualine_c = { { 'diagnostics', symbols = { error = 'E', warn = 'W', info = 'I', hint = 'H' } } },
    lualine_x = {},
    lualine_y = { active_lsps, 'searchcount' },
    lualine_z = { 'location' }
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  },
}
