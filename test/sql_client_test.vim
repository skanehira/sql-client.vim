let s:suite = themis#suite('Test for my plugin')
let s:assert = themis#helper('assert')

function! s:suite.test_get_connection()
  let sql_profiles = [
        \ {
        \     'name': 'mysql',
        \     'host': 'localhost',
        \     'user': 'gorilla',
        \     'password': 'password',
        \ },
        \ ]

  call sql_client#new_connection({'profiles': sql_profiles}, 0, 1)

  call s:assert.equals(sql_client#get_connection('mysql'),
        \ sql_client#get_connection_pool()[0])

endfunction
