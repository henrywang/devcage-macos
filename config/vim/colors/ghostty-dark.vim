" Ghostty Default StyleDark - vim colorscheme
" Mirrors the Ghostty terminal theme palette exactly.
"
" Terminal palette:
"   0  #1d1f21  1  #bf6b69  2  #b7bd73  3  #e9c880
"   4  #88a1bb  5  #ad95b8  6  #95bdb7  7  #c5c8c6
"   8  #666666  9  #c55757  10 #bcc95f  11 #e1c65e
"  12  #83a5d6  13 #bc99d4  14 #83beb1  15 #eaeaea
"  bg  #292c33  fg #ffffff

set background=dark
highlight clear
if exists('syntax_on') | syntax reset | endif
let g:colors_name = 'ghostty-dark'

" ── Core ────────────────────────────────────────────────────────────────────
hi Normal          ctermfg=15  ctermbg=NONE  guifg=#ffffff  guibg=#292c33
hi NonText         ctermfg=8   ctermbg=NONE  guifg=#666666  guibg=NONE
hi EndOfBuffer     ctermfg=8   ctermbg=NONE  guifg=#666666  guibg=NONE
hi LineNr          ctermfg=8   ctermbg=NONE  guifg=#666666  guibg=NONE
hi CursorLineNr    ctermfg=11  ctermbg=NONE  guifg=#e1c65e  guibg=NONE  cterm=NONE gui=NONE
hi CursorLine      ctermfg=NONE ctermbg=0    guifg=NONE     guibg=#1d1f21 cterm=NONE
hi ColorColumn     ctermbg=0   guibg=#1d1f21
hi SignColumn      ctermfg=8   ctermbg=NONE  guifg=#666666  guibg=NONE

" ── Selection / Search ──────────────────────────────────────────────────────
hi Visual          ctermfg=0   ctermbg=15   guifg=#292c33  guibg=#ffffff
hi Search          ctermfg=0   ctermbg=11   guifg=#1d1f21  guibg=#e1c65e
hi IncSearch       ctermfg=0   ctermbg=3    guifg=#1d1f21  guibg=#e9c880  cterm=NONE gui=NONE

" ── UI Chrome ───────────────────────────────────────────────────────────────
hi StatusLine      ctermfg=15  ctermbg=8    guifg=#ffffff  guibg=#666666  cterm=NONE gui=NONE
hi StatusLineNC    ctermfg=8   ctermbg=0    guifg=#666666  guibg=#1d1f21  cterm=NONE gui=NONE
hi VertSplit       ctermfg=8   ctermbg=NONE guifg=#666666  guibg=NONE     cterm=NONE gui=NONE
hi TabLine         ctermfg=8   ctermbg=0    guifg=#666666  guibg=#1d1f21  cterm=NONE gui=NONE
hi TabLineSel      ctermfg=15  ctermbg=NONE guifg=#ffffff  guibg=NONE     cterm=NONE gui=NONE
hi TabLineFill     ctermbg=0   guibg=#1d1f21 cterm=NONE gui=NONE
hi Pmenu           ctermfg=7   ctermbg=0    guifg=#c5c8c6  guibg=#1d1f21
hi PmenuSel        ctermfg=0   ctermbg=4    guifg=#1d1f21  guibg=#88a1bb
hi PmenuSbar       ctermbg=8   guibg=#666666
hi PmenuThumb      ctermbg=7   guibg=#c5c8c6

" ── Diagnostics ─────────────────────────────────────────────────────────────
hi Error           ctermfg=9   ctermbg=NONE guifg=#c55757  guibg=NONE
hi ErrorMsg        ctermfg=9   ctermbg=NONE guifg=#c55757  guibg=NONE
hi WarningMsg      ctermfg=3   ctermbg=NONE guifg=#e9c880  guibg=NONE
hi Todo            ctermfg=0   ctermbg=3    guifg=#1d1f21  guibg=#e9c880
hi MatchParen      ctermfg=0   ctermbg=11   guifg=#1d1f21  guibg=#e1c65e  cterm=NONE gui=NONE

