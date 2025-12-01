vim.cmd [==[

" silent! is added so that mappings do not abort

function! PrintError(msg) abort
    execute 'normal! \<Esc>'
    echohl ErrorMsg
    echomsg a:msg
    echohl None
endfunction

" https://gist.github.com/statox/5b79f7e72ca650ed0a26ae1bdfea35eb
function! SetVisualSelect(start, end)
    execute "silent! normal! \v\<Esc>"
    if &selection == 'exclusive'
        let a:end[1] += 1
    endif
    call setpos("'<", [ 0, a:start[0], a:start[1] ])
    call setpos("'>", [ 0, a:end[0], a:end[1] ])
    norm! gv
endfunction
function! SetVisualLines(start, end)
    execute "silent! normal! \V\<Esc>"
    call setpos("'<", [0, a:start[0], a:start[1]])
    call setpos("'>", [0, a:end[0], a:end[1]])
    norm! gv
endfunction

" doesn't consider string literals
"
" direction = 0, start from beginning of the line
" direction = 1, search forward
" direction = 2, search backwards
fun! SelectVariableValue(direction)
    let startL = line('.')
    let searchPattern = '\M\(=\@<!==\@!\|:\@<!::\@!\)'
    if !a:direction
        call cursor(startL, 1)
        keepjumps let lin = search(searchPattern, 'Wc', startL)
    else
        let [forwFlags, backFlags] = (a:direction == 1 ? ['Wc', 'Wcb'] : ['Wcb', 'Wc'])
        keepjumps let lin = search(searchPattern, forwFlags, startL)
        if !lin | keepjumps let lin = search(searchPattern, backFlags, startL) | endif
    endif
    if !lin | call PrintError('Could not find variable declaration') | return | endif

    keepjumps let selectStart = searchpos('\M\S', 'Ws')
    let [skipCur, curL, curC] = [v:false, line('.'), col('.')]
    while v:true
        keepjumps let [curL, curC] = searchpos('\M\((\|{\|[\|;\|,\)', (skipCur ? 'W' : 'Wc'), line('.'))
        if !curL | let [curL, curC] = [line('.'), strlen(getline('.'))] | break | endif
        let curChar = nr2char(strgetchar(getline(curL)[curC - 1:], 0))
        if curChar == '(' || curChar == '{' || curChar == '['
            keepjumps silent! normal! %
            let skipCur = curL == line('.') && curC == col('.')
        else | let curC = curC-1 | break | endif
    endwhile
    call SetVisualSelect(selectStart, [curL, curC])
endfun

fun! ExecDelLines(dir)
    let startPos = [line('.'), col('.')]
    let saveView = winsaveview()
    call SelectVariableValue(a:dir)
    let endPos = [line('.'), col('.')]
    silent! normal! d
    call winrestview(saveView)
    call SetVisualLines(startPos, [line('.'), col('.')])
    silent! normal! "_dd
endfun
]==]
