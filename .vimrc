" File and backup settings
set nobackup            " Disable create backup files
set noswapfile          " Disable swap files
set nowritebackup       " Disable backup before overwriting

" Text wrapping
set linebreak           " Wrap lines at word boundaries, not mid-word

" Search settings
set hlsearch            " Highlight search matches
set incsearch           " Highlight matches as you type
highlight Search    ctermbg=236 ctermfg=darkred
highlight IncSearch ctermbg=236 ctermfg=darkred cterm=NONE

" Key mappings
" Clear search highlights and redraw screen with Ctrl-L
nnoremap <C-L> :nohl<CR><C-L>
" Reload .vimrc with Ctrl-R
nnoremap <C-R> :source ~/.vimrc<CR>
" Prevent accidental command history with q:
nnoremap q: :
" Scroll by display line (not physical line)
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk
" Scroll horizontally
nnoremap H 5zh
nnoremap L 5zl

" Filetype and syntax
filetype plugin on   " Enable filetype-specific plugins
filetype indent on   " Enable filetype-specific indentation
syntax on            " Enable syntax highlighting

" Indentation and tabs
set tabstop=2        " Width of a tab character
set softtabstop=2    " Width of a tab when editing
set shiftwidth=2     " Width for auto-indents
set autoindent       " Copy indent from previous line
set noexpandtab      " Don't replace tabs with spaces

" Whitespace and backspace
autocmd BufRead,BufNewFile * match Error /\s\+$/  " Highlight trailing whitespace
set backspace=indent,eol,start                    " Make backspace work over indents, line ends, and start of insert

" Editing behavior
set paste            " Enable paste mode for clean pasting
autocmd FileType python set paste  " Enable paste mode for Python files
autocmd FileType javascript set paste  " Enable paste mode for Python files
autocmd FileType html set paste  " Enable paste mode for Python files
set nowrap           " Disable line wrapping
set smartcase        " Case-sensitive search if pattern contains uppercase

" Show number of search matches
set shortmess-=S

" Move left and right
nnoremap <C-h> 5zh
nnoremap <C-l> 5zl
