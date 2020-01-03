" sql_client
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#sql_client#new()
let s:TABLE = s:V.import('Text.Table')

let g:sql_profiles = [{'name': 'sqlite3', 'dbtype': 'sqlite3', 'dsn': ':memory:'}]

let s:bufname = '[SQL OUTPUT]'

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
"     'name': 'sqlite3',
"     'channel': channel,
"   },
" ]
if !exists('g:loaded_sql_client_autoload')
  let s:connection_pool = []
  let s:selected_db = {}
endif
let g:loaded_sql_client_autoload = 1

" OUT:
" {
"   'name': 'test_db',
"   'dbtype': 'sqlite3',
"   'channel': channel,
" }
function! sql_client#get_connection() abort
  if empty(s:selected_db)
    return {}
  endif

  let result = filter(s:connection_pool,
        \ printf('v:val.dbtype is "%s" && v:val.name is "%s"',
        \ s:selected_db.dbtype, s:selected_db.name))

  if len(result) > 0
    return result[0]
  endif

  return {}
endfunction

" profiles [
"   {
"       'name': 'mydb',
"       'dbtype': 'mysql',
"       'dsn': 'gorilla:gorilla@localhost'
"   },
"   {
"       'name': 'test_db',
"       'dbtype': 'sqlite',
"       'dsn': ':memory:'
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
"       'name': 'slqite3',
"       'dbtype': 'sqlite3',
"       'dsn': ':memory:',
"     }
"   ]
" }
function! sql_client#new_connection(context, id, selected) abort
  let profile = a:context.profiles[a:selected-1]

  " validate profile
  for k in ['name', 'dbtype', 'dsn']
    if !has_key(profile, k)
      call s:echo_err('not found profile.' .. k)
      return
    endif
  endfor

  " if already connected, do nothing
  for c in s:connection_pool
    if c.name is profile.name
      call s:echo_err(profile.name .. ' is already connected')
      return
    endif
  endfor

  let channel = ch_open("localhost:9999", {
        \ 'mode': 'raw',
        \ 'callback': function('s:channel_callback')
        \ })

  if ch_status(channel) is 'closed'
    call s:echo_err('cannot connect ' .. porfile.name)
    return
  endif

  let req = s:build_request(profile.dbtype, 'connection', 'dsn=' .. profile.dsn)
  call ch_sendraw(channel, req)

  let s:selected_db = {
        \ 'name': profile.name,
        \ 'dbtype': profile.dbtype,
        \ }
endfunction

function! s:channel_callback(channel, msg) abort
  let res = json_decode(a:msg)

  if res.status is 'error'
    call s:echo_err(res.body)
    if res.method is 'connection'
      let s:selected_db = {}
    endif
    return
  endif

  if res.method is 'connection'
    cal add(s:connection_pool, {'name': s:selected_db.name, 'dbtype': res.body, 'channel': a:channel})
    echom 'connected'
    return
  endif

  " create table
  " {'status': 'success', 'method': 'query', 'body': '[{"id":1,"name":"gorilla"},{"id":2,"name":"cat"}]'}
  let body = json_decode(res.body)
  if empty(body)
    call s:echo_err('body is empty')
    return
  endif

  let header = keys(body[0])
  let columns = []
  for v in header
    let columns = add(columns, {})
  endfor

  let result_table = s:TABLE.new({
        \ 'columns': columns,
        \ 'header' : header,
        \ })

  for b in body
    let row = []
    for h in header
      call add(row, b[h])
    endfor
    call result_table.add_row(row)
  endfor

  " if buf is already exist
  if bufexists(s:bufname)
    let buf = bufnr(s:bufname)
    let winid = win_findbuf(buf)
    if empty(winid)
      exec 'new | e' s:bufname '| %d_'
    endif
    call win_execute(winid[0], '%d_')
  " if buf not exist, create new window
  else
      exec 'new' s:bufname '| %d_'
      set buftype=nofile | nnoremap <buffer> q :bw<CR>
  endif

  call setbufline(s:bufname, 1, result_table.stringify())
endfunction

function! sql_client#exec_sql(sql) abort
  call s:send_req('exec', a:sql)
endfunction

function! sql_client#query_sql(sql) abort
  call s:send_req('query', a:sql)
endfunction

function! s:send_req(querytype, sql) abort
  let conn = sql_client#get_connection()
  if empty(conn)
    call s:echo_err('cannot get connection')
    return
  endif

  let req = s:build_request(conn.dbtype, a:querytype, a:sql)
  call ch_sendraw(conn.channel, req)
endfunction

" build request
" e.g
" sqlite3: exec
" create table users(id int, name varchar(255))
function! s:build_request(dbtype, querytype, body) abort
  return printf("%s: %s\n%s", a:dbtype, a:querytype, a:body)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
