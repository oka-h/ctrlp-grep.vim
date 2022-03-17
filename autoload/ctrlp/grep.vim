if get(g:, 'loaded_ctrlp_grep')
    finish
endif

let g:loaded_ctrlp_grep = 1

if !exists('g:ctrlp_ext_vars')
    let g:ctrlp_ext_vars = []
endif

call add(g:ctrlp_ext_vars, {
\   'init' : 'ctrlp#grep#init()',
\   'accept' : 'ctrlp#grep#accept',
\   'lname' : 'grep',
\   'sname' : 'grep',
\   'type' : 'line',
\   'specinput' : 1
\})

function! ctrlp#grep#run(...) abort
    let l:grep_item = s:get_grep_item()

    if empty(l:grep_item)
        call s:echo_warning('"g:ctrlpgrep_cmd" に正しい値が設定されていません。')
        return
    endif

    if !l:grep_item['executable']()
        call s:echo_warning(printf('コマンド "%s" は実行できません。', g:ctrlpgrep_cmd))
        return
    endif

    let l:option = {}

    if a:0 > 0
        let l:option['dir'] = expand(a:1)

        if !isdirectory(l:option['dir'])
            call s:echo_warning(printf('ディレクトリ "%s" は存在しません。', a:1))
            return
        endif
    endif

    let s:pattern = input('pattern:')

    if empty(s:pattern)
        return
    endif

    let s:extensions_option = s:get_extensions_option(a:000[1:])

    call ctrlp#init(ctrlp#grep#id(), l:option)
endfunction

function! s:get_grep_item() abort
    return get(s:grep_item, tolower(get(g:, 'ctrlpgrep_cmd')), {})
endfunction

function! s:echo_warning(message) abort
    redraw
    echohl WarningMsg
    echo a:message
    echohl None
endfunction

function! s:get_extensions_option(input_extensions) abort
    if !empty(a:input_extensions)
        return {
        \   'include' : a:input_extensions[0] !~# '^-',
        \   'extensions' : split(join(a:input_extensions, ','), '[^0-9A-Za-z]\+')
        \}
    endif

    let l:include_extensions = get(g:, 'ctrlpgrep_default_include_extensions', '')

    if !empty(l:include_extensions)
        let l:result = { 'include' : 1 }

        if type(l:include_extensions) == v:t_string
            let l:result['extensions'] = split(l:include_extensions, '[^0-9A-Za-z]\+')
        elseif type(l:include_extensions) == v:t_list
            let l:result['extensions'] = copy(l:include_extensions)
        else
            let l:result['extensions'] = []
        endif

        return l:result
    endif

    let l:exclude_extensions = get(g:, 'ctrlpgrep_default_exclude_extensions', '')

    if !empty(l:exclude_extensions)
        let l:result = { 'include' : 0 }

        if type(l:exclude_extensions) == v:t_string
            let l:result['extensions'] = split(l:exclude_extensions, '[^0-9A-Za-z]\+')
        elseif type(l:exclude_extensions) == v:t_list
            let l:result['extensions'] = copy(l:exclude_extensions)
        else
            let l:result['extensions'] = []
        endif

        return l:result
    endif

    return {
    \   'include' : 0,
    \   'extensions' : []
    \}
endfunction

let s:id = ctrlp#getvar('g:ctrlp_builtins') + len(g:ctrlp_ext_vars)

function! ctrlp#grep#id() abort
    return s:id
endfunction

function! ctrlp#grep#init() abort
    call s:syntax()
    let l:result = s:get_grep_item()['cmd'](s:pattern, s:extensions_option['include'], s:extensions_option['extensions'])
    
    if type(l:result) == v:t_string
        return split(l:result, "\n")
    elseif type(l:result) == v:t_list
        return l:result
    else
        call s:echo_warning('コマンド関数の返り値は文字列またはリストである必要があります。')
        return
    endif
endfunction

function! s:syntax() abort
    if ctrlp#nosy() || !get(g:, 'ctrlpgrep_highlight_enable')
        return
    endif

    call ctrlp#hicheck('CtrlPGrep', 'Search')

    try
        execute printf('syntax match CtrlPGrep /%s/', escape(s:pattern, '/'))
    catch
    endtry
endfunction

function! ctrlp#grep#accept(mode, str) abort
    call ctrlp#exit()
    let l:result = s:get_grep_item()['parse'](a:str)

    if type(l:result) != v:t_dict
        call s:echo_warning('解析関数の返り値は辞書である必要があります。')
        return
    endif

    if !has_key(l:result, 'file')
        call s:echo_warning('解析関数が返す辞書は "file" をキーに持つ必要があります。')
        return
    endif

    let l:file = l:result['file']

    if type(l:file) != v:t_string || empty(l:file)
        call s:echo_warning('ファイルには空ではない文字列を指定する必要があります。')
        return
    endif

    call ctrlp#acceptfile(a:mode, l:file)
    
    if has_key(l:result, 'line')
        call setpos('.', [0, l:result['line'], get(l:result, 'col', 0), 0])
    endif
endfunction

function! s:grep_cmd(pattern, include_extensions, extensions) abort
    let l:extensions_args = join(map(a:extensions,
    \   printf('printf(''--%s="*.%%s"'', v:val)', a:include_extensions ? 'include' : 'exclude')))
    return map(systemlist(printf('grep -inrs --color=never %s %s %s',
    \   l:extensions_args, s:escape_for_grep(a:pattern), shellescape(getcwd()))), 'trim(v:val)')
endfunction

