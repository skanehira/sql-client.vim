" sql_client
" Author: skanehira
" License: MIT

if exists('g:loaded_sql_client')
  finish
endif
let g:loaded_sql_client = 1

let s:save_cpo = &cpo
set cpo&vim

command! SQLProfiles call sql_client#profiles()
command! -range SQLExec call sql_client#exec_sql(<line1>, <line2>)
command! -range SQLQuery call sql_client#query_sql(<line1>, <line2>)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
