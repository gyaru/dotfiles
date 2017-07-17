" init.vim
set nocompatible

" plugins
source ~/.config/nvim/plugins.vim

" keybindings
source ~/.config/nvim/keybindings.vim

" basic settings
filetype plugin indent on
syntax on

" interface
set autoread
set cmdheight=1
set hid
set foldcolumn=0
set laststatus=2
set linebreak
set number
set ruler
set scrolloff=3
set showcmd
set showmatch
set textwidth=500
set wildmenu
set wrap

" search
set ignorecase
set smartcase
set hlsearch
set incsearch

" indenting
set autoindent
set smartindent

" tabs
set expandtab
set shiftwidth=4
set smarttab
set tabstop=4

" performance
set lazyredraw
set ttyfast

" let's jump to the last known cursor position if known.
autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
\ endif

" unfuck cursor after nvim exit
set guicursor=
au VimLeave * set guicursor

" colours
set background=dark
colorscheme base16-ocean
set termguicolors
highlight LineNr guibg=background
highlight SignColumn guibg=background

" no point showing this if we have a statusline
set noshowmode
