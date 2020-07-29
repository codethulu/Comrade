"=============================================================================
" AUTHOR:  beeender <chenmulong at gmail.com>
" License: GPLv3
"=============================================================================

" Called by JetBrains to set the code insight result.
" insight_map format:
" { start_line_number :
"   [
"     {id: , s_line: , e_line: , s_col: , e_col: , severity: , desc: }
"     {id: , s_line: , e_line: , s_col: , e_col: , severity: , desc: }
"   ]
" }
" Line number is 0 based.
function! comrade#SetInsights(channel, buf, insight_map)
    let l:channel = comrade#bvar#get(a:buf, 'channel')
    if l:channel == a:channel
        call comrade#bvar#set(a:buf, 'insight_map', a:insight_map)
        call comrade#sign#SetSigns(a:buf)
        call comrade#highlight#SetHighlights(a:buf)

        call comrade#SetQFs(a:buf)
    endif
endfunction

function! comrade#SetQFs(buffer) abort
    let l:results = []

    let l:insight_map = comrade#bvar#get(a:buffer, 'insight_map')
    if empty(l:insight_map)
        let l:insight_map = {}
    endif

    for l:line in keys(l:insight_map)
        for l:insight in l:insight_map[l:line]
            if strlen(l:insight['desc']) > 0
                if l:insight['severity'] >= 400
                    let l:severity = 'E'
                elseif l:insight['severity'] >= 300
                    let l:severity = 'W'
                else
                    let l:severity = 'I'
                endif

                let l:entry = {'bufnr': a:buffer, 'lnum': l:insight['s_line'] + 1, 'col': l:insight['s_col'] + 1, 'type': l:severity, 'text': l:insight['desc']}
                call add(l:results, l:entry)
            endif
        endfor
    endfor

    call setloclist(bufwinnr(a:buffer), l:results, 'r')
endfunction

" Called by python when deoplete wants do completion.
function! comrade#RequestCompletion(buf, param)
    if comrade#bvar#has(a:buf, 'channel')
        try
            let result = call('rpcrequest', [comrade#bvar#get(a:buf, 'channel'), 'comrade_complete', a:param])
            return result
        catch /./ " The channel has been probably closed
            call comrade#util#TruncatedEcho('Failed to send completion request to JetBrains instance. \n' . v:exception)
            call comrade#bvar#remove(a:buf, 'channel')
        endtry
    endif
    return []
endfunction

function! comrade#RequestQuickFix(buf, insight, fix) abort
    if comrade#bvar#has(a:buf, 'channel')
        try
            let result = call('rpcrequest', [comrade#bvar#get(a:buf, 'channel'), 'comrade_quick_fix',
                        \ {'buf' : a:buf, 'insight' : a:insight, 'fix' : a:fix}])
            if !empty(result)
                call comrade#util#TruncatedEcho(result)
            endif
        catch /./ " The channel has been probably closed
            call comrade#util#TruncatedEcho('Failed to send completion request to JetBrains instance. \n' . v:exception)
            call comrade#bvar#remove(a:buf, 'channel')
        endtry
    endif
    return []
endfunction
