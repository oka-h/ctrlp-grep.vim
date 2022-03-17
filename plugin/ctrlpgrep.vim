if get(g:, 'loaded_ctrlpgrep')
    finish
endif

let g:loaded_ctrlpgrep = 1
let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=dir CtrlPGrep call ctrlp#grep#run(<f-args>)

if !exists('g:ctrlpgrep_cmd')
    let g:ctrlpgrep_cmd = (has('win32') || has('win64')) ? 'select-string' : 'grep'
endif

if !exists('g:ctrlpgrep_default_include_extensions')
    let g:ctrlpgrep_default_include_extensions = []
endif

if !exists('g:ctrlpgrep_default_exclude_extensions')
    let g:ctrlpgrep_default_exclude_extensions = []
endif

if !exists('g:ctrlpgrep_highlight_enable')
    let g:ctrlpgrep_highlight_enable = 0
endif

let &cpo = s:save_cpo
unlet s:save_cpo