" ── Spelling ────────────────────────────────────────────────────────────────
hi SpellBad        ctermfg=9   ctermbg=NONE cterm=underline guifg=#c55757  guibg=NONE gui=underline
hi SpellCap        ctermfg=4   ctermbg=NONE cterm=underline guifg=#88a1bb  guibg=NONE gui=underline
hi SpellRare       ctermfg=13  ctermbg=NONE cterm=underline guifg=#bc99d4  guibg=NONE gui=underline
hi SpellLocal      ctermfg=6   ctermbg=NONE cterm=underline guifg=#95bdb7  guibg=NONE gui=underline

" ── Syntax ──────────────────────────────────────────────────────────────────
hi Comment         ctermfg=8   guifg=#666666  cterm=italic gui=italic
hi Constant        ctermfg=3   guifg=#e9c880
hi String          ctermfg=2   guifg=#b7bd73
hi Character       ctermfg=2   guifg=#b7bd73
hi Number          ctermfg=3   guifg=#e9c880
hi Boolean         ctermfg=3   guifg=#e9c880
hi Float           ctermfg=3   guifg=#e9c880
hi Identifier      ctermfg=7   guifg=#c5c8c6  cterm=NONE gui=NONE
hi Function        ctermfg=12  guifg=#83a5d6
hi Statement       ctermfg=5   guifg=#ad95b8  cterm=NONE gui=NONE
hi Keyword         ctermfg=5   guifg=#ad95b8
hi Conditional     ctermfg=5   guifg=#ad95b8
hi Repeat          ctermfg=5   guifg=#ad95b8
hi Operator        ctermfg=6   guifg=#95bdb7
hi PreProc         ctermfg=6   guifg=#95bdb7
hi Include         ctermfg=6   guifg=#95bdb7
hi Type            ctermfg=4   guifg=#88a1bb  cterm=NONE gui=NONE
hi StorageClass    ctermfg=4   guifg=#88a1bb
hi Structure       ctermfg=4   guifg=#88a1bb
hi Special         ctermfg=13  guifg=#bc99d4
hi SpecialChar     ctermfg=13  guifg=#bc99d4
hi Underlined      ctermfg=12  guifg=#83a5d6  cterm=underline gui=underline
hi Ignore          ctermfg=8   guifg=#666666

" ── Diff ────────────────────────────────────────────────────────────────────
hi DiffAdd         ctermfg=2   ctermbg=NONE guifg=#b7bd73  guibg=NONE
hi DiffDelete      ctermfg=1   ctermbg=NONE guifg=#bf6b69  guibg=NONE
hi DiffChange      ctermfg=3   ctermbg=NONE guifg=#e9c880  guibg=NONE
hi DiffText        ctermfg=0   ctermbg=3    guifg=#1d1f21  guibg=#e9c880  cterm=NONE gui=NONE

" ── ALE ─────────────────────────────────────────────────────────────────────
hi ALEError        ctermfg=9   ctermbg=NONE guifg=#c55757  guibg=NONE cterm=underline gui=underline
hi ALEWarning      ctermfg=3   ctermbg=NONE guifg=#e9c880  guibg=NONE cterm=underline gui=underline
hi ALEInfo         ctermfg=4   ctermbg=NONE guifg=#88a1bb  guibg=NONE cterm=underline gui=underline
hi ALEErrorSign    ctermfg=9   ctermbg=NONE guifg=#c55757  guibg=NONE
hi ALEWarningSign  ctermfg=3   ctermbg=NONE guifg=#e9c880  guibg=NONE
hi ALEInfoSign     ctermfg=4   ctermbg=NONE guifg=#88a1bb  guibg=NONE

" ── Git gutter ──────────────────────────────────────────────────────────────
hi GitGutterAdd    ctermfg=2   guifg=#b7bd73
hi GitGutterChange ctermfg=3   guifg=#e9c880
hi GitGutterDelete ctermfg=1   guifg=#bf6b69
