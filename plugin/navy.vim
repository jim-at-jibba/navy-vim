if exists('g:loaded_navy') | finish | endif " stops plugin loading twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to the defaults

hi def link NavyHeader      Number
hi def link NavySubHeader   Identifier

" Command to run our plugin
command! Navy lua require'navy'.navy()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_navy = 1
