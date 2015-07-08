" ====================================================
"   Filetypes
" ====================================================
autocmd Filetype gitcommit setlocal spell textwidth=72
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd Filetype gitcommit setlocal spell textwidth=72
autocmd Filetype markdown setlocal wrap
autocmd Filetype markdown setlocal linebreak
autocmd Filetype markdown setlocal nolist
autocmd BufNewFile,BufRead *.scss set ft=scss.css
autocmd BufNewFile,BufRead *.sass set ft=sass.css
"======================================================================
"     Autosave
"======================================================================
if has('autocmd')"
   autocmd bufwritepost .vimrc source $MYVIMRC
endif
au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
au FileType go nmap <Leader>dt <Plug>(go-def-tab)
au BufNewFile,BufRead *.thor       set filetype=ruby
au BufNewFile,BufRead Guardfile    set filetype=ruby
au BufNewFile,BufRead .pryrc       set filetype=ruby
au BufNewFile,BufRead Vagrantfile  set filetype=ruby
au BufNewFile,BufRead *.pp         set filetype=ruby
au BufNewFile,BufRead *.prawn      set filetype=ruby
au BufNewFile,BufRead Appraisals   set filetype=ruby
au BufNewFile,BufRead .psqlrc      set filetype=sql
au BufNewFile,BufRead *.less       set filetype=css
au BufNewFile,BufRead bash_profile set filetype=sh
au BufNewFile,BufRead *.zsh        set filetype=sh
au BufNewFile,BufRead Capfile      set filetype=ruby
au BufNewFile,BufRead *.hbs,*.ejs  set filetype=html
autocmd BufNewFile,BufRead *.ru                  setfiletype ruby
autocmd BufNewFile,BufRead *.css.erb,*.spriter   setfiletype css
autocmd BufNewFile,BufRead *.mkd,*.md,*.markdown setfiletype markdown
autocmd BufNewFile,BufRead *.json                setfiletype javascript
autocmd BufNewFile,BufRead *.ejs,*.hbs           setfiletype html
autocmd BufNewFile,BufRead *.go                  setfiletype go
autocmd Filetype python setlocal tabstop=4 softtabstop=4 shiftwidth=4
autocmd Filetype make,automake setlocal noexpandtab
autocmd Filetype go setlocal noexpandtab
autocmd Filetype markdown setlocal spell textwidth=80
autocmd Filetype gitcommit,mail setlocal spell textwidth=76 colorcolumn=77
"======= GO Lang ======================================================
au FileType go nmap <Leader>gd <Plug>(go-doc)
au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_fmt_command = "goimports"
let g:go_fmt_fail_silently = 1
let g:go_fmt_autosave = 0
let g:go_play_open_browser = 0
let g:go_bin_path = expand("~/.gotools")
let g:go_bin_path = "/usr/local/bin/go"
"======================================================================
