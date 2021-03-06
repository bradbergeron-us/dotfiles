" ====================================================
"   Mappings
" ====================================================
" ========== General ========== "
" Better defaults
nnoremap ; :
nnoremap : ;
inoremap jk <esc>
" Arrow Keys for window sizing
noremap <up>    <c-w>+
noremap <down>  <c-w>-
noremap <left>  1<c-w>>
noremap <right> 1<c-w><
" Window navigation
nnoremap <c-h> <c-w>h
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-l> <c-w>l
" Move visual block
vnoremap J :m '>+1<cr>gv=gv
vnoremap K :m '<-1<ct>gv=gv
" Tabs
noremap <c-t> <esc>:tabnew<cr>
" Move to the previous tab
nnoremap H gT
" Move to the next tab
nnoremap L gt
" Save file
noremap <c-s> <esc>:w<cr>
inoremap <c-s> <esc>:w<cr>
" Directory of Current File
cnoremap %% <c-r>=expand('%:h').'/'<cr>
" Jump out of parenthesis, brackets, etc.
inoremap <c-e> <c-o>A
" Insert newlines
nnoremap J O<esc>Dj
nnoremap K o<esc>Dk
" Copy to end of line
nnoremap Y y$

" ===== Non-Alphanumeric =====
" Switch between buffers
nnoremap ,, <c-^>
" Shell command
nnoremap ! :!<space>
" == A == "
" Search with ag
nnoremap <leader>aa :Ag! ''<left>
nnoremap <leader>ac :Ag! --coffee ''<left>
nnoremap <leader>ah :Ag! --haml ''<left>
nnoremap <leader>as :Ag! --sass ''<left>
" Search for word under cursor with ag
nnoremap <leader>AA :Ag! <c-r><c-w><cr>
" == B == "
" bundle install
nnoremap <leader>B :!bundle install<cr>
" Open CtrlP buffer search
nnoremap <leader>b :CtrlPBuffer<cr>
" == C == "jhhj
" ctag commands
map <leader>t :call ExecuteInShell("clear; ".TestCmd())<CR>
map <leader>T :call ExecuteInShell("clear; ".TestCmd().":".line("."))<CR>
map <leader>r :call ExecuteInShell("clear; ".AllTestsCmd())<CR>
map <leader>M :call ExecuteInShell("clear; make")<CR>
map <leader>ct :silent !ctags -R .<CR>:redraw!<CR>
" Copy whole file, store in register
nnoremap <leader>co ggVG"*y

" Tab Settings
noremap 1 :tabnext 1<CR>
noremap 2 :tabnext 2<CR>
noremap 3 :tabnext 3<CR>
noremap 4 :tabnext 4<CR>
noremap 5 :tabnext 5<CR>
noremap 6 :tabnext 6<CR>
noremap 7 :tabnext 7<CR>
noremap 8 :tabnext 8<CR>
noremap 9 :tablast<CR>
" == D == "
" Delete all text in file
nnoremap <leader>do ggdG
" == E == "
" ...
" == F == "
" Standard CtrlP window
nnoremap <leader>f :CtrlP<cr>
" Clear CtrlP cache
nnoremap <silent> <leader>F :ClearCtrlPCache<cr>
" == G == "
"Add gitsh shell functionality
map <leader>g :silent !gitsh<CR>:redraw!<CR>
" g Command
nnoremap <leader>G :g/
" :Gbrowse
nnoremap <leader>gb :Gbrowse<cr>
" :Gstatus
nnoremap <leader>gs :Gstatus<CR><C-W>15+
" Sort block
nnoremap <silent> <leader>gs (jV)k :sort<cr>
" == H == "
" Horizontal split
nnoremap <leader>h <c-w>s<c-w>j
" == I == "
" Auto-indent entire file
nnoremap <leader>I mmgg=G`m
" == J == "
" EasyMotion
map <leader>j <plug>(easymotion-bd-w)
" Jasmine
nnoremap <leader>J :!bundle exec rake jasmine:ci<cr>
" == K == "

map<leader>ka f(cs)(
map<leader>kr f(cs()
" == L == "
" Clear the search buffer when hitting return
nnoremap <silent> <leader>l :nohlsearch<cr>
" == M == "
" ...
" == N == "
" ...
" == O == "
" Open current file in Sublime Text
nnoremap <leader>os :! subl '%:p'<cr>
" == P == "
" Duplicate current line, paste after
nnoremap <leader>p Yp
" Nice paste
nnoremap <leader>P :set paste<cr>o<esc>"*]p :set nopaste<cr>
" == Q == "
" Quit
nnoremap <leader>q :q<cr>
" == R == "
" Open .vimrc
nnoremap <leader>rc :e ~/.dotfiles/.vim/.vimrc<cr>
nnoremap <leader>ev :vs $MYVIMRC<CR>
nnoremap <leader>ra :!clear;time bundle exec rake<CR>
" Replace current search with...
nnoremap <leader>rs :%s//
" Open Vim mappings file
nnoremap <leader>rm :e ~/.dotfiles/vim/partials/mappings.vim<cr>
" == S == "
" Trim trailing whitespace
nnoremap <silent> <leader>st :%s/\s\+$//<cr>:let @/=''<cr>
" Open snippets
nnoremap <leader>sd :e ~/.dotfiles/.vim/snippets<cr>
" Edit currently scoped snippets
nnoremap <leader>se :i<cr>
" == T == "
" Tabularize
vnoremap <leader>T :Tabularize /
vnoremap <leader>T= :Tabularize /=<cr>
vnoremap <leader>T: :Tabularize /:<cr>
" Run RSpec test for current file
nnoremap <leader>t :!bundle exec rspec %<cr>
" == U == "
" IndentGuidesToggle
nnoremap <silent> <leader>ug :IndentGuidesToggle<cr>
" == V == "
" Vertical split
nnoremap <leader>v <c-w>v<c-w>l
" Goyo trigger
nnoremap <leader>V :Goyo<cr>
" == W == "
" Save file
nnoremap <leader>w :w<cr>
nnoremap <leader>W :x<cr>
" == X == "
" ...
" == Y == "
" Copy line, paste before current line
nnoremap <leader>y YP
" == Z == "
" Quicker action to suspend Vim ('fg' to return)
nnoremap <leader>z <c-z>
" Replace bottom, middle, top
nnoremap zh H
nnoremap zm M
nnoremap zl L
