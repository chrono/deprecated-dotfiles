" This sets up *.otl files to be outlines
" $Id: filetype_otl.vim,v 1.2 2001/11/12 18:47:13 ned Exp $
augroup filetypedetect
au BufNewFile,BufRead *.otl			setf otl
augroup END
