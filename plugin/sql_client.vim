" sql_client
" Author: skanehira
" License: MIT

if exists('g:loaded_sql_client')
  finish
endif
let g:loaded_sql_client = 1

let s:save_cpo = &cpo
set cpo&vim



let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
