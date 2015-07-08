" ====================================================
"   Colors
" ====================================================

if (&t_Co > 2 || has("gui_running")) && !exists("syntax_on")
  syntax on
endif

set t_Co=256

set background=dark
colorscheme gotham

hi! LineNR guibg=NONE ctermbg=NONE
hi FoldColumn ctermbg=NONE
hi SignColumn ctermbg=NONE
