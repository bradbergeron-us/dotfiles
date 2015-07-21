" ====================================================
"   Settings
" ====================================================
" ========== CtrlP ==========
let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
set wildignore+=*/tmp/*,*/log/*,*.so,*.swp,*.zip
" ========== EasyMotion ==========
let g:EasyMotion_leader_key = '<leader>e'
" Display targets in uppercase
let g:EasyMotion_use_upper = 1
" Remove x, z, and ; from default key set, set group key priority
let g:EasyMotion_keys = 'ASDHJKLQWERTYUIMNOCVBPGF'
" Overwrite default target colors
hi link EasyMotionTarget Special
hi link EasyMotionShade  Comment
hi link EasyMotionTarget2First Type
hi link EasyMotionTarget2Second Type
" ========== Gist ========== "
let g:gist_clip_command = 'pbcopy'
let g:gist_open_browser_after_post = 1
let g:gist_update_on_write = 2
let g:gist_post_private = 1
" ========== Syntastic ========== "
let g:syntastic_mode_map = { 'mode': 'active',
      \ 'active_filetypes': ['ruby', 'javascript'],
      \ 'passive_filetypes': ['html'] }
"=======DTree |ive ==========="
" The tree buffer makes it easy to drill down through the directories of your
" git repository, but it’s not obvious how you could go up a level to the
" parent directory. Here’s a mapping of .. to the above command, but
" only for buffers containing a git blob or tree
autocmd User fugitive
  \ if fugitive#buffer().type() =~# '^\%(tree\|blob\)$' |
  \   nnoremap <buffer> .. :edit %:h<CR> |
  \ endif
autocmd BufReadPost fugitive://* set bufhidden=delete
"==================== easymotion==============="
" These keys are easier to type than the default set
" We exclude semicolon because it's hard to read and
" i and l are too easy to mistake for each other slowing
" down recognition. The home keys and the immediate keys
" accessible by middle fingers are available 
let g:EasyMotion_keys='asdfjkoweriop'
nmap ,<ESC> ,,w
nmap ,<S-ESC> ,,b
"==================== Multiple Cursors ====="
" Turn off default key mappings
let g:multi_cursor_use_default_mapping=0
" Switch to multicursor mode with ,mc
let g:multi_cursor_start_key=',mc'
" Ctrl-n, Ctrl-p, Ctrl-x, and <Esc> are mapped in the special multicursor
" mode once you've added at least one virtual cursor to the buffer
let g:multi_cursor_next_key='<C-n>'
let g:multi_cursor_prev_key='<C-p>'
let g:multi_cursor_skip_key='<C-x>'
let g:multi_cursor_quit_key='<Esc>'
" ====================================================
"  Bling Airline
" ===================================================
let g:airline_powerline_fonts = 1
set laststatus= 2
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
" tabline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
" tabline
let g:airline#extensions#tabline#enabled = 1

" Rspec Running tests if you need to see full backtrace
" output to debug use ^Z (ctrl+Z) to send Vim to background,
" running the specs in terminal, and using fg to bring Vim 
" back to the foreground
let g:rspec_command = "Dispatch rspec {spec}"
