" plugins.vim

call plug#begin('~/.local/share/nvim/plugged')

	Plug 'scrooloose/nerdtree'                  " a nice filesystem explorer

	Plug 'Xuyuanp/nerdtree-git-plugin'          " plugin for NERDTree showing git status.

    Plug 'gyaru/ctrlp.vim'                      " fuzzy finder

    Plug 'chriskempson/base16-vim'              " base16 colour schemes.

	Plug 'sheerun/vim-polyglot'                 " syntax and shit for various languages.

	Plug 'vim-airline/vim-airline'              " a statusline/tabline plugin.
	Plug 'vim-airline/vim-airline-themes'

	Plug 'Shougo/deoplete.nvim',{ 'do': ':UpdateRemotePlugins' } " deoplete, an asynchronous keyword completion system.

call plug#end()

" deoplete
let g:deoplete#enable_at_startup = 1
let g:deoplete#auto_completion_start_length = 2

" nerdtree
map <C-n> :NERDTreeToggle<CR>
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif

" airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline_theme='base16_ocean'
let g:airline_powerline_fonts = 0
" ctrlp
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
