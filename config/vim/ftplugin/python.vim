setlocal tabstop=4                   " insert 4 spaces for a tab
setlocal softtabstop=4               " when hitting <BS>, pretend like a tab is removed, even if spaces
setlocal shiftwidth=4                " to change the number of space characters inserted for indentation
setlocal textwidth=99
setlocal expandtab                   " pressing the <TAB> key will always insert 'softtabstop' amount of space characters
setlocal autoindent                  " copy the indentation from the previous line, when starting a new line
setlocal fileformat=unix

" Check Python files with flake8
let b:ale_linters = ['flake8']
" Fix Python files with autopep8
let b:ale_fixers = ['autopep8']
