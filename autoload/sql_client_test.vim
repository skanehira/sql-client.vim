let s:suite = themis#suite('Test for my plugin')
let s:assert = themis#helper('assert')

let g:sql_profiles = [
            \ {
            \     'name': 'mysql',
            \     'host': 'localhost',
            \     'user': 'gorilla',
            \     'password': 'password',
            \ },
            \ {
            \     'name': 'mysql',
            \     'host': 'localhost',
            \     'user': 'gorilla',
            \     'password': 'password',
            \ }
            \ ]

function! s:suite.my_test_1()
    call s:assert.equals(sql_client#profiles(), g:sql_profiles)
endfunction
