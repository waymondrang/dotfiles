return {
  'nvimtools/none-ls.nvim',
  config = function()
    local null_ls = require 'null-ls'

    null_ls.setup {
      sources = {
        null_ls.builtins.formatting.black, -- use black for python
        null_ls.builtins.formatting.prettier, -- use prettier for js, ts, css, and much more
      },
    }
  end,
}
