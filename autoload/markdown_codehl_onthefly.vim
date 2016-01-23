scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let g:markdown_codehl_onthefly#additional_fenced_languages =
\   get(g:, 'markdown_codehl_onthefly#additional_fenced_languages', [
\           'viml=vim',
\           'bash=sh'
\])

let s:NONE = []
let s:do_syn_include_after = 0


function! markdown_codehl_onthefly#start() abort
    if &filetype !=# 'markdown'
        return
    endif
    " Save current g:markdown_fenced_languages
    call s:save_markdown_fenced_languages()
    " Change g:markdown_fenced_languages (buffer-local)
    call s:set_markdown_fenced_languages(
    \   s:get_using_inline_filetypes() +
    \   g:markdown_codehl_onthefly#additional_fenced_languages)
    " Register auto-commands (buffer-local)
    augroup markdown_codehl_onthefly-buflocal
        autocmd!
        autocmd TextChanged,TextChangedI <buffer>
        \   let s:do_syn_include_after = 1
        autocmd InsertLeave <buffer>
        \   call s:syn_include_dynamically()
        autocmd BufEnter <buffer>
        \   call s:restore_buflocal_markdown_fenced_languages()
        autocmd BufLeave <buffer>
        \   call s:restore_markdown_fenced_languages()
    augroup END
endfunction

" Save current g:markdown_fenced_languages
" before changing g:markdown_fenced_languages.
" @seealso s:restore_markdown_fenced_languages()
function! s:save_markdown_fenced_languages() abort
    if !exists('g:markdown_fenced_languages')
        let b:markdown_codehl_onthefly_prev_markdown_fenced_languages =
        \   s:NONE
    else
        let b:markdown_codehl_onthefly_prev_markdown_fenced_languages =
        \   g:markdown_fenced_languages
    endif
endfunction

" Restore original g:markdown_fenced_languages
" before entering markdown buffer.
" @seealso s:save_markdown_fenced_languages()
function! s:restore_markdown_fenced_languages() abort
    if b:markdown_codehl_onthefly_prev_markdown_fenced_languages is s:NONE
        unlet g:markdown_fenced_languages
    else
        let g:markdown_fenced_languages =
        \   b:markdown_codehl_onthefly_prev_markdown_fenced_languages
    endif
endfunction

" Set g:markdown_fenced_languages when entering markdown buffer.
" @seealso s:restore_buflocal_markdown_fenced_languages()
function! s:set_markdown_fenced_languages(langs) abort
    let g:markdown_fenced_languages = copy(a:langs)
    let b:markdown_codehl_onthefly_buflocal_markdown_fenced_languages =
    \   copy(a:langs)
endfunction

" Set g:markdown_fenced_languages when entering markdown buffer.
" @seealso s:set_markdown_fenced_languages()
function! s:restore_buflocal_markdown_fenced_languages() abort
    if exists('b:markdown_codehl_onthefly_buflocal_markdown_fenced_languages')
        let g:markdown_fenced_languages =
        \   b:markdown_codehl_onthefly_buflocal_markdown_fenced_languages
    endif
endfunction

function! s:syn_include_dynamically() abort
    if !s:do_syn_include_after
        return
    endif
    if !exists('g:markdown_fenced_languages')
        let g:markdown_fenced_languages = []
    endif
    try
        let added = 0
        for filetype in s:get_using_inline_filetypes()
            let group = 'markdownHighlight' . filetype
            if match(g:markdown_fenced_languages,
            \       '^'.filetype.'\($\|=\)') ==# -1
                call s:set_markdown_fenced_languages(
                \   g:markdown_fenced_languages + [filetype]
                \)
                let added = 1
            endif
        endfor
        if added
            syntax clear
            syntax enable
        endif
    finally
        let s:do_syn_include_after = 0
    endtry
endfunction

let s:RE_FILETYPE = '```\zs\w\+\ze'
function! s:get_using_inline_filetypes() abort
    return map(filter(getline(1, '$'), 'v:val =~# s:RE_FILETYPE'),
    \         'matchstr(v:val, s:RE_FILETYPE)')
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
" vim:set et:
