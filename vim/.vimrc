" Substitute:
"   [w]ord under cursor
"   [/] last search pattern
"   ["] from default register
"   [.] last inserted text
nnoremap grw :%s/\<<c-r><c-w>\>//g<left><left>
nnoremap gr/ :%s/<c-r>///g<left><left>
nnoremap gr" :%s/<c-r>"//g<left><left>
nnoremap gr. :%s/<c-r>.//g<left><left>
xnoremap grw y:<c-u>%s/<c-r>"//g<left><left>
xnoremap gr/ :s/<c-r>///g<left><left>
xnoremap gr" :s/<c-r>"//g<left><left>
xnoremap gr. :s/<c-r>.//g<left><left>
" Change word under cursor
nnoremap c* *``cgn
nnoremap c# #``cgN

" Changes go to A register, leave my unnamed alone    
nnoremap c "ac
vnoremap c "ac
nnoremap C "aC
vnoremap C "aC
" Prevent x from overriding what's in the clipboard.    
noremap x "_x
noremap X "_x    

set sessionoptions-=blank,buffers
set sessionoptions-=curdir
set sessionoptions+=globals
set clipboard^=unnamed,unnamedplus
