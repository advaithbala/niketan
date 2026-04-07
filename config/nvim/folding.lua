-- Treesitter-based code folding.
-- Uses expression folding backed by Treesitter so that folds follow the
-- actual syntax tree (JSON objects/arrays, function bodies, if-blocks, etc.).
-- Parsers are pre-compiled at bootstrap time (see install_nvim_parsers in
-- lib/neovim.sh).  This file only needs to set fold options per buffer.

vim.o.foldlevelstart = 99
vim.o.foldnestmax = 10
vim.o.foldcolumn = '1'
vim.o.foldtext = ''

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('niketan-folding', { clear = true }),
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not lang then return end

    local has_parser = pcall(vim.treesitter.language.add, lang)
    if has_parser then
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end
  end,
})
