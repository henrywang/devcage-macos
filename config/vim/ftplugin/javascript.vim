" ref http://vim.wikia.com/wiki/Indenting_source_code
setlocal tabstop=2                   " insert 4 spaces for a tab
setlocal softtabstop=2               " when hitting <BS>, pretend like a tab is removed, even if spaces
setlocal shiftwidth=2                " to change the number of space characters inserted for indentation
setlocal shiftwidth=2                " number of spaces to use for autoindenting

" Enable ESLint only for JavaScript.
let b:ale_linters = ['eslint']
" Fix files with ESLint.
let b:ale_fixers = ['eslint']
