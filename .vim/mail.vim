autocmd BufRead /tmp/mutt* set syntax=mail
autocmd BufRead /tmp/mutt* startinsert!
autocmd BufRead /tmp/mutt* set laststatus=1
autocmd BufRead /tmp/mutt* set nohlsearch
autocmd BufRead /tmp/mutt* set expandtab
" autocmd BufRead /tmp/mutt* source ~/.vim/par.vim
autocmd BufRead /tmp/mutt* set tw=72
autocmd BufRead /tmp/mutt* let $PARINIT="72jhq"
" martins eigene addons
autocmd BufRead /tmp/mutt* set list
autocmd BufRead /tmp/mutt* set listchars=tab:»·,trail:·
" kill quoted signature
" detect signature by sigdashes line ("-- ")
" and then delete unto the next non-empty line:
" au BufRead /tmp/mutt* normal :g/^> -- $/,/^$/-1d^M/^$^M^L
" au BufRead /tmp/mutt* normal :g/^> -- $/,/^$/-1d<cr>/^$<cr><c-l>
" au BufRead /tmp/mutt* normal :g/^> -- $/,/^$/-1d<cr>
" au BufRead /tmp/mutt* normal   /^> -- $<cr>dG
" au BufRead /tmp/mutt* normal  :/^> -- $<cr>d}
" au BufRead /tmp/mutt* normal   /^> -- $<cr>
hi mailHeaderKey  ctermfg=cyan
hi mailSubject    ctermfg=magenta
hi mailHeader     ctermfg=darkcyan
hi mailEmail      ctermfg=yellow
hi mailSignature  ctermfg=darkmagenta
hi mailQuoted1    ctermfg=darkgreen
hi mailQuoted2    ctermfg=darkcyan
hi mailQuoted3    ctermfg=darkmagenta
hi mailQuoted4    ctermfg=blue
hi mailQuoted5    ctermfg=darkblue
hi mailQuoted6    ctermfg=black
