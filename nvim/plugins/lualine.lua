return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local config = {
      options = {
        component_separator = '',
        section_separators = '',
        disabled_filetypes = {
          'NvimTree',
          'NVimTree',
          'alpha',
        },
      },
      sections = {
        lualine_b = {},
        lualine_x = {},
        lualine_y = {},
      },
    }

    require('lualine').setup(config)
  end,
}
