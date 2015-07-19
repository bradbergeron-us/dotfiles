" =====================================================
"   Vundle
" =====================================================
set nocompatible
filetype on
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'
" ========== Plugins ====================================
Plugin 'mattn/webapi-vim'
" Close matching parenthesis, quote, etc.
Plugin 'AutoClose'

" ========================================================
" Searching
" ========================================================
" Better, visual navigation
Plugin 'Lokaltog/vim-easymotion'
" Search word under cursor
Plugin 'bronson/vim-visual-star-search'
" Fuzzy file finder
Plugin 'kien/ctrlp.vim'
" Better than Grep
" Plugin 'mileszs/ack.vim'
" Front for ag, A.K.A. the_silver_searcher
Plugin 'rking/ag.vim'

" ========================================================
" Formatting Text
" ========================================================
" Indentation guides
Plugin 'nathanaelkane/vim-indent-guides'
" Populate the argument list from the files in the quickfix list
Plugin 'nelstrom/vim-qargs'
" Markdown Preview
Plugin 'nelstrom/vim-markdown-preview'
" Syntax checker
Plugin 'scrooloose/syntastic'
" Expanding abbreviations
Plugin 'mattn/emmet-vim'

" ===========================================
" Textmate Style Snippets in Vim
" ============================================
" Dependencies:
Plugin 'SirVer/ultisnips'
" Optional:
Plugin 'honza/vim-snippets'

" ===========================================
" Useful Utilities
" ===========================================
" Select, and act on, multiple words at once
Plugin 'terryma/vim-multiple-cursors'
Plugin 'digitaltoad/vim-jade'
" Context Aware Tabbing
Plugin 'ervandew/supertab'
" Simple TODO lists
Plugin 'vitalk/vim-simple-todo'
" Adds a 'gs' sort
Plugin 'christoomey/vim-sort-motion'
" GitHub Gist (and dependencies)
Plugin 'mattn/gist-vim'
" Plugin 'Valloric/YouCompleteMe'
" Text filtering and alignment
Plugin 'godlygeek/tabular'
" Just like 'f', but for two characters
Plugin 'goldfeld/vim-seek'
" Distraction-free writing
Plugin 'junegunn/goyo.vim'

" ======================================================
" Tmux and Statusline
" ======================================================
Plugin 'bling/vim-airline'
Plugin 'airblade/vim-gitgutter'
Plugin 'jgdavey/vim-turbux'
Plugin 'edkolev/tmuxline.vim'
Plugin 'benmills/vimux'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'jgdavey/tslime.vim'
Plugin 'thoughtbot/vim-rspec'

" =======================================================
"   Color Scheme
" =======================================================
Plugin 'whatyouhide/vim-gotham'

" ========================================================
"   Git Integration
" ========================================================
Plugin 'chrisbra/vim-diff-enhanced'
" Nice inteface for dealing with Git branches
Plugin 'idanarye/vim-merginal'

" ==========================================================
"   Language Specific Plugins
" ==========================================================
" =========  HTML ===============
Plugin 'nono/vim-handlebars'

" =======  Javascript ===========
Plugin 'kchmck/vim-coffee-script'
Plugin 'elzr/vim-json'
Plugin 'burnettk/vim-angular'
"======== Go Lang ===============
Plugin 'fatih/vim-go'
"Plugin 'Shougo/neocomplete.vim'
Plugin 'majutsushi/tagbar'

" ======== Ruby ==================
"Executes Ruby Code in Buffer
Plugin 't9md/vim-ruby-xmpfilter'
Plugin 'hwartig/vim-seeing-is-believing'

"========= Elixir =================
Plugin 'elixir-lang/vim-elixir'
"=======================================
"   Tim Pope (Prolific Plug-in Writer)
"=======================================
Plugin 'tpope/vim-abolish'
" Does something with TMUX
" //TODO: look up docs for:
Plugin 'tpope/vim-dispatch'
" Support for Haml and Sass
Plugin 'tpope/vim-haml'
Plugin 'tpope/vim-markdown'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-surround'
" Improved netrw similar to NERDTREE
Plugin 'tpope/vim-vinegar'
Plugin 'tpope/vim-projectionist'
" Git Wrapper within Vim
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-git'
" Rails Utility Belt
Plugin 'tpope/vim-rails'
"Native Ruby Plugins
Plugin 'tpope/vim-rake'
Plugin 'tpope/vim-endwise'
Plugin 'tpope/vim-bundler'
Plugin 'tpope/vim-rbenv'
"Behavior Driven Development
Plugin 'tpope/vim-cucumber'
Plugin 'tpope/vim-eunuch'
" Date Helper
Plugin 'tpope/vim-speeddating'
Plugin 'tpope/vim-tbone'
Plugin 'tpope/vim-commentary'
call vundle#end()
filetype indent plugin on

