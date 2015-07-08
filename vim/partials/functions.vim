" ====================================================
"   Functions
" ====================================================
"=============== Tabular====================
" Tabular
inoremap <silent> <Bar> <Bar><Esc>:call <SID>align()<CR>a
function! s:align()
 let p = '^\s*|\s.*\s|\s*$'
    if exists(':Tabularize') && getline('.') =~# '^\s*|' &&
     (getline(line('.')-1) =~# p || getline(line('.')+1) =~# p)
  let column =
     strlen(substitute(getline('.')[0:col('.')],'[^|]','','g'))
     let position =
     strlen(matchstr(getline('.')[0:col('.')],'.*|\s*\zs.*'))
  Tabularize/|/l1
         normal! 0
        call
search(repeat('[^|]*|',column).'\s\{-\}'.repeat('.',position),'ce',line('.'))
        endif
endfunction
" ========== Browser ========== "
" Open link on current line in browser
function! Browser()
  let s:uri = matchstr(getline("."), '[a-z]*:\/\/[^ >,;:]*')
  echo s:uri
  if s:uri != ""
    exec "!open \"" . s:uri . "\""
  else
    echo "No URI found in line."
  endif
endfunction
nnoremap <leader>R :call Browser()<cr>
" ========== Multi-purpose Tab Key ========== "
" Indent if we're at the beginning of a line. Else, do completion.
function! InsertTabWrapper()
  let col = col('.') - 1
  if !col || getline('.')[col - 1] !~ '\k'
    return "\<tab>"
  else
    return "\<c-p>"
  endif
endfunction
inoremap <tab> <c-r>=InsertTabWrapper()<cr>
inoremap <s-tab> <c-n>
" ========== Rename File ========== "
function! RenameFile()
  let old_name = expand('%')
  let new_name = input('New file name: ', expand('%'), 'file')
  if new_name != '' && new_name != old_name
    exec ':saveas ' . new_name
    exec ':silent !rm ' . old_name
    redraw!
  endif
endfunction
nnoremap <leader>rn :call RenameFile()<cr>
set laststatus=2
" Specific Configurations
let g:markdown_fenced_languages = ['css', 'erb=eruby', 'javascript', 'js=javascript', 'json=javascript', 'ruby', 'sass', 'xml', 'html']
