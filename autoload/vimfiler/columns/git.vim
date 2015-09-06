"
"============================================================================
" FILE: git.vim
" AUTHOR:  Dzikie Drożdże <daz@hackerspace.pl>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:fish = &shell =~# 'fish'

function! vimfiler#columns#git#define()
  return s:column
endfunction"}}}

let s:column = {
      \ 'name' : 'git',
      \ 'description' : 'git file status',
      \ 'syntax' : 'vimfilerColumn__Git',
      \ }

function! s:column.length(files, context) "{{{
  return 3
endfunction "}}}
if !exists('g:VimFilerGitIndicatorMap')
    let g:VimFilerGitIndicatorMap = {
                \ "Modified"  : "✹",
                \ "Staged"    : "✚",
                \ "Untracked" : "✭",
                \ "Renamed"   : "➜",
                \ "Unmerged"  : "═",
                \ "Deleted"   : "✖",
                \ "Dirty"     : "✗",
                \ "Clean"     : "✔︎",
                \ "Unknown"   : "?"
                \ }
endif

function! s:column.define_syntax(context) "{{{
  syntax match   vimfilerColumn__GitModified     '\[✹\]' 
  \ contained containedin=vimfilerColumn__Git            
  syntax match   vimfilerColumn__GitStaged       '\[✚\]' 
  \ contained containedin=vimfilerColumn__Git            
  syntax match   vimfilerColumn__GitUnstaged     '\[✭\]' 
  \ contained containedin=vimfilerColumn__Git            
  syntax match   vimfilerColumn__GitRenamed      '\[➜\]' 
  \ contained containedin=vimfilerColumn__Git            
  syntax match   vimfilerColumn__GitUnmerged     '\[═\]' 
  \ contained containedin=vimfilerColumn__Git            
  syntax match   vimfilerColumn__GitDeleted      '\[✖\]' 
  \ contained containedin=vimfilerColumn__Git            
  syntax match   vimfilerColumn__GitDirty        '\[✗\]' 
  \ contained containedin=vimfilerColumn__Git             
  syntax match   vimfilerColumn__GitClean        '\[✔︎\]' 
  \ contained containedin=vimfilerColumn__Git             
  syntax match   vimfilerColumn__GitUnknown      '\[?\]' 
  \ contained containedin=vimfilerColumn__Git

  highlight def link  vimfilerColumn__GitModified Special
  highlight def link  vimfilerColumn__GitStaged   Function
  highlight def link  vimfilerColumn__GitUnstaged Text
  highlight def link  vimfilerColumn__GitRenamed  Title
  highlight def link  vimfilerColumn__GitUnmerged Label
  highlight def link  vimfilerColumn__GitDeleted  Text
  highlight def link  vimfilerColumn__GitDirty    Text
  highlight def link  vimfilerColumn__GitClean    Text   
  highlight def link  vimfilerColumn__GitUnknown  Text   
endfunction "}}}

function s:directory_of_file(file)
  return fnamemodify(a:file, ':h')
endfunction


function! s:system(cmd, ...)
  silent let output = (a:0 == 0) ? system(a:cmd) : system(a:cmd, a:1)
  return output
endfunction

function! s:git_shellescape(arg)
  if a:arg =~ '^[A-Za-z0-9_/.-]\+$'
    return a:arg
  elseif &shell =~# 'cmd' || gitgutter#utility#using_xolox_shell()
    return '"' . substitute(substitute(a:arg, '"', '""', 'g'), '%', '"%"', 'g') . '"'
  else
    return shellescape(a:arg)
  endif
endfunction

function! s:cmd_in_directory_of_file(file, cmd)
     return 'cd '.s:git_shellescape(s:directory_of_file(a:file)) . (s:fish ? '; and ' : ' && ') . a:cmd
endfunction



function! s:git_state_to_name(symb)  " TODO: X, Y
    if a:symb == 'OK'
        return "Unmodified"
    elseif a:symb == 'M'
        return "Modified"
    elseif a:symb == 'A'
        return "Staged"
    elseif a:symb == 'D'
        return "Deleted"
    else
    elseif a:symb == 'R'
        return "Renamed"
    else
    let unmerged_states  = ['DD', 'AU', 'UD', 'UA', 'DU', 'AA', 'UU']
    elseif (index(symb, unmerged_states) >= 0)
        return "Unmerged"
    endif

endfunction

function! s:git_state_to_symbol(s)
    let name = s:git_state_to_name(a:s)
    return g:VimFilerGitIndicatorMap[name]
endfunction

function! s:column.get(file, context) "{{{
    if(a:file.vimfiler__is_directory)
        return '   '
    endif
    let fname = a:file.vimfiler__filename
    let fullname = a:file.word
    let cmd = s:cmd_in_directory_of_file(fullname, "git status --porcelain " . fname)
    let output = split(s:system(cmd))
    if v:shell_error
        return '   '
    endif
    let symbol = len(output) ? output[0] : 'OK'
    return '[' . s:git_state_to_symbol(symbol) . ']'
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
