" sql_client
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

function! s:echo_err(msg) abort
	echohl ErrorMsg
	echo a:msg
	echohl None
endfunction

" profiles [
"   {
"       'name': 'mysql',
"       'host': 'localhost',
"       'user': 'gorilla',
"       'password': 'password',
"   },
"   {
"       'name': 'mysql',
"       'host': 'localhost',
"       'user': 'gorilla',
"       'password': 'password',
"   }
" ]
function! sql_client#profiles() abort
    let profiles = get(g, 'sql_profiles', {})
    if empty(profiles)
        call s:echo_err('can''t found any profiles')
        return
    endif

    let names = map(copy(profiles), 'return v:val.name')
    return names
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
