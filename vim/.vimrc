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