local function show_macro_recording()
  local recording_register = vim.fn.reg_recording()
  if recording_register == '' then
    return ''
  else
    return '@' .. recording_register
  end
end

vim.opt.showcmd = true
vim.opt.showcmdloc = 'statusline'

return {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-tree/nvim-web-devicons' },

  opts = {
    options = {
      icons_enabled = true,
      theme = 'auto',
      component_separators = { left = '', right = '' },
      section_separators = { left = '', right = '' },
      disabled_filetypes = {
        statusline = {},
        winbar = { 'NeogitStatus', 'DiffviewFiles', 'DiffviewFileHistory' },
      },
      ignore_focus = {},
      always_divide_middle = true,
      -- globalstatus = true,
      refresh = {
        statusline = 250,
        tabline = 1000,
        winbar = 1000,
      },
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch', 'diff' },
      lualine_c = { 'diagnostics' },
      lualine_x = { 'searchcount', { 'macro-recording', fmt = show_macro_recording }, '%S' },
      lualine_y = { { 'filename', path = 1 }, 'filetype' },
      lualine_z = { 'location', 'progress' },
    },
    -- inactive_sections = {},
    winbar = {
      lualine_c = { 'filename' },
    },
    inactive_winbar = {
      lualine_c = { 'filename' },
    },
    extensions = {},
  },
}
