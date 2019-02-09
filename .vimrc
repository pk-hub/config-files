"" GENERAL
set nocompatible                    " Use 'vim' settings rather than 'vi' ones
"" INTERFACE
colorscheme evening
set number numberwidth=4            " Show line numbers
highlight LineNr term=bold ctermfg=Black ctermbg=Gray
set linebreak                       " Break lines at word (requires wrap lines)
set showbreak=+++                   " Wrap-broken line prefix
set textwidth=100                   " Line wrap (number of cols)
set softtabstop=4                   " Number of spaces per tab
set expandtab                       " Spaces instead of tabs
set smarttab
set autoindent                      " Auto-indent new lines
set shiftwidth=4                    " Number of auto-indent spaces
set smartindent                     " Enable smart-indent
set ruler                           " Always show cursor
set listchars=trail:.               " Display special character with replacement characters
set list                            " Show  tab characters. Visual whitespace
set laststatus=2                    " Always show status bar
syntax on                           " Syntax highlight with colors

"" SEARCH
set showmatch                       " Use visual bell (no beeping)
set hlsearch                        " Hightlight all search results
set smartcase                       " Enable smart-case searc
set ignorecase                      " Always case-insensitive

"" BEHAVIOUR
set mousemodel=extend               " Search for an exact word using shift + mouse click
set backspace=indent,eol,start      " Backspace behaviour
set undolevels=100                  " Number of undo levels
set cmdheight=2                     " Set command line height
set history=50                      " Keep 50 lines of command line history

"" ADD SHEBANG LINE AUTOMATICALLY
augroup Shebang
  autocmd BufNewFile *.py 0put =\"#!/usr/bin/env python\"|$
  autocmd BufNewFile *.rb 0put =\"#!/usr/bin/env ruby\"|$
  autocmd BufNewFile *.tex 0put =\"%&plain\<nl>\"|$
  autocmd BufNewFile *.\(cc\|hh\) 0put =\"//\<nl>// \".expand(\"<afile>:t\").\" -- \<nl>//\<nl>\"|2|start!
augroup END

"" HIGHLIGHT 120th COLUMN
set cc=120
highlight ColorColumn ctermbg=DarkGreen ctermfg=black

"" MISC COMMANDS
command Todo noautocmd vimgrep /TODO\|FIXME/j ** | cw   " todo list generation

"" MAPPINGS
map <C-o> :NERDTreeToggle<CR>
map <C-x> :FZF<CR>

"" RUNTIME PATH CHANGES
set rtp+=~/.fzf

"" MUST HAVE PLUGINS/TOOLS
"" * nerdtree: https://github.com/scrooloose/nerdtree.git
"" * vim-airline: https://github.com/vim-airline/vim-airline
"" * fugitive: https://github.com/tpope/vim-fugitive
"" * fzf: https://github.com/junegunn/fzf

