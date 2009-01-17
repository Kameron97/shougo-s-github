"=============================================================================
" FILE: vimshell.vim
" AUTHOR: Janakiraman .S <prince@india.ti.com>(Original)
"         Shougo Matsushita <Shougo.Matsu@gmail.com>(Modified)
" Last Modified: 17 Jan 2009
" Usage: Just source this file.
"        source vimshell.vim
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
" Version: 3.5, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   3.5:
"     - Implemented by autoload.
"     - Fixed non-Windows platform error.
"     - Improved history executed.
"     - Fixed many bugs.
"   3.4:
"     - Fixed filename escape bug.
"     - Fixed vimshell buffer clear when hide.
"     - No setlocal lazyredraw.
"     - Filename escape when cd.
"     - Implemented pseudo shell variables.
"   3.3:
"     - Changed escape sequence into "\<ESC>".
"     - Changed autocmd timing.
"     - Added filename escape.
"     - Added vimshell_split_switch, vimshell_switch, vimshell_split_create, vimshell_create.
"     - Can have multiple Vimshell instance.
"   3.2:
"     - Fixed space name command bug.
"     - Fixed quick match bug.
"     - Implemented vim and view command.
"   3.1:
"     - Fixed ATOK X3 is ON  when startinsert.
"     - Silent message if exit code isn't 0.
"   3.0:
"     - Do startinsert! after command executed.
"     - Added g:VimShell_QuickMatchMaxLists option.
"     - Added g:VimShell_QuickMatchEnable option.
"     - Implemented two digits quick match.
"   2.9:
"     - Trial implemented highlight escape sequence.
"     - Fixed history bug.
"     - Convert cd to lcd.
"   2.8:
"     - Dup check when quick match.
"     - Due to optimize, filtering len(cur_keyword_str) >.
"     - Ignore head spaces when completion.
"   2.7:
"     - Implemented shell history completion by omnifunc.
"     - Mapping omnifunc <C-j>.
"     - Implemented quick match.
"     - Improved escape.
"   2.6:
"     - Implemented shell history.
"   2.5:
"     - Set lazyredraw in vimshell buffer.
"     - Refactoring.
"   2.3:
"     - Code cleanup.
"   2.2:
"     - Fix syntax highlight at pipe command.
"     - Fix quotetion highlight.
"   2.1:
"     - Fix syntax highlights.
"   2.0:
"     - Implemented syntax highlight.
"   1.0:
"     - Initial version.
""}}}
"-----------------------------------------------------------------------------
" TODO: "{{{
"     - Make built-in command autoload.
""}}}
" Bugs"{{{
"     -
""}}}
"=============================================================================

if exists('g:loaded_vimshell') || v:version < 700
  finish
endif

" Plugin keymapping"{{{
nnoremap <silent> <Plug>(vimshell_split_switch)  :<C-u>call vimshell#switch_shell(1)<CR>
nnoremap <silent> <Plug>(vimshell_split_create)  :<C-u>call vimshell#create_shell(1)<CR>
nnoremap <silent> <Plug>(vimshell_switch)  :<C-u>call vimshell#switch_shell(0)<CR>
nnoremap <silent> <Plug>(vimshell_create)  :<C-u>call vimshell#create_shell(0)<CR>
nnoremap <silent> <Plug>(vimshell_enter)  :<C-u>call vimshell#process_enter()<CR>
nmap <silent> <Leader>sp     <Plug>(vimshell_split_switch)
nmap <silent> <Leader>sn     <Plug>(vimshell_split_create)
nmap <silent> <Leader>sh     <Plug>(vimshell_switch)
nmap <silent> <Leader>sc     <Plug>(vimshell_create)
"}}}

command! -nargs=0 VimShell call s:vimshell#switch_shell(0)

let g:loaded_vimshell = 1

" vim: foldmethod=marker
