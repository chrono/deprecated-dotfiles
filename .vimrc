" /tmp/mutt* are emails, set tw and start in insertmode
" au BufRead /tmp/mutt-* :g/^> --.*/,/^$/-1d
autocmd BufRead /tmp/mutt* source ~/.vim/mail.vim
autocmd BufRead *.php source ~/.vim/PEAR.vim
autocmd BufRead *.as setl filetype=actionscript
autocmd FileType smarty setl matchpairs+=<:> " we want to jump around those xml tags using %
autocmd FileType gitlog setl keywordprg=git\ show\ --pretty=raw

autocmd BufNewFile,BufRead *.git/COMMIT_EDITMSG    setf gitcommit
autocmd BufNewFile,BufRead *.git/config,.gitconfig setf gitconfig
autocmd BufNewFile,BufRead git-rebase-todo         setf gitrebase
autocmd BufNewFile,BufRead .msg.[0-9]*
	\ if getline(1) =~ '^From.*# This line is ignored.$' |
	\   setf gitsendemail |
	\ endif
autocmd BufNewFile,BufRead *.git/**
	\ if getline(1) =~ '^\x\{40\}\>\|^ref: ' |
	\   setf git |
	\ endif

autocmd BufRead /etc/apache2/* set syntax=apache
autocmd BufRead *svn-commit.tmp startinsert!

set nocompatible    " Use Vim defaults (much better!)
set backspace=2     " allow backspacing over everything in insert mode
set ruler
set scrolloff=5  " keep context wen scrolling
set ttyfast " fast terminal connection
set hlsearch " highlight search matches

autocmd BufEnter * let &titlestring = "vim(" . expand("%:t") . ")"

if &term =~ "^screen"
  set t_ts=k
  set t_fs=\
endif
set title
set laststatus=2
set directory-=. " do not litter my working directory with swap files

" mutt config files
autocmd BufRead *muttrc set syntax=muttrc
autocmd BufRead *.mutt set syntax=muttrc
syntax on

let loaded_vimspell = 0
let spell_executable = "aspell"
let spell_update_time = 2000
let spell_language_list = "german,english"
ab mfg Mit freundlichen Grüßen
let mapleader = "\\"
let Tlist_Process_File_Always = 1
set vb
" I find myself typing ":wq" in insert-mode many a time.
" Add this to your .vimrc.

function WQHelper()
    let x = confirm("Current Mode ==  Insert-Mode!\n Would you like ':wq'?"," &Yes \n &No",1,1)
    if x == 1
    silent! :wq
    else
        "???
    endif
endfunction
iab wq <bs><esc>:call WQHelper()<CR>

" http://www.rayninfo.co.uk/vimtips.html
" f5 - list buffer ask number
map   <F5> :ls<CR>:e #
set number
" C-j & C-K als window-tabber
set wmh=0
map <C-J> <C-W>j<C-W>_
map <C-K> <C-W>k<C-W>_ 
nmap <silent> <A-Up> :wincmd k<CR>
nmap <silent> <A-Down> :wincmd j<CR>
nmap <silent> <A-Left> :wincmd h<CR>
nmap <silent> <A-Right> :wincmd l<CR> 
imap <S-space> <esc>
map <S-space> i
imap <C-space> <C-N>
set switchbuf=useopen
" REQUIRED. This makes vim invoke latex-suite when you open a tex file.
filetype plugin on
" IMPORTANT: grep will sometimes skip displaying the file name if you
" search in a singe file. This will confuse latex-suite. Set your grep
" program to alway generate a file-name.
set grepprg=grep\ -nH\ $*
source $VIMRUNTIME/menu.vim
set wildmenu
set cpo-=<
set wcm=<C-Z>
map <F4> :emenu <C-Z>
nnoremap <silent> <F8> :TlistToggle<CR>

" This function determines, wether we are on the start of the line text (then tab indents) or
" if we want to try autocompletion
function InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<tab>"
    else
        return "\<c-p>"
    endif
endfunction

function s:Cursor_Moved()
  let cur_pos= line ('.')
  if g:last_pos==0
    set cul
    let g:last_pos=cur_pos
    return
  endif
  let diff= g:last_pos - cur_pos
  if diff > 1 || diff < -1
     set cul
    else
     set nocul
  end
  let g:last_pos=cur_pos
endfunction

autocmd CursorMoved,CursorMovedI * call s:Cursor_Moved()
let g:last_pos=0   

" Remap the tab key to select action with InsertTabWrapper
inoremap <tab> <c-r>=InsertTabWrapper()<cr>
set list
set listchars=tab:>-,trail:-
set ignorecase                  " caseinsensitive searches
set showmode                    " always show command or insert mode
set whichwrap=b,s,<,>,[,]

set background=dark

if has("gui_macvim")
  let macvim_hig_shift_movement = 1
endif
