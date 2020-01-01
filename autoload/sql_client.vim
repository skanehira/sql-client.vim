" sql_client
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

function! s:echo_err(msg) abort
  echohl ErrorMsg
  echom 'sql_client.vim: ' .. a:msg
  echohl None
endfunction

" this a pool for keep db connection
" [
"   {
"     'name': 'mysql',
"     'channel': channel,
"   },
"   {
"     'name': 'sqlite',
"     'channel': channel,
"   },
" ]
let s:connection_pool = []

function! sql_client#get_connection_pool() abort
  return s:connection_pool
endfunction

" OUT:
" {
"   'name': 'sqlite',
"   'channel': channel,
" }
function! sql_client#get_connection(name) abort
  let result = filter(s:connection_pool, printf('v:val.name is "%s"', a:name))
  if len(result) > 0
    return result[0]
  endif
  return {}
endfunction

" profiles [
"   {
"       'name': 'mydb',
"       'type': 'mysql',
"       'host': 'localhost',
"       'user': 'gorilla',
"       'password': 'password',
"   },
"   {
"       'name': 'test_db',
"       'type': 'sqlite',
"       'host': 'localhost',
"       'user': 'gorilla',
"       'password': 'password',
"   }
" ]
function! sql_client#profiles() abort
  let profiles = get(g:, 'sql_profiles', {})
  if empty(profiles)
    call s:echo_err('not found any profiles')
    return
  endif

  let context = {
        \ 'profiles': profiles
        \ }

  call popup_menu(map(copy(profiles), 'v:val.name'), {
        \ 'callback': function('sql_client#new_connection', [context]),
        \ })

endfunction

" IN:
" context: {
"   profiles: [
"     {
"       'name': 'mysql',
"       'host': 'localhost',
"       'user': 'gorilla',
"       'password': 'password',
"     }
"   ]
" }
function! sql_client#new_connection(context, id, selected) abort
  let profile = a:context.profiles[a:selected-1]

  for k in ['name', 'host', 'user', 'password']
    if !has_key(profile, k)
      call s:echo_err('not found profile.' .. k)
      return
    endif
  endfor

  for c in s:connection_pool
    if c.name is profile.name
      call s:echo_err(profile.name .. ' is already connected')
      return
    endif
  endfor

  cal add(s:connection_pool, profile)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