function! s:ag_cmd(pattern, include_extensions, extensions) abort
    if empty(a:extensions)
        let l:extensions_args = ''
    elseif a:include_extensions
        let l:extensions_args = printf('-G "\.(%s)"', join(a:extensions, '|'))
    else
        let l:extensions_args = join(map(a:extensions, 'printf(''--ignore="*.%s"'', v:val)'))
    endif

    return map(systemlist(printf('ag --nocolor --column --nogroup --silent -S %s %s %s',
    \   l:extensions_args, s:escape_for_grep(a:pattern), shellescape(getcwd()))), 'trim(v:val)')
endfunction

function! s:rg_cmd(pattern, include_extensions, extensions) abort
    let l:extensions_args = empty(a:extensions) ? '' :
    \   printf('--type-add "ctrlpgrep:*.{%s}" -%sctrlpgrep', join(a:extensions, ','), a:include_extensions ? 't' : 'T')
    return map(systemlist(printf('rg --color=never --column --no-heading -S %s %s %s',
    \   l:extensions_args, s:escape_for_grep(a:pattern), shellescape(getcwd()))), 'trim(v:val)')
endfunction

if has('win32')
    function! s:escape_for_grep(text) abort
        let l:text = substitute(a:text, '["%&()<>^|]', '^&', 'g')
        let l:text = substitute(l:text, '\\\+\ze\^"', '&&', 'g')
        let l:text = substitute(l:text, '\^"', '\\&', 'g')
        let l:text = substitute(l:text, '\\\+$', '&&', '')
        let l:text = printf('^"%s^"', l:text)
        return l:text
    endfunction

    function! s:select_string_cmd(pattern, include_extensions, extensions) abort
        let l:extensions_args = empty(a:extensions) ? '' :
        \   printf('-%s %s', a:include_extensions ? 'include' : 'exclude', join(map(a:extensions, '"*." . v:val'), ','))
        return map(systemlist(printf('powershell -c "Get-ChildItem -File -r %s | Select-String %s | ForEach-Object { $_.ToString() }"',
        \   l:extensions_args, s:escape_for_select_string(a:pattern))), 'trim(iconv(v:val, "cp932", &encoding))')
    endfunction

    function! s:escape_for_select_string(text) abort
        let l:text = substitute(a:text, '["'']', '\\&&', 'g')
        let l:text = printf("'%s'", l:text)
        return l:text
    endfunction
else
    function! s:escape_for_grep(text) abort
        let l:text = substitute(a:text, '["\\`]', '\\&', 'g')
        let l:text = printf('"%s"', l:text)
        return l:text
    endfunction

    function! s:select_string_cmd(pattern, include_extensions, extensions) abort
        let l:extensions_args = empty(a:extensions) ? '' :
        \   printf('-%s %s', a:include_extensions ? 'include' : 'exclude', join(map(a:extensions, '"*." . v:val'), ','))
        return map(systemlist(printf('pwsh -c "Get-ChildItem -File -r %s | Select-String %s | ForEach-Object { \$_.ToString() }"',
        \   l:extensions_args, s:escape_for_select_string(a:pattern))), 'trim(v:val)')
    endfunction

    function! s:escape_for_select_string(text) abort
        let l:text = substitute(a:text, '\\\\', '&&', 'g')
        let l:text = substitute(l:text, '[!"`]', '\\&', 'g')
        let l:text = substitute(l:text, '\(^\|[^\\]\)\(\\\\\)*\zs\\\$', '\\&', 'g')
        let l:text = substitute(l:text, "'", '\\&&', 'g')
        let l:text = printf("'%s'", l:text)
        return l:text
    endfunction
endif

function! s:grep_parse(grep_result) abort
    let l:match = matchlist(a:grep_result, '^\(.\{-}\):\(\d\+\):')
    return {
    \   'file' : l:match[1],
    \   'line' : l:match[2]
    \}
endfunction

function! s:ag_parse(ag_result) abort
    let l:match = matchlist(a:ag_result, '^\(.\{-}\):\(\d\+\):\(\d\+\):')
    return {
    \   'file' : l:match[1],
    \   'line' : l:match[2],
    \   'col' : l:match[3]
    \}
endfunction

function! s:custom_cmd(pattern, include_extensions, extensions) abort
    return exists('*g:Ctrlpgrep_custom_cmd') ? funcref('g:Ctrlpgrep_custom_cmd')(a:pattern, a:include_extensions, a:extensions) : ''
endfunction

function! s:custom_parse(grep_result) abort
    return exists('*g:Ctrlpgrep_custom_parse') ? funcref('g:Ctrlpgrep_custom_parse')(a:grep_result) : { 'file' : '' }
endfunction

function! s:custom_executable() abort
    return exists('*g:Ctrlpgrep_custom_cmd') && exists('*g:Ctrlpgrep_custom_parse')
endfunction

let s:grep_item = {
\   'grep' : {
\       'cmd' : funcref('s:grep_cmd'),
\       'parse' : funcref('s:grep_parse'),
\       'executable' : function('executable', ['grep'])
\   },
\   'ag' : {
\       'cmd' : funcref('s:ag_cmd'),
\       'parse' : funcref('s:ag_parse'),
\       'executable' : function('executable', ['ag'])
\   },
\   'rg' : {
\       'cmd' : funcref('s:rg_cmd'),
\       'parse' : funcref('s:ag_parse'),
\       'executable' : function('executable', ['rg'])
\   },
\   'select-string' : {
\       'cmd' : funcref('s:select_string_cmd'),
\       'parse' : funcref('s:grep_parse'),
\       'executable' : function('executable', [has('win32') ? 'powershell' : 'pwsh'])
\   },
\   'custom' : {
\       'cmd' : funcref('s:custom_cmd'),
\       'parse' : funcref('s:custom_parse'),
\       'executable' : function('s:custom_executable')
\   }
\}
