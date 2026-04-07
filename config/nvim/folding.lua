-- Treesitter-based code folding.
-- Uses expression folding backed by Treesitter so that folds follow the
-- actual syntax tree (JSON objects/arrays, function bodies, if-blocks, etc.).

vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- Start with all folds open; press zc / zo / za to collapse / expand / toggle.
vim.o.foldlevelstart = 99

-- Show a concise fold summary instead of the default dashes.
vim.o.foldtext = ''

-- Limit nesting depth so deeply-nested files stay readable.
vim.o.foldnestmax = 10

-- Keep a narrow column to hint at foldable regions.
vim.o.foldcolumn = '1'
