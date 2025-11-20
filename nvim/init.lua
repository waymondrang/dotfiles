-- shoutout benji trimmmm
vim.o.number = true

vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.softtabstop = 4

vim.o.ignorecase = true

vim.o.termguicolors = true

vim.opt.fillchars = { eob = ' ' }

-- do not show "--visual" or "--insert--"
vim.o.showmode = false

-- virtual text
vim.diagnostic.config {
  virtual_text = false,
  underline = false,
  signs = false,
}

-- toggle virtual text
vim.api.nvim_create_user_command('DiagnosticToggle', function()
  local config = vim.diagnostic.config
  local vt = config().virtual_text

  config {
    virtual_text = not vt,
    underline = not vt,
    signs = not vt,
  }
end, { desc = 'toggle diagnostic' })

-- set leader key
vim.keymap.set('n', '<Space>', '<Nop>', { silent = true, remap = false })
vim.g.mapleader = ' '

-- leader key combos
vim.api.nvim_set_keymap('n', '<Leader>l', ':Lazy<cr>', { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>h', ':NvimTreeToggle<cr>', { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>m', ':Mason<cr>', { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>t', ':Trouble diagnostics toggle<cr>', { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>d', ':DiagnosticToggle<cr>', { silent = true, noremap = true })

-- telescope key combos
vim.api.nvim_set_keymap('n', '<Leader>f', ':Telescope find_files<cr>', { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>b', ':Telescope buffers<cr>', { silent = true, noremap = true })

-- zen mode
local in_zen_mode = false

function ToggleZenMode()
  if in_zen_mode then
    vim.opt.number = true
    -- vim.opt.relativenumber = true
    require('lualine').hide { unhide = true }
    in_zen_mode = false
  else
    vim.opt.number = false
    -- vim.opt.relativenumber = false
    require('lualine').hide { unhide = false }
    in_zen_mode = true
  end
end

vim.keymap.set('n', '<Leader>z', ToggleZenMode, { desc = 'toggle zen mode' })

-- format keybind
vim.keymap.set('n', '<A-S-f>', function()
  vim.lsp.buf.format { async = true }
end, { desc = 'Format buffer with language server protocol' })

-- sync neovim clipboard with os clipboard
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

-- use terminal bg
-- vim.cmd [[colorscheme catppuccin-mocha]]

require 'config.lazy'

vim.cmd.colorscheme 'catppuccin'
-- vim.cmd [[hi Normal ctermbg=NONE guibg=NONE]]
