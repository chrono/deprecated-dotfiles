" tSkeleton.vim
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     21-Sep-2004.
" @Last Change: 23-Sep-2006.
" @Revision:    2.2.1649
"
" vimscript #1160
" http://www.vim.org/scripts/script.php?script_id=1160
"
" TODO:
" - <form in php mode funktioniert nicht
" - ADD: make use of vim7 omnicompletion (or of its new popup menu for 
"   g:tskelQueryType)
" - FIX: minibits are not included in the popup menu or offered for 
"   completion
" - CHANGE: Use expand("<cword>")
" - FIX: No popup menu when nothing is selected in insert mode & cursor 
"   at last position (bibtex mode)
" - ADD: More latex & html bits
" - ADD: <tskel:post> embedded tag (evaluate some vim code on the visual 
"   region covering the final expansion)
" - ADD: Create map files from ctags files?
" - FIX: The \section bit either moves the cursor after the closing 
"   curly brace or (when applying some correction) before the opening 
"   CB. This is very confusing.


if &cp || exists("loaded_tskeleton") "{{{2
    finish
endif
let loaded_tskeleton = 202

if !exists('loaded_genutils') "{{{2
    runtime plugin/genutils.vim
    if !exists('loaded_genutils')
        echoerr "tSkeleton: genutils (vimscript #197) is required"
        finish
    endif
endif

if !exists("g:tskelDir") "{{{2
    let g:tskelDir = globpath(&rtp, 'skeletons/')
    let g:tskelDir = matchstr(g:tskelDir, '^.\{-}\ze\(\n\|$\)')
endif

if !isdirectory(g:tskelDir) "{{{2
    echoerr 'tSkeleton: Please set g:tskelDir ('. g:tskelDir .') first!'
    finish
endif

if g:tskelDir !~ '[/\\]$'
    let g:tskelDir = g:tskelDir.'/'
endif

let g:tskelBitsDir = g:tskelDir .'bits/'

if !exists('g:tskelLicense') "{{{2
    let g:tskelLicense = 'GPL (see http://www.gnu.org/licenses/gpl.txt)'
endif

if !exists("g:tskelMapLeader")     | let g:tskelMapLeader     = "<Leader>#"   | endif "{{{2
if !exists("g:tskelMapInsert")     | let g:tskelMapInsert     = '<c-\><c-\>'  | endif "{{{2
if !exists("g:tskelPatternLeft")   | let g:tskelPatternLeft   = "<+"          | endif "{{{2
if !exists("g:tskelPatternRight")  | let g:tskelPatternRight  = "+>"          | endif "{{{2
if !exists("g:tskelPatternCursor") | let g:tskelPatternCursor = "<+CURSOR+>"  | endif "{{{2
if !exists("g:tskelDateFormat")    | let g:tskelDateFormat    = "%d-%b-%Y"    | endif "{{{2
if !exists("g:tskelUserName")      | let g:tskelUserName      = "<+NAME+>"    | endif "{{{2
if !exists("g:tskelUserAddr")      | let g:tskelUserAddr      = "<+ADDRESS+>" | endif "{{{2
if !exists("g:tskelUserEmail")     | let g:tskelUserEmail     = "<+EMAIL+>"   | endif "{{{2
if !exists("g:tskelUserWWW")       | let g:tskelUserWWW       = "<+WWW+>"     | endif "{{{2

if !exists("g:tskelRevisionMarkerRx") | let g:tskelRevisionMarkerRx = '@Revision:\s\+' | endif "{{{2
if !exists("g:tskelRevisionVerRx")    | let g:tskelRevisionVerRx = '\(RC\d*\|pre\d*\|p\d\+\|-\?\d\+\)\.' | endif "{{{2
if !exists("g:tskelRevisionGrpIdx")   | let g:tskelRevisionGrpIdx = 3 | endif "{{{2

if !exists("g:tskelMaxRecDepth") | let g:tskelMaxRecDepth = 10 | endif "{{{2
if !exists("g:tskelChangeDir")   | let g:tskelChangeDir   = 1  | endif "{{{2

if !exists("g:tskelMenuPrefix")   | let g:tskelMenuPrefix  = 'TSke&l'    | endif "{{{2
if !exists("g:tskelMenuCache")    | let g:tskelMenuCache = '.tskelmenu' | endif "{{{2
if !exists("g:tskelMenuPriority") | let g:tskelMenuPriority = 90 | endif "{{{2

if !exists("g:tskelQueryType") "{{{2
    if has('gui_win32') || has('gui_win32s') || has('gui_gtk')
        let g:tskelQueryType = 'popup'
    else
        let g:tskelQueryType = 'query'
    end
endif

if !exists("g:tskelPopupNumbered") | let g:tskelPopupNumbered = 1 | endif "{{{2

if !exists("g:tskelKeyword_bib")  | let g:tskelKeyword_bib  = '[@[:alnum:]]\{-}'       | endif "{{{2
if !exists("g:tskelKeyword_html") | let g:tskelKeyword_html = '<\?[^>[:blank:]]\{-}'   | endif "{{{2
if !exists("g:tskelKeyword_sh")   | let g:tskelKeyword_sh   = '[\[@${([:alpha:]]\{-}'  | endif "{{{2
if !exists("g:tskelKeyword_tex")  | let g:tskelKeyword_tex  = '\\\?\w\{-}'             | endif "{{{2
if !exists("g:tskelKeyword_viki") | let g:tskelKeyword_viki = '\(#\|{\)\?[^#{[:blank:]]\{-}' | endif "{{{2

if !exists("g:tskelBitGroup_php") "{{{2
    let g:tskelBitGroup_php = "php\nhtml"
endif

let s:tskelScratchIdx  = 0
let s:tskelScratchMax  = 0
let s:tskelDestBufNr   = -1
let s:tskelBuiltMenu   = 0
let s:tskelSetFiletype = 1
let s:tskelLine        = 0
let s:tskelCol         = 0
let s:tskelDidSetup    = 0
let s:tskelProcessing  = 0
let s:tskelPattern     = g:tskelPatternLeft ."\\("
            \ ."&.\\{-}\\|b:.\\{-}\\|g:.\\{-}\\|bit:.\\{-}\\|tskel:.\\{-}"
            \ ."\\|?.\\{-}?"
            \ ."\\|call:\\('[^']*'\\|\"\\(\\\\\"\\|[^\"]\\)*\"\\|[bgs]:\\|.\\)\\{-1,}"
            \ ."\\|[a-zA-Z ]\\+"
            \ ."\\)\\(: *.\\{-} *\\)\\?". g:tskelPatternRight

