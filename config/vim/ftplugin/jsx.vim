setlocal tabstop=2                   " insert 2 spaces for a tab
setlocal softtabstop=2               " when hitting <BS>, pretend like a tab is removed, even if spaces
setlocal shiftwidth=2                " to change the number of space characters inserted for indentation
setlocal expandtab                   " pressing the <TAB> key will always insert 'softtabstop' amount of space characters
setlocal autoindent                  " copy the indentation from the previous line, when starting a new line
setlocal fileformat=unix

let b:ale_linter_aliases = ['css', 'javascript']
let b:ale_linters = ['stylelint', 'eslint']
