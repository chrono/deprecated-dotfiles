" .vim/ftplugin/php.vim by Tobias Schlitt <toby@php.net>.
" No copyright, feel free to use this, as you like.

" Including PDV
source ~/.vim/php-doc.vim

" {{{ Settings
setl tabstop=4
setl shiftwidth=4

" Auto expand tabs to spaces
setl expandtab

" Auto indent after a {
setl autoindent
setl smartindent

" Linewidth to endless
setl textwidth=0

" Do not wrap lines automatically
setl nowrap

" Correct indentation after opening a phpdocblock and automatic * on every
" line
setl formatoptions=qroct

" Use errorformat for parsing PHP error output
setl errorformat=%m\ in\ %f\ on\ line\ %l

" }}} Settings

" {{{ Command mappings

" Map ; to run PHP parser check
" noremap ; :!php5 -l %<CR>

" Map ; to "add ; to the end of the line, when missing"
" noremap ; :s/\([^;]\)$/\1;/<cr>

" DEPRECATED in favor of PDV documentation (see below!)
" Map <CTRL>-P to run actual file with PHP CLI
" noremap <C-P> :w!<CR>:!php5 %<CR>

"" Map <ctrl>+p to single line mode documentation (in insert and command mode)
"inoremap <C-P> :call PhpDocSingle()<CR>i
nnoremap <buffer> <C-P> :call PhpDocSingle()<CR>
"" Map <ctrl>+p to multi line mode documentation (in visual mode)
vnoremap <buffer> <C-P> :call PhpDocRange()<CR>
"
"" Map <CTRL>-H to search phpm for the function name currently under the cursor (insert mode only)
"inoremap <C-H> <ESC>:!phpm <C-R>=expand("<cword>")<CR><CR>

" }}}

" {{{ Automatic close char mapping

" More common in PEAR coding standard
inoremap  <buffer> { {<CR>}<C-O>O
" Maybe this way in other coding standards
" inoremap  { <CR>{<CR>}<C-O>O

inoremap <buffer> [ []<LEFT>

" Standard mapping after PEAR coding standard
inoremap <buffer> ( ()<LEFT>

" Maybe this way in other coding standards
" inoremap ( ( )<LEFT><LEFT> 

inoremap <buffer> " ""<LEFT>
inoremap <buffer> ' ''<LEFT>

" }}} Automatic close char mapping

" {{{ Wrap visual selections with chars

:vnoremap <buffer> ( "zdi(<C-R>z)<ESC>
:vnoremap <buffer> { "zdi{<C-R>z}<ESC>
:vnoremap <buffer> [ "zdi[<C-R>z]<ESC>
:vnoremap <buffer> ' "zdi'<C-R>z'<ESC>
" :vnoremap " "zdi"<C-R>z"<ESC>

" }}} Wrap visual selections with chars

" {{{ Dictionary completion

" The completion dictionary is provided by Rasmus:
" http://lerdorf.com/funclist.txt
"set dictionary-=/home/dotxp/funclist.txt dictionary+=/home/dotxp/funclist.txt
setl dictionary+=~/.vim/ftplugin/php/funclist.txt
"" Use the dictionary completion
"set complete-=k complete+=k
setl complete+=k

" }}} Dictionary completion

" {{{ Autocompletion using the TAB key

" This function determines, wether we are on the start of the line text (then tab indents) or
" if we want to try autocompletion
func! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<tab>"
    else
        return "\<c-p>"
    endif
endfunction

" Remap the tab key to select action with InsertTabWrapper
inoremap <buffer> <tab> <c-r>=InsertTabWrapper()<cr>

" }}} Autocompletion using the TAB key

" taglist
nnoremap <buffer> <silent> <F8> :Tlist<CR>

function! PHPsynCHK()
    let winnum = winnr() " get current window number
    silent make %
    redraw!
    cw " open the error window if it contains error
    " return to the window with cursor set on the line of the first error (if any)
    execute winnum . "wincmd w"
endfunction 
setl makeprg=php\ -l\ 
setl errorformat=%m\ in\ %f\ on\ line\ %l 
noremap <buffer> <C-I> :call PHPsynCHK()<CR>
"autocmd BufWritePost,FileWritePost *.php call PHPsynCHK()
autocmd BufWritePost <buffer> call PHPsynCHK()
setlocal foldmethod=manual
EnableFastPHPFolds
" some templates
inoremap <buffer> ;; <C-O>/%%%<CR><C-O>c3l
nnoremap <buffer> ;; /%%%<CR>c3l
inoremap <buffer> ;fo <C-O>mzfor (%%%;%%%;%%%) {<CR>}<C-O>O%%%<C-O>'z<C-O>/%%%<CR><C-O>c3l
inoremap <buffer> ;fe <C-O>mzforeach (%%% as %%% => %%%<ESC>A{%%%<C-O>'z;;
inoremap <buffer> ;i <C-O>mzif (%%%<ESC>A{%%%<C-O>'z;;

fun! OpenPhpFunction (keyword, split)
    " let proc_keyword = substitute(a:keyword , '_', '-', 'g')
    let proc_keyword = a:keyword
    if a:split
        exe 'split'
        exe 'enew'
        exe "set buftype=nofile"
    else
        exe 'norm gg'
        exe 'silent norm dG'
    endif
    " exe 'silent r!lynx -dump -nolist http://www.php.net/manual/en/print/function.'.proc_keyword.'.php'
    exe 'silent r!lynx -dump -nolist http://www.php.net/'.proc_keyword
    exe 'norm gg'
    exe 'call search ("^' . a:keyword .'")'
    exe 'silent norm dgg'
    exe 'call search("User Contributed Notes")'
    exe 'silent norm dGgg'
    map <buffer> K :call OpenPhpFunction('<c-r><c-w>', 0)<CR>
endfun
map <buffer> K :call OpenPhpFunction('<c-r><c-w>', 1)<CR>
" setl keywordprg=~/bin/phpdoc.sh

" map <buffer> <F5> <Esc>:EnableFastPHPFolds<Cr>
" map <buffer> <F6> <Esc>:EnablePHPFolds<Cr>
" map <buffer> <F7> <Esc>:DisablePHPFolds<Cr>