fun! TSkeletonFillIn(bit, ...) "{{{3
    " try
        let b:tskelFiletype = a:0 >= 1 && a:1 != "" ? a:1 : ""
        let ft = b:tskelFiletype != "" ? ", '". b:tskelFiletype ."'" : ""
        call <SID>GetBitProcess('msg', 2)
        let before  = <SID>GetBitProcess('before', 1)
        let after   = <SID>GetBitProcess('after', 1)
        let hbefore = <SID>GetBitProcess('here_before', 0)
        let hafter  = <SID>GetBitProcess('here_after', 0)
        if before
            call <SID>EvalBitProcess('before', 1)
        endif
        if hbefore
            call <SID>EvalBitProcess('here_before', 0)
        endif
        silent norm! G$
        let s:tskelLine_{s:tskelScratchIdx} = search(s:tskelPattern, 'w')
        while s:tskelLine_{s:tskelScratchIdx} > 0
            " let col  = virtcol(".")
            let col  = col(".")
            let line = strpart(getline("."), col - 1)
            let text = substitute(line, s:tskelPattern .'.*$', '\1', '')
            let s:tskelPostExpand = ""
            let repl = <SID>HandleTag(text, b:tskelFiletype)
            if repl != '' && line =~ '\V\^'. escape(repl, '\')
                norm! l
            else
                let mod  = substitute(line, s:tskelPattern .'.*$', '\4', '')
                let repl = <SID>Modify(repl, mod)
                let repl = substitute(repl, "\<c-j>", "", "g")
                " silent exec 's/\%'. col .'v'. s:tskelPattern .'/'. escape(repl, '/')
                silent exec 's/\%'. col .'c'. s:tskelPattern .'/'. escape(repl, '/')
            endif
            if s:tskelPostExpand != ""
                exec s:tskelPostExpand
                let s:tskelPostExpand = ""
            end
            if s:tskelLine_{s:tskelScratchIdx} > 0
                let s:tskelLine_{s:tskelScratchIdx} = search(s:tskelPattern, "W")
            endif
		endwhile
        if !a:bit
            call <SID>SetCursor('%', '')
        endif
        if hafter
            call <SID>EvalBitProcess('here_after', 0)
        endif
        if after
            call <SID>EvalBitProcess('after', 1)
        endif
    " catch
    "     echom "An error occurred in TSkeletonFillIn() ... ignored"
    " endtry
endf

fun! <SID>HandleTag(match, filetype) "{{{3
    if a:match =~ '^[bg]:'
        return <SID>Var(a:match)
    " elseif a:match =~ '^if '
    "     return <SID>SwitchIf(strpart(a:match, 3))
    " elseif a:match =~ '^elseif '
    "     return <SID>SwitchElseif(strpart(a:match, 7))
    " elseif a:match =~ '^else'
    "     return <SID>SwitchElse()
    " elseif a:match =~ '^endif '
    "     return <SID>SwitchEndif()
    elseif a:match =~ '\C^\([A-Z ]\+\)'
        return <SID>Dispatch(a:match)
    elseif a:match[0] == '&'
        return <SID>Exec(a:match)
    elseif a:match[0] == '?'
        return <SID>Query(strpart(a:match, 1, strlen(a:match) - 2))
    elseif strpart(a:match, 0, 4) =~ 'bit:'
        return <SID>Expand(strpart(a:match, 4), a:filetype)
    elseif strpart(a:match, 0, 6) =~ 'tskel:'
        return <SID>Expand(strpart(a:match, 6), a:filetype)
    elseif strpart(a:match, 0, 5) =~ 'call:'
        return <SID>Call(strpart(a:match, 5))
    else
        return a:match
    end
endf

" <SID>SetCursor(from, to, ?mode='n', ?findOnly)
fun! <SID>SetCursor(from, to, ...) "{{{3
    let mode     = a:0 >= 1 ? a:1 : 'n'
    let findOnly = a:0 >= 2 ? a:2 : (s:tskelScratchIdx > 1)
    let c = col('.')
    let l = line('.')
    if a:to == ''
        if a:from == '%'
            silent norm! gg
        else
            exec a:from
        endif
    else
        exec a:to
    end
    if line('.') == 1
        norm! G$
        let l = search(g:tskelPatternCursor, 'w')
    else
        norm! k$
        let l = search(g:tskelPatternCursor, 'W')
    end
    if l == 0
        " silent exec "norm! ". c ."|". l ."G"
        call cursor(l, c)
        return 0
    elseif !findOnly
        let c = col('.')
        silent exec 's/'. g:tskelPatternCursor .'//e'
        " silent exec 's/'. g:tskelPatternCursor .'//e'
        " silent exec "norm! ". c ."|"
        call cursor(0, c)
    endif
    return l
endf

" fun! <SID>SwitchIf(text)
" endf
" 
" fun! <SID>SwitchElseif(text)
" endf
" 
" fun! <SID>SwitchElse()
" endf
" 
" fun! <SID>SwitchEndif()
" endf
" 
" fun! <SID>RemoveBranch()
"     let pos = <SID>SavePos()
"     let nxt = 
"     call <SID>RestorePos(pos)
" endf

fun! <SID>Var(arg) "{{{3
    if exists(a:arg)
        exec 'return '.a:arg
    else
        return TSkeletonEvalInDestBuffer(a:arg)
    endif
endf

fun! <SID>Exec(arg) "{{{3
    return TSkeletonEvalInDestBuffer(a:arg)
endf

fun! TSkelIncreaseIndex(var) "{{{3
    exec "let ". a:var ."=". a:var ."+1"
    return a:var
endf

fun! <SID>Query(arg) "{{{3
    let sepx = stridx(a:arg, "|")
    let var  = strpart(a:arg, 0, sepx)
    " let text = substitute(strpart(a:arg, sepx + 1), ':?$', ':', '')
    let text = strpart(a:arg, sepx + 1)
    let tsep = stridx(text, "|")
    if tsep == -1
        let repl = ''
    else
        let repl = strpart(text, tsep + 1)
        let text = strpart(text, 0, tsep)
    endif
    if var != ""
        if !TSkeletonEvalInDestBuffer("exists('". var ."')")
            echom "Unknown choice variable: ". var
        else
            let b:tskelQueryIndex = 0
            let val = TSkeletonEvalInDestBuffer(var)
            echo "Choices:"
            let val = substitute("\n". val. "\n", "\n\\zs\\(.\\{-}\\)\\ze\n", "\\=<SID>QuerySeparator(submatch(1))", "g")
            unlet b:tskelQueryIndex
            let sel = input(text. " ", '')
            if sel != ""
                let rv = matchstr(val, "\n". sel .": \\zs\\(.\\{-}\\)\\ze\n")
                if rv == val
                    let rv = sel
                endif
                if repl != ''
                    let rv = <SID>sprintf1(repl, rv)
                endif
                return rv
            else
                return ""
            endif
        endif
    endif
    let rv = input(text. " ", '')
    if rv != '' && repl != ''
        let rv = <SID>sprintf1(repl, rv)
    endif
    return rv
endf

fun! <SID>QuerySeparator(txt) "{{{3
    let b:tskelQueryIndex = b:tskelQueryIndex + 1
    let rv = b:tskelQueryIndex .": ". a:txt
    echo rv
    return rv
endf

fun! <SID>GetVarName(name, global) "{{{3
    if a:global == 2
        return 's:tskelBitProcess_'. a:name
    elseif a:global == 1
        return 's:tskelBitProcess_'. s:tskelScratchIdx .'_'. a:name
    else
        return 'b:tskelBitProcess_'. a:name
    endif
endf

fun! <SID>SaveBitProcess(name, match, global) "{{{3
    let v = <SID>GetVarName(a:name, a:global)
    if a:global == 2 && exists(v)
        let c = 'let '. v .' = '. v .' ."'. escape(a:match, '"\') .'"'
    else
        let c = 'let '. v .' = "'. escape(a:match, '"\') .'"'
    endif
    exec c
    let s:tskelGetBit = 1
    return ""
endf

fun! <SID>GetBitProcess(name, global) "{{{3
    silent norm! gg
    let s:tskelGetBit = 0
    exec 's/^\s*<tskel:'. a:name .'>\s*\n\(\(.\{-}\n\)\{-}\)\s*<\/tskel:'. a:name .'>\s*\n/\=<SID>SaveBitProcess("'. a:name .'", submatch(1), '. a:global .')/e'
    return s:tskelGetBit
endf

fun! <SID>EvalBitProcess(name, global) "{{{3
    let v = <SID>GetVarName(a:name, a:global)
    if exists(v)
        if a:global
            call TSkeletonExecInDestBuffer('exec '. v)
            call TSkeletonExecInDestBuffer('unlet '. v)
        else
            exec 'exec '. v
            exec 'unlet '. v
        endif
    endif
endf

fun! <SID>Modify(text, modifier) "{{{3
    let rv = escape(a:text, '\&~')
    let premod = '^[:ulcs]\{-}'
    if a:modifier =~? premod.'u'
        let rv = toupper(rv)
    endif
    if a:modifier =~? premod.'l'
        let rv = tolower(rv)
    endif
    if a:modifier =~? premod.'c'
        let rv = toupper(rv[0]) . tolower(strpart(rv, 1))
    endif
    if a:modifier =~? premod.'C'
        let rv = substitute(rv, '\(^\|[^a-zA-Z0-9_]\)\(.\)', '\u\2', 'g')
    endif
    if a:modifier =~? premod.'s'
        let mod  = substitute(a:modifier, '^[^s]*s\(.*\)$', '\1', '')
        " let rxm  = '\V'
        let rxm  = ''
        let sep  = mod[0]
        let esep = escape(sep, '\')
        let pat  = '\(\[^'. sep .']\*\)'
        let rx   = '\V\^'. esep . pat . esep . pat . esep .'\$'
        let from = substitute(mod, rx, '\1', '')
        let to   = substitute(mod, rx, '\2', '')
        let rv   = substitute(rv, rxm . from, to, 'g')
    endif
    return rv
endf

fun! <SID>Dispatch(name) "{{{3
    let name = substitute(a:name, '^ *\(.\{-}\) *$', '\1', '')
    let name = substitute(name, " ", "_", "g")
    if exists("*TSkeleton_". name)
        return TSkeleton_{name}()
    else
        return g:tskelPatternLeft . a:name . g:tskelPatternRight
    endif
endf

fun! <SID>Call(fn) "{{{3
    return TSkeletonEvalInDestBuffer(a:fn)
endf

fun! <SID>Expand(bit, ...) "{{{3
    let ft = a:0 >= 1 && a:0 != "" ? a:1 : &filetype
    call <SID>PrepareBits(ft)
    let t = @t
    try
        let sepx = match(a:bit, "|")
        if sepx == -1
            let name    = a:bit
            let default = ""
        else
            let name    = strpart(a:bit, 0, sepx)
            let default = strpart(a:bit, sepx + 1)
        endif
        let @t = ""
        let bitfname = <SID>SelectBit(name, ft)
        let indent   = <SID>GetIndent(getline("."))
        if bitfname != ""
            let setCursor = <SID>RetrieveBit('read', bitfname, indent, ft)
        endif
        if @t == ""
            if default =~ '".*"'
                let @t = substitute(default, '^"\(.*\)"$', '\1', '')
            elseif default != ""
                let s:tskelPostExpand = s:tskelPostExpand .'|norm '. default
            else
                let @t = '<+bit:'.a:bit.'+>'
            endif
        endif
        return @t
    finally
        let @t = t
    endtry
endf

fun! TSkeletonGetVar(name, ...) "{{{3
    if TSkeletonEvalInDestBuffer('exists("b:'. a:name .'")')
        return TSkeletonEvalInDestBuffer('b:'. a:name)
    elseif a:0 >= 1
        exec "return ". a:1
    else
        exec "return g:". a:name
    endif
endf

fun! TSkeletonEvalInDestBuffer(code) "{{{3
    return TSkeletonExecInDestBuffer("return ". a:code)
endf

fun! TSkeletonExecInDestBuffer(code) "{{{3
    let cb = bufnr("%")
    try
        if s:tskelDestBufNr >= 0
            silent exec "buffer ". s:tskelDestBufNr
        endif
        exec a:code
    finally
        if bufnr("%") != cb
            silent exec "buffer ". cb
        endif
    endtry
endf

if !exists('*TSkeleton_FILE_DIRNAME') "{{{2
    fun! TSkeleton_FILE_DIRNAME() "{{{3
        return TSkeletonEvalInDestBuffer('expand("%:p:h")')
    endf
endif

if !exists('*TSkeleton_FILE_SUFFIX') "{{{2
    fun! TSkeleton_FILE_SUFFIX() "{{{3
        return TSkeletonEvalInDestBuffer('expand("%:e")')
    endf
endif

if !exists('*TSkeleton_FILE_NAME_ROOT') "{{{2
    fun! TSkeleton_FILE_NAME_ROOT() "{{{3
        return TSkeletonEvalInDestBuffer('expand("%:t:r")')
    endf
endif

if !exists('*TSkeleton_FILE_NAME') "{{{2
    fun! TSkeleton_FILE_NAME() "{{{3
        return TSkeletonEvalInDestBuffer('expand("%:t")')
    endf
endif

if !exists('*TSkeleton_NOTE') "{{{2
    fun! TSkeleton_NOTE() "{{{3
        let title = TSkeletonGetVar("tskelTitle", 'input("Please describe the project: ")', '')
        let note  = title != "" ? " -- ".title : ""
        return note
    endf
endif

if !exists('*TSkeleton_DATE') "{{{2
    fun! TSkeleton_DATE() "{{{3
        return strftime(TSkeletonGetVar("tskelDateFormat"))
    endf
endif

if !exists('*TSkeleton_TIME') "{{{2
    fun! TSkeleton_TIME() "{{{3
        return strftime("%X")
    endf
endif

if !exists('*TSkeleton_AUTHOR') "{{{2
    fun! TSkeleton_AUTHOR() "{{{3
        return TSkeletonGetVar("tskelUserName")
    endf
endif

if !exists('*TSkeleton_EMAIL') "{{{2
    fun! TSkeleton_EMAIL() "{{{3
        let email = TSkeletonGetVar("tskelUserEmail")
        " return substitute(email, "@"," AT ", "g")
        return email
    endf
endif

if !exists('*TSkeleton_WEBSITE') "{{{2
    fun! TSkeleton_WEBSITE() "{{{3
        return TSkeletonGetVar("tskelUserWWW")
    endf
endif

if !exists('*TSkeleton_LICENSE') "{{{2
    fun! TSkeleton_LICENSE() "{{{3
        return TSkeletonGetVar("tskelLicense")
    endf
endif

fun! TSkeletonSetup(template, ...) "{{{3
    let anyway = a:0 >= 1 ? a:1 : 0
    if anyway || !exists("b:tskelDidFillIn") || !b:tskelDidFillIn
        if filereadable(g:tskelDir . a:template)
            let tf = g:tskelDir . a:template
        elseif filereadable(g:tskelDir ."prefab/". a:template)
            let tf = g:tskelDir ."prefab/". a:template
        else
            echoerr "Unknown skeleton: ". a:template
            return
        endif
        try
            let cpoptions = &cpoptions
            set cpoptions-=a
            exe "0read ". escape(tf, '#% \')
            norm! Gdd
        finally
            let &cpoptions = cpoptions
        endtry
        call TSkeletonFillIn(0, &filetype)
        if g:tskelChangeDir
            let cd = substitute(expand("%:p:h"), '\', '/', 'g')
            let cd = substitute(cd, '//\+', '/', 'g')
            exec "cd ". cd
        endif
        let b:tskelDidFillIn = 1
    endif
endf

fun! TSkeletonSelectTemplate(ArgLead, CmdLine, CursorPos) "{{{3
    if a:CmdLine =~ '^.\{-}\s\+.\{-}\s'
        return ""
    else
        " return <SID>GlobBits(g:tskelDir ."/,". g:tskelDir ."prefab/")
        return <SID>GlobBits(g:tskelDir) . <SID>GlobBits(g:tskelDir .'prefab/')
    endif
endf

command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonSetup 
            \ call TSkeletonSetup(<f-args>)

if has("browse") "{{{2
    fun! <SID>TSkeletonBrowse(save, title, initdir, default) "{{{3
        return browse(a:save, a:title, a:initdir, a:default)
    endf
else
    fun! <SID>TSkeletonBrowse(save, title, initdir, default) "{{{3
        let dir = substitute(a:initdir, '\\', '/', "g")
        let files = substitute(glob(dir. "*"), '\V\(\_^\|\n\)\zs'. dir, '', 'g')
        let files = substitute(files, "\n", ", ", "g")
        echo files
        let tpl = input(a:title ." -- choose file: ", '')
        return a:initdir. tpl
    endf
endif

" TSkeletonEdit(?dir)
fun! TSkeletonEdit(...) "{{{3
    let tpl  = <SID>TSkeletonBrowse(0, "Template", g:tskelDir, "")
    if tpl != ""
        let tpl = a:0 >= 1 && a:1 ? g:tskelDir.a:1 : fnamemodify(tpl, ":p")
        exe "edit ". tpl
    end
endf
command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonEdit 
            \ call TSkeletonEdit(<f-args>)

" TSkeletonNewFile(?template, ?dir, ?fileName)
fun! TSkeletonNewFile(...) "{{{3
    if a:0 >= 1 && a:1 != ""
        let tpl = g:tskelDir. a:1
    else
        let tpl = <SID>TSkeletonBrowse(0, "Template", g:tskelDir, "")
        if tpl == ""
            return
        else
            let tpl = fnamemodify(tpl, ":p")
        endif
    endif
    if a:0 >= 2 && a:2 != ""
        let dir = a:2
    else
        let dir = getcwd()
    endif
    if a:0 >= 3
        let fn = a:3
    else
        let fn = <SID>TSkeletonBrowse(1, "New File", dir, "new.".fnamemodify(tpl, ":e"))
        if fn == ""
            return
        else
            let fn = fnamemodify(fn, ":p")
        endif
    endif
    if fn != "" && tpl != ""
        exe 'edit '. tpl
        exe 'saveas '. fn
        call TSkeletonFillIn(0, &filetype)
        exe "bdelete ". tpl
    endif
endf
command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonNewFile 
            \ call TSkeletonNewFile(<f-args>)


" GlobBits(path, ?flatten=1)
fun! <SID>GlobBits(path, ...) "{{{3
    let pt = "*"
    let fl = a:0 >= 1 ? a:1 : 1
    let rv = globpath(a:path, pt)
    " let rv = "\n". substitute(rv, '\\', '/', 'g') ."\n"
    let rv = substitute(rv, '\\', '/', 'g')
    if fl
        let rv = <SID>PurifyBits(rv)
    else
        let rp = substitute(a:path, '\\', '/', 'g')
        let rv = substitute("\n". rv, '\c\V\n\zs'. rp, '', 'g')
    endif
    return strpart(rv, 1)
endf

fun! <SID>PrepareMiniBit(bit, expansion) "{{{3
    let expansion = a:expansion != '' ? a:expansion : a:bit
    return 'if b:tskelMini == "'. escape(a:bit, '"') .'" | return "'. escape(expansion, '"') .'" | endif |'
endf

fun! <SID>MiniBits(filename) "{{{3
    let c = <SID>ReadFile(a:filename)
    if c =~ '\S'
        let c1 = substitute("\n". c, "\n\\+\\([^\t\n ]\\+\\)\\([\t ]\\+\\([^\n]\\+\\)\\)\\?", 
                    \ '\=<SID>PrepareMiniBit(submatch(1), submatch(3))', 'g')
        if c1 == c
            echoerr 'Parsing minibits file failed: '. a:filename
            return ''
        end
        return c1
    endif
    return ''
endf

fun! <SID>SavePos() "{{{3
    " return 'norm! '. line('.') .'G'. col('.') .'|'
    return 'call cursor('. line('.') .','. col('.') .')'
endf

fun! <SID>RestorePos(saved) "{{{3
    exec a:saved
endf

fun! <SID>ExpandMiniBit(bit) "{{{3
    if exists('b:tskelMinis')
        let b:tskelMini = a:bit
        let pos = <SID>SavePos()
        try
            exec b:tskelMinis
        finally
            unlet b:tskelMini
            call <SID>RestorePos(pos)
        endtry
    endif
    return ''
endf

" <SID>Collect(array, function, ?first=0, ?sep="\n")
fun! <SID>Collect(array, function, ...) "{{{3
    if a:array !~ '\S'
        return ''
    endif
    let first = a:0 >= 1 ? a:1 : 0
    let sep       = a:0 >= 2 ? a:2 : "\n"
    let seplen = strlen(sep)
    let i  = 0
    let j  = 0
    let rv = ''
    let a  = a:array
    while j != -1
        let j = stridx(a, sep)
        if j == -1
            let t = a
        else
            let t = strpart(a, 0, j)
            let a = strpart(a, j  + seplen)
        endif
        exec 'let v = '. <SID>sprintf1(a:function, escape(t, '\'))
        if first
            if v != ''
                return v
            endif
        else
            if v != ''
                let rv = rv . sep . v
            endif
        endif
    endwh
    return strpart(rv, 1)
endf

fun! <SID>sprintf1(string, arg) "{{{3
    let rv = substitute(a:string, '\C[^%]\zs%s', escape(a:arg, '"\'), 'g')
    let rv = substitute(rv, '%%', '%', 'g')
    return rv
endf

fun! <SID>GetBitGroup(filetype, ...) "{{{3
    let general_first = a:0 >= 1 ? a:1 : 0
    if exists('g:tskelBitGroup_'. a:filetype)
        let rv = g:tskelBitGroup_{a:filetype}
    else
        let rv = a:filetype
    endif
    if general_first
        return "general\n". rv
    else
        return rv ."\ngeneral"
    endif
endf

fun! <SID>PurifyBits(bits) "{{{3
    let rv = substitute("\n". a:bits ."\n", '\n\zs[^[:cntrl:]]\{-}[/.]\([^/.[:cntrl:]]\{-}\)\ze\n', '\1', 'g')
    let rv = DecodeURL(rv)
    return rv
endf

" <SID>PrepareMenu(type, ?menuprefix='')
fun! <SID>PrepareMenu(type, ...) "{{{3
    if g:tskelMenuCache == '' || g:tskelMenuPrefix == ''
        return
    endif
    let menu_file = <SID>GetMenuCacheFilename(a:type)
    if menu_file != ''
        let sub = a:0 >= 1 ? a:1 : ''
        let t = @t
        let tskelMenuPrefix = g:tskelMenuPrefix
        let lazyredraw = &lazyredraw
        let backup     = &backup
        let patchmode  = &patchmode
        let s:tskelSetFiletype = 0
        set lazyredraw
        set nobackup
        set patchmode=
        try
            if sub != ''
                let g:tskelMenuPrefix = g:tskelMenuPrefix .'.'. sub
                let subpriority = 10
            else
                let subpriority = 20
            endif
            let @t = "\n". g:tskelBitFiles_{a:type} ."\n"
            let menu = substitute(@t, '\n\zs\(.\{-}\)\ze\n', '\=<SID>PrepareMenuEntry(submatch(1), '. subpriority .', "n")', 'g')
            let menu = menu ."\n". substitute(@t, '\n\zs\(.\{-}\)\ze\n', '\=<SID>PrepareMenuEntry(submatch(1), '. subpriority .', "i")', 'g')
            let @t = menu
            " echom 'tSkeleton: menu cache: '. menu_file
            " if filereadable(menu_file)
            "     call delete(menu_file)
            " endif
            split
            silent exec 'edit '. menu_file
            if exists('*TSkelMenuCacheEditHook')
                call TSkelMenuCacheEditHook()
            endif
            setlocal bufhidden=hide
            setlocal noswapfile
            setlocal nobuflisted
            setlocal modifiable
            norm! ggdG
            norm! "tp
            silent write!
            if exists('*TSkelMenuCachePostWriteHook')
                call TSkelMenuCachePostWriteHook()
            endif
            wincmd c
        finally
            let @t = t
            let &lazyredraw = lazyredraw
            let &backup     = backup
            let &patchmode  = patchmode
            let s:tskelSetFiletype = 1
            let g:tskelMenuPrefix = tskelMenuPrefix
        endtry
    endif
endf

fun! <SID>GetMenuCacheFilename(type) "{{{3
    if a:type == ''
        return ''
    endif
    let d = g:tskelBitsDir . a:type .'/'
    if !isdirectory(d)
        return ''
    endif
    " return d . g:tskelMenuCache
    return g:tskelDir .'menu/'. a:type
endf

fun! <SID>PrepareMenuEntry(name, subpriority, mode) "{{{3
    if a:name =~ '\S'
        " let item = escape(a:name, '. 	')
        let item = escape(DecodeURL(a:name), ' 	\')
        let bit  = escape(substitute(a:name, '^.\{-}\.\ze[^.]\+$', '', 'g'), '"')
        let spri = stridx(item, '.') >= 0 ? a:subpriority - 1 : a:subpriority
        let pri  = g:tskelMenuPriority .'.'. spri
        if a:mode == 'i'
            return "imenu". pri .' '. g:tskelMenuPrefix .'.'. item .
                        \ ' <c-r>=TSkeletonSetCursorPosition()<cr>'.
                        \ '<c-o>:call TSkeletonExpandBitUnderCursor("i", "'. bit .'")<cr>'
        else
            return  'menu '. pri .' '. g:tskelMenuPrefix .'.'. item .
                        \ ' :call TSkeletonExpandBitUnderCursor("n", "'. bit .'")<cr>'
    else
        return ''
    endif
endf

fun! <SID>BuildBufferMenu() "{{{3
    if !s:tskelProcessing && &filetype != '' && g:tskelMenuCache != '' && g:tskelMenuPrefix != ''
        call <SID>PrepareBits()
        if s:tskelBuiltMenu == 1
            try
                exec 'aunmenu '. g:tskelMenuPrefix
            finally
            endtry
        endif
        let pri = g:tskelMenuPriority .'.'. 5
        exec 'amenu '. pri .' '. g:tskelMenuPrefix .'.Reset :TSkeletonBitReset<cr>'
        exec 'amenu '. pri .' '. g:tskelMenuPrefix .'.-tskel1- :'
        let bg = <SID>GetBitGroup(&filetype, 1)
        call <SID>Collect(bg, "<SID>GetMenuCache(\"%s\")")
        let s:tskelBuiltMenu = 1
    endif
endf

fun! <SID>GetMenuCache(type) "{{{3
    let pg = <SID>GetMenuCacheFilename(a:type)
    if filereadable(pg)
        exec 'source '. pg
    endif
endf

" <SID>PrepareBits(?filetype=&ft, ?reset=0)
fun! <SID>PrepareBits(...) "{{{3
    let filetype = a:0 >= 1 && a:1 != '' ? a:1 : &filetype
    if filetype == ''
        return
    endif
    let bg = <SID>GetBitGroup(filetype)
    let reset = a:0 >= 2 ? a:2 : 0
    let init  = <SID>Collect(bg, "<SID>PrepareBits4Type(\"%s\", 0)") =~ '0'
    let did_maps = 0
    if reset || init
        call <SID>Collect(bg, "<SID>PrepareBits4Type(\"%s\", 1)")
        if reset
            call <SID>Collect(bg, "<SID>PrepareMenu4Type(\"%s\")")
            call <SID>Collect(bg, "<SID>PrepareMap4Type(\"%s\", 1)")
            let did_maps = 1
        endif
    endif
    if !did_maps
        call <SID>Collect(bg, "<SID>PrepareMap4Type(\"%s\", 0)")
    endif
    if reset || !exists('b:tskelMinis')
        let b:tskelMinis = <SID>MiniBits(expand('%:p:h') .'/.tskelmini') .
                    \ <SID>Collect(bg, "<SID>GetMiniBits(\"%s\")")
    endif
    let b:tskelBits = <SID>Collect(bg, "<SID>GetBits4Type(\"%s\")")
    let b:tskelBits = substitute(b:tskelBits, '\n\n\+', '\n', 'g')
    if g:tskelPopupNumbered
        let b:tskelBits = substitute(b:tskelBits, '&', '', 'g')
    endif
endf

fun! <SID>BitsBuilt4Type(type) "{{{3
    return exists('g:tskelBits_'. a:type)
endf

fun! <SID>PrepareConditionEntry(pattern, eligible) "{{{3
    let pattern  = escape(substitute(a:pattern, '%', '%%', 'g'), '"')
    let eligible = escape(a:eligible, '"')
    return 'if search("'. pattern .'%s", "W") | return "'. eligible .'" | endif | '
endf

fun! <SID>ReadFile(filename) "{{{3
    let t = @t
    let processing = <SID>SetProcessing()
    try
        if filereadable(a:filename)
            call <SID>EditScratchBuffer('tmp')
            exec 'silent 0read '. a:filename
            norm! gg"tyG
            wincmd c
            return @t
        endif
    finally
        let @t = t
        call <SID>SetProcessing(processing)
    endtry
    return ''
endf

fun! <SID>PrepareMap4Type(type, anyway) "{{{3
    if !exists('g:tskelBitMap_'. a:type) || a:anyway
        let fn = g:tskelDir .'map/'. a:type
        let c  = <SID>ReadFile(fn)
        if c =~ '\S'
            let c = substitute("\n". c, "\n\\+\\([^\t ]\\+\\)[\t ]\\+\\([^\n]\\+\\)", 
                        \ '\=<SID>PrepareConditionEntry(submatch(1), submatch(2))', 'g')
            let g:tskelBitMap_{a:type} = c
        endif
    endif
endf

fun! <SID>PrepareMenu4Type(type) "{{{3
    if a:type == 'general'
        call <SID>PrepareMenu('general', 'General')
    else
        call <SID>PrepareMenu(a:type)
    endif
endf

fun! <SID>GetBits4Type(type) "{{{3
    return g:tskelBits_{a:type}
endf

fun! <SID>PrepareBits4Type(type, anyway) "{{{3
    let rv = exists('g:tskelBitFiles_'. a:type)
    if !rv || a:anyway
        let g:tskelBitFiles_{a:type} = <SID>GlobBits(g:tskelBitsDir . a:type .'/', 0)
        let g:tskelBits_{a:type}     = <SID>PurifyBits(g:tskelBitFiles_{a:type})
        let g:tskelBitMinis_{a:type} = <SID>MiniBits(g:tskelBitsDir . a:type .'.txt')
    endif
    return rv
endf

fun! <SID>GetMiniBits(type) "{{{3
    if exists('g:tskelBitMinis_'. a:type) && g:tskelBitMinis_{a:type} =~ '\S'
        return ' | '. g:tskelBitMinis_{a:type}
    endif
    return ''
endf

command! TSkeletonBitReset call <SID>PrepareBits('', 1)

fun! <SID>ResetBits() "{{{3
    unlet b:tskelBits
endf

fun! TSkeletonSelectBit(ArgLead, CmdLine, CursorPos) "{{{3
    call <SID>PrepareBits()
    " return b:tskelBits
    return <SID>EligibleBits(&filetype)
endf

fun! <SID>SetLine(mode) "{{{3
    let s:tskelLine = line('.')
    " if <SID>IsInsertMode(a:mode)
    "     if <SID>IsEOL(a:mode)
    "         let s:tskelCol = s:tskelSavedCol
    "     else
    "         let s:tskelCol = s:tskelSavedCol - 1
    "     endif
    " else
    let s:tskelCol  = col('.')
    " endif
endf

fun! <SID>UnsetLine() "{{{3
    let s:tskelLine = 0
    let s:tskelCol  = 0
endf

fun! <SID>GetElibigleBits(type) "{{{3
    let pos  = '\\%'. s:tskelLine .'l\\%'. s:tskelCol .'c'
    let cond = <SID>sprintf1(g:tskelBitMap_{a:type}, pos)
    exec cond
    return ''
endf

fun! <SID>EligibleBits(type) "{{{3
    if s:tskelLine && exists('g:tskelBitMap_'. a:type)
        norm! {
        let eligible = <SID>GetElibigleBits(a:type)
        exec 'norm! '. s:tskelLine .'G'. s:tskelCol .'|'
        if eligible != ''
            let eligible = substitute(eligible, '\s\+', "\n", 'g')
            return "\n". eligible ."\n"
        endif
    endif
    if exists('b:tskelBits')
        return "\n". b:tskelBits ."\n"
    else
        return ''
    endif
endf

fun! <SID>EditScratchBuffer(...) "{{{3
    let idx = a:0 >= 1 ? a:1 : s:tskelScratchIdx
    if exists("s:tskelScratchNr". idx) && s:tskelScratchNr{idx} >= 0
        let tsbnr = bufnr(s:tskelScratchNr{idx})
    else
        let tsbnr = -1
    endif
    if tsbnr >= 0
        silent exec "sbuffer ". tsbnr
    else
        silent split
        silent exec "edit [TSkeletonScratch_". idx ."]"
        let s:tskelScratchNr{idx} = bufnr("%")
    endif
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    silent norm! ggdG
endf

" <SID>RetrieveBit(agent, bit, ?indent, ?filetype) => setCursor?; @t=expanded template bit
fun! <SID>RetrieveBit(agent, bit, ...) "{{{3
    let indent = a:0 >= 1 ? a:1 : ''
    let ft     = a:0 >= 2 ? a:2 : &filetype
    let @t     = ""
    if s:tskelScratchIdx >= g:tskelMaxRecDepth
        return 0
    endif
    let cpoptions = &cpoptions
    if s:tskelScratchIdx == 0
        let s:tskelDestBufNr = bufnr("%")
    endif
    let s:tskelScratchIdx = s:tskelScratchIdx + 1
    if s:tskelScratchIdx > s:tskelScratchMax
        let s:tskelScratchMax = s:tskelScratchIdx
        let s:tskelScratchNr{s:tskelScratchIdx} = -1
    endif
    let setCursor  = 0
    let processing = <SID>SetProcessing()
    try
        call <SID>EditScratchBuffer()
        let b:tskelFiletype = ft
        if ft != ""
            call <SID>PrepareBits(ft)
        endif
        set cpoptions-=a
        call <SID>RetrieveAgent_{a:agent}(a:bit)
        call <SID>IndentLines(1, line("$"), indent)
        silent norm! gg
        call TSkeletonFillIn(1, ft)
        let setCursor = <SID>SetCursor('%', '', '', 1)
        silent norm! ggvGk$"ty
    finally
        call <SID>SetProcessing(processing)
        let &cpoptions = cpoptions
        wincmd c
        let s:tskelScratchIdx = s:tskelScratchIdx - 1
        if s:tskelScratchIdx == 0
            silent exec "buffer ". s:tskelDestBufNr
            let s:tskelDestBufNr = -1
        else
            silent exec "buffer ". s:tskelScratchNr{s:tskelScratchIdx}
        endif
    endtry
    return setCursor
endf

fun! <SID>SetProcessing(...) "{{{3
    if a:0 >= 1
        let s:tskelProcessing = a:1
        return a:1
    else
        let rv = s:tskelProcessing
        let s:tskelProcessing = 1
        return rv
    endif
endf

fun! <SID>RetrieveAgent_read(bit) "{{{3
    silent exec "0read ". escape(a:bit, '\#%')
endf

fun! <SID>RetrieveAgent_text(bit) "{{{3
    let t = @t
    try
        let @t = a:bit
        silent 0put t
    finally
        let @t = t
    endtry
endf

fun! TSkeletonGetBit(bit) "{{{3
    let t = @t
    try
        let ft = exists('b:tskelFiletype') ? b:tskelFiletype : &filetype
        let bf = <SID>SelectBit(a:bit, ft)
        if bf != ''
            let sc = <SID>RetrieveBit('read', bf, '', ft)
            return @t
        endif
    finally
        let @t = t
    endtry
    return ''
endf

fun! <SID>InsertBit(agent, bit, mode) "{{{3
    set cpoptions-=a
    let t = @t
    try
        let c  = col(".")
        let e  = col("$")
        let l  = line(".")
        let li = getline(l)
        " Adjust for vim idiosyncrasy
        if c == e - 1 && li[c - 1] == " "
            let e = e - 1
        endif
        let i = <SID>GetIndent(li)
        let setCursor = <SID>RetrieveBit(a:agent, a:bit, i)
        exec 'silent norm! '. c .'|'
        call <SID>InsertTReg(a:mode)
        if setCursor
            let ll = l + setCursor - 1
            call <SID>SetCursor(l, ll, a:mode)
        endif
    finally
        let @t = t
    endtry
endf

fun! <SID>InsertTReg(mode) "{{{3
    if <SID>IsEOL(a:mode)
    " if <SID>IsInsertMode(a:mode) && !<SID>IsEOL(a:mode)
        silent norm! "tgp
    else
        silent norm! "tgP
    end
endf

fun! <SID>GetIndent(line) "{{{3
    return matchstr(a:line, '^\(\s*\)')
endf

fun! <SID>IndentLines(from, to, indent) "{{{3
    silent exec a:from.",".a:to.'s/\(^\|\n\)/\1'. escape(a:indent, '/\') .'/g'
endf

fun! <SID>CharRx(char) "{{{3
    let rv = '&\?'
    if a:char == '\\'
        return rv .'\('. EncodeChar('\') .'\|\\\)'
    elseif a:char =~ '[/*#<>|:"?{}~]'
        return rv .'\('. EncodeChar(a:char) .'\|'. a:char .'\)'
    else
        return rv . a:char
    endif
endf

fun! <SID>BitRx(bit, escapebs) "{{{3
    let rv = substitute(escape(a:bit, '\'), '\(\\\\\|.\)', '\=<SID>CharRx(submatch(1))', 'g')
    return rv
endf

fun! <SID>SelectBitForMode(type, bit) "{{{3
    if a:type == '' || a:bit == ''
        return 0
    else
        let ffbits = "\n". g:tskelBitFiles_{a:type} ."\n"
        let bit    = <SID>BitRx(a:bit, 0)
        " echom "DBG ffbits=". ffbits
        " echom "DBG bit=". bit
        if ffbits =~ '\V\n\(\.\{-}.\)\?'. bit .'\n'
            let ffbit  = substitute(ffbits, '\V\.\{-}\n\(\(\[^[:cntrl:]]\{-}.\)\?'. bit .'\)\n\.\*', '\1', '')
            " echom "DBG ffbit=". ffbit
            if ffbits != ffbit
                " echom "DBG bitfile=". g:tskelBitsDir . a:type ."/". ffbit
                return g:tskelBitsDir . a:type ."/". ffbit
            endif
        endif
        return ""
    endif
endf

fun! <SID>SelectBit(bit, ...) "{{{3
    let ft = a:0 >= 1 ? a:1 : &filetype
    let bg = <SID>GetBitGroup(ft)
    let bf = <SID>Collect(bg, "<SID>SelectBitForMode(\"%s\", '". a:bit ."')", 1)
    return bf
endf

fun! <SID>SelectAndInsert(bit, mode) "{{{3
    let mb = <SID>ExpandMiniBit(a:bit)
    if mb != ''
        call <SID>InsertBit('text', mb, a:mode)
        return 1
    endif
    let bf = <SID>SelectBit(a:bit)
    if bf != ""
        let mv = <SID>GetVarName('msg', 2)
        call <SID>InsertBit('read', bf, a:mode)
        if exists(mv)
            exec 'echo '. mv
            exec 'unlet! '. mv
        endif
        return 1
    endif
    return 0
endf

" TSkeletonBit(bit, ?mode='n')
fun! TSkeletonBit(bit, ...) "{{{3
    let mode = a:0 >= 1 ? a:1 : 'n'
    let processing = <SID>SetProcessing()
    call genutils#SaveWindowSettings2('tSkeleton', 1)
    try
        if <SID>SelectAndInsert(a:bit, mode)
            return 1
        else
            " echom "TSkeletonBit: Unknown bit '". a:bit ."'"
            if <SID>IsPopup(mode)
                let t = @t
                try
                    let @t = a:bit
                    call <SID>InsertTReg(mode)
                    return 1
                finally
                    let @t = t
                endtry
            endif
            return 0
        endif
        " catch
        "     echom "An error occurred in TSkeletonBit() ... ignored"
    finally
        call genutils#RestoreWindowSettings2('tSkeleton')
        call <SID>SetProcessing(processing)
    endtry
endf

command! -nargs=1 -complete=custom,TSkeletonSelectBit TSkeletonBit
            \ call TSkeletonBit(<q-args>)

if !hasmapto("TSkeletonBit") "{{{2
    " noremap <unique> <Leader>tt ""diw:TSkeletonBit <c-r>"
    exec "noremap <unique> ". g:tskelMapLeader ."t :TSkeletonBit "
endif

fun! <SID>IsInsertMode(mode) "{{{3
    return a:mode =~? 'i'
endf

fun! <SID>IsEOL(mode) "{{{3
    return a:mode =~? '1'
endf

fun! <SID>IsPopup(mode) "{{{3
    return a:mode =~? 'p'
endf

fun! <SID>BitMenu(bit, mode, ft) "{{{3
    if has("menu") && g:tskelQueryType == 'popup'
        return <SID>BitMenu_menu(a:bit, a:mode, a:ft)
    else
        return <SID>BitMenu_query(a:bit, a:mode, a:ft)
    endif
endf

fun! <SID>BitMenuEligible(agent, bit, mode, ft) "{{{3
    call <SID>SetLine(a:mode)
    let t = <SID>EligibleBits(a:ft)
    let s:tskelMenuEligibleIdx = 0
    let s:tskelMenuEligibleRx  = '^'. <SID>BitRx(a:bit, 0)
    let e = <SID>Collect(t, "<SID>BitMenuEligible_". a:agent ."_cb(\"%s\", \"". a:mode ."\")")
    return e
endf

fun! <SID>BitMenu_query(bit, mode, ft) "{{{3
    let s:tskelQueryN   = 0
    let s:tskelQueryAcc = <SID>BitMenuEligible('query', a:bit, a:mode, a:ft)
    if s:tskelQueryAcc <= 1
        let rv = s:tskelQueryAcc
    else
        let qu = "s:tskelQueryAcc|Select bit:"
        let rv = <SID>Query(qu)
    endif
    if rv != ''
        call TSkeletonBit(rv, a:mode .'p')
        return 1
    endif
    return 0
endf

fun! <SID>BitMenuEligible_query_cb(bit, mode) "{{{3
    if a:bit =~ '\S' && a:bit =~ s:tskelMenuEligibleRx
        let s:tskelQueryN = s:tskelQueryN + 1
        return escape(DecodeURL(a:bit), '"\ 	')
    endif
    return ''
endf

fun! <SID>BitMenu_menu(bit, mode, ft) "{{{3
    try
        silent aunmenu ]TSkeleton
    catch
    endtry
    let rv = <SID>BitMenuEligible('menu', a:bit, a:mode, a:ft)
    let j  = strlen(rv)
    if j == 1
        exec s:tskelMenuEligibleEntry
        return 1
    elseif j > 0
        popup ]TSkeleton
        return 1
    endif
    return 0
endf

fun! <SID>BitMenuEligible_menu_cb(bit, mode) "{{{3
    if a:bit =~ '\S' && a:bit =~ s:tskelMenuEligibleRx
        let s:tskelMenuEligibleIdx = s:tskelMenuEligibleIdx + 1
        if stridx(a:bit, '&') == -1
            let x = substitute(s:tskelMenuEligibleIdx, '\(.\)$', '\&\1', '')
        else
            let x = s:tskelMenuEligibleIdx
        end
        let i = escape(DecodeURL(a:bit), '"\ 	')
        let s:tskelMenuEligibleEntry = 'call TSkeletonBit("'. i .'", "'. a:mode .'p")'
        exec 'amenu ]TSkeleton.'. x .'\ '. i .' :'. s:tskelMenuEligibleEntry .'<cr>'
        return 1
    endif
    return ''
endf

" TSkeletonExpandBitUnderCursor(mode, ?bit)
fun! TSkeletonExpandBitUnderCursor(mode, ...) "{{{3
    call <SID>PrepareBits()
    let t = @t
    let lazyredraw = &lazyredraw
    set lazyredraw
    try
        let @t    = ""
        let ft    = &filetype
        let imode = <SID>IsInsertMode(a:mode)
        let l     = getline('.')
        if imode
            if s:tskelSavedCol >= col('$')
                let col = s:tskelSavedCol
                let eol_adjustment = 1
            else
                let col = s:tskelSavedCol - 1
                let eol_adjustment = 0
            endif
        else
            let col = col('.')
            let eol_adjustment = (col + 1 >= col('$'))
        endif
        let mode  = a:mode . eol_adjustment
        if a:0 >= 1
            let @t = a:1
        else
            let c = l[col - 1]
            let pos = '\%#'
            if c =~ '\s'
                let @t = ''
                " echom "DBG 0 @t=". @t
                if !imode && !eol_adjustment
                    norm! l
                endif
            elseif exists('g:tskelKeyword_'. ft) && search(g:tskelKeyword_{ft} . pos) != -1
                if imode && eol_adjustment
                    let d = col - col('.')
                else
                    let d = col - col('.') + 1
                endif
                exec 'silent norm! "td'. d .'l'
                " echom "DBG 1 @t='". @t ."'"
            elseif imode && !eol_adjustment
                silent norm! h"tdiw
                " echom "DBG 2 @t='". @t ."'"
            else
                silent norm! "tdiw
                " echom "DBG 3 @t='". @t ."'"
            endif
        endif
        let bit = @t
        if bit =~ '^\s\+$'
            let bit = ''
        endif
        " echom "DBG 4 bit='". bit ."'"
        if bit != '' && TSkeletonBit(bit, mode) == 1
            return 1
        elseif <SID>BitMenu(bit, mode, ft)
            return 0
        endif
        " silent norm! u
        let @t = bit
        call <SID>InsertTReg(mode)
        echom "TSkeletonBit: Unknown bit '". bit ."'"
        return 0
    finally
        let @t = t
        call <SID>UnsetLine()
        let lazyredraw  = &lazyredraw
    endtry
endf

fun! TSkeletonSetCursorPosition() "{{{3
    let s:tskelSavedCol = col('.')
    return ''
endf

if !hasmapto("TSkeletonExpandBitUnderCursor") "{{{2
    exec "nnoremap <unique> ". g:tskelMapLeader ."# :call TSkeletonExpandBitUnderCursor('n')<cr>"
    exec "inoremap <unique> ". g:tskelMapInsert ." <c-r>=TSkeletonSetCursorPosition()<cr><c-o>:call TSkeletonExpandBitUnderCursor('i')<cr>"
endif


fun! TSkeletonGoToNextTag() "{{{3
    let rx = '\(???\|+++\|###\|<+.\{-}+>\)'
    let x  = search(rx)
    if x > 0
        let ll = exists('b:tskelLastLine') ? b:tskelLastLine : 0
        let lc = exists('b:tskelLastCol')  ? b:tskelLastCol  : 0
        let l  = strpart(getline(x), lc)
        let ms = matchstr(l, rx)
        let mb = match(l, rx) + lc + 1
        let me = matchend(l, rx) + lc - mb + 1
        if ms == '???' || ms == '+++' || ms == '###'
            exec 'norm! v'. me .'l'
        else
            let mb = match(l, rx) + lc + 1
            let me = matchend(l, rx) + lc - mb + 1
            " let lp = substitute(strpart(l, 2, me - 4), '\W', '_', 'g')
            " if exists('*TSkeletonCB_'. lp)
            "     let v = TSkeletonCB_{lp}()
            "     if v != ''
            "         exec 'norm! d'. me .'li'. v
            "         return
            "     endif
            " endif
            if me == 4
                exec 'norm! d'. me .'l'
            else
                exec 'norm! v'. me .'l'
            endif
        endif
    endif
endf

fun! TSkeletonMapGoToNextTag() "{{{3
    noremap <c-j> :call TSkeletonGoToNextTag()<cr>
    vnoremap <c-j> <C-\><C-N>:call TSkeletonGoToNextTag()<cr>
    inoremap <c-j> <c-o>:call TSkeletonGoToNextTag()<cr>
endf

fun! TSkeletonLateExpand() "{{{3
    let rx = '<+.\{-}+>'
    let l  = getline('.')
    let lc = col('.') - 1
    while strpart(l, lc, 2) != '<+'
        let lc = lc - 1
        if lc <= 0 || strpart(l, lc - 1, 2) == '+>'
            throw "TSkeleton: No tag under cursor"
        endif
    endwh
    let l  = strpart(l, lc)
    let me = matchend(l, rx)
    if me < 0
        throw "TSkeleton: No tag under cursor"
    else
        let lp = substitute(strpart(l, 2, me - 4), '\W', '_', 'g')
        if exists('*TSkeletonCB_'. lp)
            let v = TSkeletonCB_{lp}()
            if v != ''
                exec 'norm! '. (lc + 1) .'|d'. me .'li'. v
                return
            endif
        else
            throw 'TSkeleton: No callback defined for '. lp .' (TSkeletonCB_'. lp .')'
        endif
    endif
endf

if !hasmapto("TSkeletonLateExpand()") "{{{2
    exec "nnoremap <unique> ". g:tskelMapLeader ."x :call TSkeletonLateExpand()<cr>"
    exec "vnoremap <unique> ". g:tskelMapLeader ."x <esc>`<:call TSkeletonLateExpand()<cr>"
endif


" misc utilities {{{1
fun! TSkeletonIncreaseRevisionNumber() "{{{3
    let rev = exists("b:revisionRx") ? b:revisionRx : g:tskelRevisionMarkerRx
    let ver = exists("b:versionRx")  ? b:versionRx  : g:tskelRevisionVerRx
    normal m`
    exe '%s/'.rev.'\('.ver.'\)*\zs\(-\?\d\+\)/\=(submatch(g:tskelRevisionGrpIdx) + 1)/e'
    normal ``
endfun

" fun! ToirtoiseSvnLogMsg() "{{{3
"     let rev = exists("b:revisionRx") ? b:revisionRx : g:tskelRevisionMarkerRx
"     let ver = exists("b:versionRx")  ? b:versionRx  : g:tskelRevisionVerRx
"     normal m`
"     let rv = ''
"     exe '%g/'.rev.'\(\('.ver.'\)*-\?\d\+\)/let rv=getline(".")'
"     normal ``
"     return rv
" endf

" autocmd BufWritePre * call TSkeletonIncreaseRevisionNumber()

fun! TSkeletonCleanUpBibEntry() "{{{3
    '{,'}s/^.*<+.\{-}+>.*\n//e
    if exists('*TSkeletonCleanUpBibEntry_User')
        call TSkeletonCleanUpBibEntry_User()
    endif
endf
command! TSkeletonCleanUpBibEntry call TSkeletonCleanUpBibEntry()

" TSkeletonRepeat(n, string, ?sep="\n")
fun! TSkeletonRepeat(n, string, ...) "{{{3
    let sep = a:0 >= 1 ? a:1 : "\n"
    let rv  = a:string
    let n   = a:n - 1
    while n > 0
        let rv = rv . sep . a:string
        let n  = n - 1
    endwh
    return rv
endf

fun! TSkeletonInsertTable(rows, cols, rowbeg, rowend, celljoin) "{{{3
    let y = a:rows
    let r = ''
    while y > 0
        let x = a:cols
        let r = r . a:rowbeg
        while x > 0
            if x == a:cols
                let r = r .'<+CELL+>'
            else
                let r = r . a:celljoin .'<+CELL+>'
            end
            let x = x - 1
        endwh
        let r = r. a:rowend
        if y > 1
            let r = r ."\n"
        endif
        let y = y - 1
    endwh
    return r
endf

fun! <SID>DefineAutoCmd(template)
    let sfx = fnamemodify(a:template, ':e')
    let tpl = fnamemodify(a:template, ':t')
    exec 'autocmd BufNewFile *.'. sfx .' TSkeletonSetup '. tpl
endf

if !s:tskelDidSetup "{{{2
    augroup tSkeleton
        autocmd!
        if !exists("g:tskelDontSetup") "{{{2
            autocmd BufNewFile *.bat       TSkeletonSetup batch.bat
            autocmd BufNewFile *.tex       TSkeletonSetup latex.tex
            autocmd BufNewFile tc-*.rb     TSkeletonSetup tc-ruby.rb
            autocmd BufNewFile *.rb        TSkeletonSetup ruby.rb
            autocmd BufNewFile *.rbx       TSkeletonSetup ruby.rb
            autocmd BufNewFile *.sh        TSkeletonSetup shell.sh
            autocmd BufNewFile *.txt       TSkeletonSetup text.txt
            autocmd BufNewFile *.vim       TSkeletonSetup plugin.vim
            "autocmd BufNewFile *.inc.php   TSkeletonSetup php.inc.php
            "autocmd BufNewFile *.class.php TSkeletonSetup php.class.php
            "autocmd BufNewFile *.php       TSkeletonSetup php.php
            autocmd BufNewFile *.tpl       TSkeletonSetup smarty.tpl
            autocmd BufNewFile *.html      TSkeletonSetup html.html
            let autotemplates = glob(g:tskelDir.'*#*')
            call <SID>Collect(autotemplates, "<SID>DefineAutoCmd(\"%s\")")
        endif

        autocmd BufNewFile,BufRead */skeletons/* if s:tskelSetFiletype | setf tskeleton | endif
        autocmd BufEnter * if (g:tskelMenuCache != '') | call <SID>BuildBufferMenu() | endif
        
        autocmd FileType bib if !hasmapto(":TSkeletonCleanUpBibEntry") | exec "noremap <buffer> ". g:tskelMapLeader ."c :TSkeletonCleanUpBibEntry<cr>" | endif
    augroup END
                
    let s:tskelDidSetup = 1
endif

finish
-------------------------------------------------------------------
" 1.0
" - Initial release
" 
" 1.1
" - User-defined tags
" - Modifiers <+NAME:MODIFIERS+> (c=capitalize, u=toupper, l=tolower, 
"   s//=substitute)
" - Skeleton bits
" - the default markup for tags has changed to <+TAG+> (for 
"   "compatibility" with imaps.vim), the cursor position is marked as 
"   <+CURSOR+> (but this can be changed by setting g:tskelPatternLeft, 
"   g:tskelPatternRight, and g:tskelPatternCursor)
" - in the not so simple mode, skeleton bits can contain vim code that 
"   is evaluated after expanding the template tags (see 
"   .../skeletons/bits/vim/if for an example)
" - function TSkeletonExpandBitUnderCursor(), which is mapped to 
"   <Leader>#
" - utility function: TSkeletonIncreaseRevisionNumber()
" 
" 1.2
" - new pseudo tags: bit (recursive code skeletons), call (insert 
"   function result)
" - before & after sections in bit definitions may contain function 
"   definitions
" - fixed: no bit name given in <SID>SelectBit()
" - don't use ={motion} to indent text, but simply shift it
" 
" 1.3
" - TSkeletonCleanUpBibEntry (mapped to <Leader>tc for bib files)
" - complete set of bibtex entries
" - fixed problem with [&bg]: tags
" - fixed typo that caused some slowdown
" - other bug fixes
" - a query must be enclosed in question marks as in <+?Which ID?+>
" - the "test_tSkeleton" skeleton can be used to test if tSkeleton is 
"   working
" - and: after/before blocks must not contain function definitions
" 
" 1.4
" - Popup menu with possible completions if 
"   TSkeletonExpandBitUnderCursor() is called for an unknown code 
"   skeleton (if there is only one possible completion, this one is 
"   automatically selected)
" - Make sure not to change the alternate file and not to distort the 
"   window layout
" - require genutils
" - Syntax highlighting for code skeletons
" - Skeleton bits can now be expanded anywhere in the line. This makes 
"   it possible to sensibly use small bits like date or time.
" - Minor adjustments
" - g:tskelMapLeader for easy customization of key mapping (changed the 
"   map leader to "<Leader>#" in order to avoid a conflict with Align; 
"   set g:tskelMapLeader to "<Leader>t" to get the old mappings)
" - Utility function: TSkeletonGoToNextTag(); imaps.vim like key 
"   bindings via TSkeletonMapGoToNextTag()
" 
" 1.5
" - Menu of small skeleton "bits"
" - TSkeletonLateExpand() (mapped to <Leader>#x)
" - Disabled <Leader># mapping (use it as a prefix only)
" - Fixed copy & paste error (loaded_genutils)
" - g:tskelDir defaults to $HOME ."/vimfiles/skeletons/" on Win32
" - Some speed-up
" 
" 2.0
" - You can define "groups of bits" (e.g. in php mode, all html bits are 
"   available too)
" - context sensitive expansions (only very few examples yet); this 
"   causes some slowdown; if it is too slow, delete the files in 
"   .vim/skeletons/map/
" - one-line "mini bits" defined in either 
"   ./vim/skeletons/bits/{&filetype}.txt or in $PWD/.tskelmini
" - Added a few LaTeX, HTML and many Viki skeleton bits
" - Added EncodeURL.vim
" - Hierarchical bits menu by calling a bit "SUBMENU.BITNAME" (the 
"   "namespace" is flat though; the prefix has no effect on the bit 
"   name; see the "bib" directory for an example)
" - the bit file may have an ampersand (&) in their names to define the 
"   keyboard shortcut
" - Some special characters in bit names may be encoded as hex (%XX as 
"   in URLs)
" - Insert mode: map g:tskelMapInsert ('<c-\><c-\>', which happens to be 
"   the <c-#> key on a German qwertz keyboard) to 
"   TSkeletonExpandBitUnderCursor()
" - New <tskel:msg> tag in skeleton bits
" - g:tskelKeyword_{&filetype} variable to define keywords by regexp 
"   (when 'iskeyword' isn't flexible enough)
" - removed the g:tskelSimpleBits option
" - Fixed some problems with the menu
" - Less use of globpath()
" 
" 2.1
" - Don't accidentally remove torn off menus; rebuild the menu less 
"   often
" - Maintain insert mode (don't switch back to normal mode) in 
"   <c-\><c-\> imap
" - If no menu support is available, use the <SID>Query function to let 
"   the user select among eligible bits (see also g:tskelQueryType)
" - Create a normal and an insert mode menu
" - Fixed selection of eligible bits
" - Ensure that g:tskelDir ends with a (back)slash
" - Search for 'skeletons/' in &runtimepath & set g:tskelDir accordingly
" - If a template is named "#.suffix", an autocmd is created  
"   automatically.
" - Set g:tskelQueryType to 'popup' only if gui is win32 or gtk.
" - Minor tweak for vim 7.0 compatibility
" 
" 2.2
" - Don't display query menu, when there is only one eligible bit
" - EncodeURL.vim now correctly en/decoded urls
" - UTF8 compatibility -- use col() instead of virtcol() (thanks to Elliot 
"   Shank)
"
