" Ghostty Default StyleDark - vim-airline theme
" Mirrors the ghostty-dark vim colorscheme palette.
"
" Palette reference:
"   bg=#292c33  0=#1d1f21  1=#bf6b69  2=#b7bd73  3=#e9c880
"   4=#88a1bb   5=#ad95b8  6=#95bdb7  7=#c5c8c6  8=#666666
"  12=#83a5d6  13=#bc99d4

let g:airline#themes#ghostty_dark#palette = {}

" ── Normal mode ─────────────────────────────────────────────────────────────
" a: dark text on bright blue  b: light on gray  c: light on bg
let s:N1 = ['#1d1f21', '#83a5d6', 0,  12]
let s:N2 = ['#c5c8c6', '#666666', 7,  8 ]
let s:N3 = ['#c5c8c6', '#292c33', 7,  235]
let g:airline#themes#ghostty_dark#palette.normal = airline#themes#generate_color_map(s:N1, s:N2, s:N3)
let g:airline#themes#ghostty_dark#palette.normal_modified = {
      \ 'airline_c': ['#e9c880', '#292c33', 3, 235, ''] }

" ── Insert mode ─────────────────────────────────────────────────────────────
" a: dark text on green
let s:I1 = ['#1d1f21', '#b7bd73', 0, 2]
let s:I2 = ['#c5c8c6', '#666666', 7, 8]
let s:I3 = ['#c5c8c6', '#292c33', 7, 235]
let g:airline#themes#ghostty_dark#palette.insert = airline#themes#generate_color_map(s:I1, s:I2, s:I3)
let g:airline#themes#ghostty_dark#palette.insert_modified = {
      \ 'airline_c': ['#e9c880', '#292c33', 3, 235, ''] }
let g:airline#themes#ghostty_dark#palette.insert_paste = {
      \ 'airline_a': ['#1d1f21', '#e9c880', 0, 3, ''] }

" ── Visual mode ─────────────────────────────────────────────────────────────
" a: dark text on yellow
let s:V1 = ['#1d1f21', '#e9c880', 0, 3]
let s:V2 = ['#c5c8c6', '#666666', 7, 8]
let s:V3 = ['#c5c8c6', '#292c33', 7, 235]
let g:airline#themes#ghostty_dark#palette.visual = airline#themes#generate_color_map(s:V1, s:V2, s:V3)
let g:airline#themes#ghostty_dark#palette.visual_modified = {
      \ 'airline_c': ['#e9c880', '#292c33', 3, 235, ''] }

" ── Replace mode ────────────────────────────────────────────────────────────
" a: dark text on red
let s:R1 = ['#1d1f21', '#bf6b69', 0, 1]
let s:R2 = ['#c5c8c6', '#666666', 7, 8]
let s:R3 = ['#c5c8c6', '#292c33', 7, 235]
let g:airline#themes#ghostty_dark#palette.replace = airline#themes#generate_color_map(s:R1, s:R2, s:R3)
let g:airline#themes#ghostty_dark#palette.replace_modified = {
      \ 'airline_c': ['#e9c880', '#292c33', 3, 235, ''] }

" ── Command mode ────────────────────────────────────────────────────────────
" a: dark text on cyan
let s:C1 = ['#1d1f21', '#95bdb7', 0, 6]
let s:C2 = ['#c5c8c6', '#666666', 7, 8]
let s:C3 = ['#c5c8c6', '#292c33', 7, 235]
let g:airline#themes#ghostty_dark#palette.commandline = airline#themes#generate_color_map(s:C1, s:C2, s:C3)

" ── Terminal mode ───────────────────────────────────────────────────────────
let g:airline#themes#ghostty_dark#palette.terminal = airline#themes#generate_color_map(s:I1, s:I2, s:I3)

" ── Inactive ────────────────────────────────────────────────────────────────
let s:IA = ['#666666', '#1d1f21', 8, 0, '']
let g:airline#themes#ghostty_dark#palette.inactive = airline#themes#generate_color_map(s:IA, s:IA, s:IA)
let g:airline#themes#ghostty_dark#palette.inactive_modified = {
      \ 'airline_c': ['#e9c880', '', 3, '', ''] }

" ── Accents ─────────────────────────────────────────────────────────────────
let g:airline#themes#ghostty_dark#palette.accents = {
      \ 'red': ['#c55757', '', 9, ''] }
