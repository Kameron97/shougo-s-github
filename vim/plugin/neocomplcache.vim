"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 13 Jan 2009
" Usage: Just source this file.
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
" Version: 1.31, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.32:
"     - Improved completion cancel.
"     - Improved syntax keyword vim, sh, zsh, vimshell.
"     - Implemented g:NeoComplCache_NonBufferFileTypeDetect option.
"   1.31:
"     - Added g:NeoComplCache_MinKeywordLength option.
"     - Caching keyword_pattern.
"     - Fixed current buffer filtering bug.
"     - Fixed rank calculation bug.
"     - Optimized keyword caching.
"     - Fixed lazyredraw bug.
"   1.30:
"     - Added NeoCompleCachingTags, NeoCompleCacheDictionary command.
"     - Renamed NeoCompleCachingBuffer command.
"   1.29:
"     - Added NeoCompleCacheLock, NeoCompleCacheUnlock command.
"     - Dup check when quick match.
"     - Fixed error when manual complete.
"   1.28:
"     - Improved filetype detection.
"     - Changed g:NeoComplCache_MaxFilenameWidth default value.
"     - Improved list.
"   1.27:
"     - Improved syntax keyword.
"     - Improved calc rank timing.
"     - Fixed keyword filtering bug.
"   1.26:
"     - Ignore if dictionary file doesn't exists.
"     - Due to optimize, filtering len(cur_keyword_str) >.
"     - Auto complete when InsertEnter.
"   1.25:
"     - Exclude cur_keyword_str from keyword lists.
"   1.24:
"     - Due to optimize, filtering len(cur_keyword_str) >=.
"     - Fixed buffer dictionary bug.
"   1.23:
"     - Fixed on lazyredraw bug.
"     - Optimized when no dictionary and tags.
"     - Not echo calculation time.
"   1.22:
"     - Optimized source.
"   1.21:
"     - Fixed overwrite completefunc bug.
"   1.20:
"     - Implemented buffer dictionary.
"   1.10:
"     - Implemented customizable complete function.
"   1.00:
"     - Renamed.
"     - Initial version.
" ChangeLog AltAutoComplPop: "{{{
"   2.62:
"     - Set lazyredraw at auto complete.
"     - Added g:AltAutoComplPop_CalcRankMaxLists option.
"     - Improved calc rank timing.
"     - Improved filetype check.
"   2.61:
"     - Improved keyword patterns.
"     - Changed g:AltAutoComplPop_CacheLineCount default value.
"     - Implemented :Neco command.
"   2.60:
"     - Cleanuped code.
"     - Show '[T]' or '[D]' at completing.
"     - Implemented tab pages tags completion.
"     - Fixed error when tab created.
"     - Changed g:AltAutoComplPop_CalcRankCount default value.
"   2.50:
"     - Implemented filetype dictionary completion.
"   2.14:
"     - Fixed 'Undefined Variable: s:cur_keyword_pos' bug.
"     - Implemented tags completion.
"   2.13:
"     - Added g:AltAutoComplPop_DictionaryLists option.
"     - Implemented dictionary completion.
"   2.12:
"     - Added g:AltAutoComplPop_CalcRankCount option.
"   2.11:
"     - Added g:AltAutoComplPop_SlowCompleteSkip option.
"     - Removed g:AltAutoComplPop_OptimiseLevel option.
"   2.10:
"     - Added g:AltAutoComplPop_QuickMatch option.
"     - Changed g:AltAutoComplPop_MaxList default value.
"     - Don't cache help file.
"   2.09:
"     - Added g:AltAutoComplPop_EnableAsterisk option.
"     - Fixed next cache line cleared bug.
"   2.08:
"     - Added g:AltAutoComplPop_OptimiseLevel option.
"       If list has many keyword, will optimise complete. 
"     - Added g:AltAutoComplPop_DisableAutoComplete option.
"   2.07:
"     - Fixed caching miss when BufRead.
"   2.06:
"     - Improved and customizable keyword patterns.
"   2.05:
"     - Added g:AltAutoComplPop_DeleteRank0 option.
"     - Implemented lazy caching.
"     - Cleanuped code.
"   2.04:
"     - Fixed caching bug.
"   2.03:
"     - Fixed rank calculation bug.
"   2.02:
"     - Fixed GVim problem at ATOK X3
"   2.01:
"     - Fixed rank calculation bug.
"     - Faster at caching.
"   2.0:
"     - Implemented Updates current buffer cache at InsertEnter.
"   1.13:
"     - Licence changed.
"     - Fix many bugs.
"   1.1:
"     - Implemented smart completion.
"       It works in vim, c, cpp, ruby, ...
"     - Implemented file completion.
"   1.0:
"     - Initial version.
""}}}
"
" }}}
"-----------------------------------------------------------------------------
" TODO: "{{{
"     - Completion optimize.
""}}}
" Bugs"{{{
"     - Nothing.
""}}}
"=============================================================================

if exists('g:loaded_neocomplcache') || v:version < 700
  finish
endif

let s:disable_neocomplcache = 1

let s:NeoComplCache = {}

command! -nargs=0 NeoCompleCacheEnable call s:NeoComplCache.Enable()
command! -nargs=0 NeoCompleCacheDisable call s:NeoComplCache.Disable()
command! -nargs=0 NeoCompleCacheToggle call s:NeoComplCache.Toggle()

function! s:NeoComplCache.Complete()"{{{
    if pumvisible() || &paste || s:complete_lock || g:NeoComplCache_DisableAutoComplete
                \|| &l:completefunc != 'g:NeoComplCache_ManualCompleteFunc'
        return
    endif

    " Get cursor word.
    let l:cur_text = strpart(getline('.'), 0, col('.') - 1) 
    " Prevent infinity loop.
    if l:cur_text == s:old_text
        return
    endif
    let s:old_text = l:cur_text

    " Not complete multi byte character for ATOK X3.
    if char2nr(l:cur_text[-1]) >= 0x80
        return
    endif

    let l:pattern = s:GetKeywordPattern(bufnr('%')) . '$'
    let l:cur_keyword_pos = match(l:cur_text, l:pattern)
    let l:cur_keyword_str = matchstr(l:cur_text, l:pattern)

    if g:NeoComplCache_EnableAsterisk
        " Check *.
        let [l:cur_keyword_pos, l:cur_keyword_str] = s:CheckAsterisk(l:cur_text, l:pattern, l:cur_keyword_pos, l:cur_keyword_str)
    endif

    if l:cur_keyword_pos < 0 || len(cur_keyword_str) < g:NeoComplCache_KeywordCompletionStartLength
        " Try filename completion.
        "
        let l:PATH_SEPARATOR = (has('win32') || has('win64')) ? '/\\' : '/'
        " Filename pattern.
        let l:pattern = printf('\f[%s]\f\{%d,}$', l:PATH_SEPARATOR, g:NeoComplCache_FilenameCompletionStartLength)
        " Not Filename pattern.
        let l:exclude_pattern = '[*/\\][/\\]\f*$\|[^[:print:]]\f*'

        " Check filename completion.
        if match(l:cur_text, l:pattern) >= 0 && match(l:cur_text, l:exclude_pattern) < 0
            call feedkeys("\<C-x>\<C-f>\<C-p>", 'n')
        endif

        return
    endif

    " Save options.
    let s:ignorecase_save = &l:ignorecase
    let s:lazyredraw_save = &l:lazyredraw

    " Set function.
    let &l:completefunc = 'g:NeoComplCache_AutoCompleteFunc'

    " Extract complete words.
    let &l:ignorecase = g:NeoComplCache_IgnoreCase
    "setlocal lazyredraw
    let &l:lazyredraw = 1
    let s:complete_words = []
    for complefunc in s:GetCompleFuncPattern()
        let Fn = function(complefunc)
        call extend(s:complete_words, Fn(l:cur_keyword_str))
    endfor

    " Prevent filcker.
    if empty(s:complete_words)
        " Restore options
        let &l:completefunc = 'g:NeoComplCache_ManualCompleteFunc'
        let &l:ignorecase = s:ignorecase_save
        let &l:lazyredraw = s:lazyredraw_save

        return
    endif

    " Lock auto complete.
    let s:complete_lock = 1

    " Start original complete.
    let s:cur_keyword_pos = l:cur_keyword_pos
    let s:cur_keyword_str = l:cur_keyword_str
    call feedkeys("\<C-x>\<C-u>\<C-p>", 'n')
endfunction"}}}

function! s:CheckAsterisk(cur_text, pattern, cur_keyword_pos, cur_keyword_str)"{{{
    let l:cur_keyword_pos = a:cur_keyword_pos
    let l:cur_keyword_str = a:cur_keyword_str

    while l:cur_keyword_pos > 1 && a:cur_text[l:cur_keyword_pos - 1] == '*'
        let l:left_text = strpart(a:cur_text, 0, l:cur_keyword_pos - 1) 
        let l:left_keyword_str = matchstr(l:left_text, a:pattern)

        let l:cur_keyword_pos = match(l:left_text, a:pattern)
        let l:cur_keyword_str = l:left_keyword_str . '*' . l:cur_keyword_str
    endwhile

    return [l:cur_keyword_pos, l:cur_keyword_str]
endfunction"}}}

function! g:NeoComplCache_AutoCompleteFunc(findstart, base)"{{{
    if a:findstart
        return s:cur_keyword_pos
    endif

    " Prevent multiplex call.
    if !s:complete_lock
        return []
    endif

    " Restore options.
    let &l:completefunc = 'g:NeoComplCache_ManualCompleteFunc'
    let &l:ignorecase = s:ignorecase_save
    let &l:lazyredraw = s:lazyredraw_save
    " Unlock auto complete.
    let s:complete_lock = 0

    return s:complete_words
endfunction"}}}

function! g:NeoComplCache_ManualCompleteFunc(findstart, base)"{{{
    if a:findstart
        " Get cursor word.
        let l:cur = col('.') - 1
        let l:cur_text = strpart(getline('.'), 0, l:cur)

        let l:pattern = s:GetKeywordPattern(bufnr('%')) . '$'
        let l:cur_keyword_pos = match(l:cur_text, l:pattern)
        if l:cur_keyword_pos < 0
            return -1
        endif
        let l:cur_keyword_str = matchstr(l:cur_text, l:pattern)

        if g:NeoComplCache_EnableAsterisk
            " Check *.
            let [l:cur_keyword_pos, l:cur_keyword_str] = s:CheckAsterisk(l:cur_text, l:pattern, l:cur_keyword_pos, l:cur_keyword_str)
        endif
        
        return l:cur_keyword_pos
    endif

    " Save options.
    let l:ignorecase_save = &l:ignorecase

    " Complete.
    let &l:ignorecase = g:NeoComplCache_IgnoreCase
    let l:complete_words = []
    for complefunc in s:GetCompleFuncPattern()
        let Fn = function(complefunc)
        call extend(l:complete_words, Fn(a:base))
    endfor

    " Restore options.
    let &l:ignorecase = l:ignorecase_save

    return l:complete_words
endfunction"}}}

" RankOrder.
function! s:CompareRank(i1, i2)
    return a:i1.rank < a:i2.rank ? 1 : a:i1.rank == a:i2.rank ? 0 : -1
endfunction
" AlphabeticalOrder.
function! s:CompareWords(i1, i2)
    return a:i1.word > a:i2.word ? 1 : a:i1.word == a:i2.word ? 0 : -1
endfunction

function! g:NeoComplCache_NormalComplete(cur_keyword_str)"{{{
    if g:NeoComplCache_SlowCompleteSkip && &l:completefunc == 'g:NeoComplCache_AutoCompleteFunc'
        let l:start_time = reltime()
    endif

    if g:NeoComplCache_EnableAsterisk
        let l:keyword_escape = substitute(substitute(escape(a:cur_keyword_str, '" \ . ^ $'), "'", "''", 'g'), '\*', '.*', 'g')
    else
        let l:keyword_escape = escape(substitute(a:cur_keyword_str, '" \ . ^ $ *'), "'", "''", 'g')
    endif

    " Keyword filter.
    if g:NeoComplCache_PartialMatch
        " Partial match.
        " Filtering len(a:cur_keyword_str).
        let l:pattern = printf("len(v:val.word) > len(a:cur_keyword_str) && v:val.word =~ '%s'", l:keyword_escape)
    else
        " Normal match.
        " Filtering len(a:cur_keyword_str).
        let l:pattern = printf("len(v:val.word) > len(a:cur_keyword_str) && v:val.word =~ '^%s'", l:keyword_escape)
    endif

    " Check dictionaries and tags are exists.
    if !empty(&filetype) && has_key(g:NeoComplCache_DictionaryFileTypeLists, &filetype)
        let l:ft_dict = '^' . &filetype
    elseif !empty(g:NeoComplCache_DictionaryFileTypeLists['default'])
        let l:ft_dict = '^default'
    else
        " Dummy pattern.
        let l:ft_dict = '^$'
    endif
    if has_key(g:NeoComplCache_TagsLists, tabpagenr())
        let l:tags = '^tags' . tabpagenr()
    elseif !empty(g:NeoComplCache_TagsLists['default'])
        let l:tags = '^tagsdefault'
    else
        " Dummy pattern.
        let l:tags = '^$'
    endif
    if has_key(g:NeoComplCache_DictionaryBufferLists, bufnr('%'))
        let l:buf_dict = '^dict' . bufnr('%')
    else
        " Dummy pattern.
        let l:buf_dict = '^$'
    endif
    let l:cache_keyword_buffer_filtered = []
    for key in keys(s:source)
        if key =~ '^\d' || key =~ l:ft_dict || key =~ l:tags || key =~ l:buf_dict
            call extend(l:cache_keyword_buffer_filtered, filter(values(s:source[key].keyword_cache), l:pattern))
        endif
    endfor

    if g:NeoComplCache_AlphabeticalOrder 
        " Not calc rank.
        let l:order_func = 's:CompareWords'
    else
        " Calc rank.
        let l:menu_pattern = '%.' . g:NeoComplCache_MaxFilenameWidth . 's %3d'
        let l:list_len = len(l:cache_keyword_buffer_filtered)

        if l:list_len > g:NeoComplCache_CalcRankMaxLists
            let l:calc_cnt = 5
        elseif l:list_len > g:NeoComplCache_CalcRankMaxLists / 2
            let l:calc_cnt = 3
        elseif l:list_len > g:NeoComplCache_CalcRankMaxLists / 4
            let l:calc_cnt = 2
        else
            let l:calc_cnt = 1
        endif

        for keyword in l:cache_keyword_buffer_filtered
            if !has_key(keyword, 'rank') || s:rank_cache_count > l:calc_cnt
                " Reset count.
                let [s:rank_cache_count, keyword.rank] = [0, 0]

                for keyword_lines in values(s:source[keyword.srcname].rank_cache_lines)
                    if has_key(keyword_lines, keyword.word)
                        let keyword.rank += keyword_lines[keyword.word]
                    endif
                endfor

                if g:NeoComplCache_DrawWordsRank
                    let keyword.menu = printf(l:menu_pattern, keyword.filename, keyword.rank)
                endif
            else
                let s:rank_cache_count += 1
            endif
        endfor

        if g:NeoComplCache_DeleteRank0
            " Delete element if rank is 0.
            call filter(l:cache_keyword_buffer_filtered, 'v:val.rank > 0')
        endif

        let l:order_func = 's:CompareRank'
    endif

    if exists('l:start_time')
        "let l:end_time = split(reltimestr(reltime(l:start_time)))[0]
        "if l:end_time > '0.2'
        if split(reltimestr(reltime(l:start_time)))[0] > '0.2'
            " Skip completion if takes too much time.
            echo 'Too many items'
            return []
        endif

        "echo l:end_time
    endif

    if g:NeoComplCache_FirstCurrentBufferWords
        let l:cache_keyword_filtered = 
                    \ filter(copy(l:cache_keyword_buffer_filtered), 'v:val.srcname == ' . bufnr('%'))
        " Sort and append list.
        if len(l:cache_keyword_filtered) < g:NeoComplCache_MaxList
            call filter(l:cache_keyword_filtered, 'v:val.srcname != ' . bufnr('%'))
            let l:ret = extend(sort(l:cache_keyword_filtered, l:order_func), sort(l:cache_keyword_buffer_filtered, l:order_func))
        else
            let l:ret = sort(l:cache_keyword_buffer_filtered, l:order_func)
        endif
    else
        " Sort.
        let l:ret = sort(l:cache_keyword_buffer_filtered, l:order_func)
    endif

    if g:NeoComplCache_QuickMatch
        " Append numbered list.
        if match(l:keyword_escape, '\d$') >= 0
            " Get numbered list.
            let l:numbered = get(s:prev_numbered_list, str2nr(matchstr(l:keyword_escape, '\d$'))-1)
            if type(l:numbered) == type({})
                call insert(l:ret, l:numbered)
            endif
        endif
    endif

    " Trunk too many item.
    let l:ret = l:ret[:g:NeoComplCache_MaxList-1]

    if g:NeoComplCache_QuickMatch
        " Check dup.
        let l:dup_check = {}
        let l:num = 0
        let l:numbered_ret = []
        for keyword in l:ret[0:14]
            if !has_key(l:dup_check, keyword.word)
                let l:dup_check[keyword.word] = 1

                call add(l:numbered_ret, keyword)
            endif
            let l:num += 1
        endfor

        " Add number.
        let l:abbr_pattern_d = '%d: %.' . g:NeoComplCache_MaxKeywordWidth . 's'
        let l:abbr_pattern_n = '   %.' . g:NeoComplCache_MaxKeywordWidth . 's'
        let l:num = 0
        for keyword in l:numbered_ret
            if l:num == 0
                let keyword.abbr = printf('*: %.' . g:NeoComplCache_MaxKeywordWidth . 's', keyword.word)
            elseif l:num == 10
                let keyword.abbr = printf('0: %.' . g:NeoComplCache_MaxKeywordWidth . 's', keyword.word)
            elseif l:num < 10
                let keyword.abbr = printf(l:abbr_pattern_d, l:num, keyword.word)
            else
                let keyword.abbr = printf(l:abbr_pattern_n, keyword.word)
            endif

            let l:num += 1
        endfor
        for keyword in l:ret[15:]
            let keyword.abbr = printf(l:abbr_pattern_n, keyword.word)
        endfor

        " Append list.
        let l:ret = extend(l:numbered_ret, l:ret)

        " Save numbered lists.
        let s:prev_numbered_list = l:ret[1:10]
    endif

    return l:ret
endfunction"}}}

function! s:NeoComplCache.Caching(srcname, start_line, end_line)"{{{
    let l:start_line = (a:start_line == '%')? line('.') : a:start_line
    let l:start_line = (l:start_line-1)/g:NeoComplCache_CacheLineCount*g:NeoComplCache_CacheLineCount+1
    let l:end_line = (a:end_line < 0)? '$' : 
                \ (l:start_line + a:end_line + g:NeoComplCache_CacheLineCount-2)/g:NeoComplCache_CacheLineCount*g:NeoComplCache_CacheLineCount

    " Check exists s:source.
    if !has_key(s:source, a:srcname)
        " Initialize source.
        call s:InitializeSource(a:srcname)
    endif

    let l:source = s:source[a:srcname]
    if a:srcname =~ '^\d'
        " Buffer.
        if empty(l:source.name)
            let l:filename = '[NoName]'
        else
            let l:filename = l:source.name
        endif
    else
        " Dictionary or tags.
        if a:srcname =~ '^tags'
            let l:prefix = '[T] '
        elseif a:srcname =~ '^dict'
            let l:prefix = '[B] '
        else
            let l:prefix = '[F] '
        endif
        let l:filename = l:prefix . fnamemodify(l:source.name, ':t')
    endif
    let l:cache_line = (l:start_line-1) / g:NeoComplCache_CacheLineCount
    let l:line_cnt = 0

    " For Debugging.
    "if l:end_line == '$'
        "echo printf("%s: start=%d, end=%d", l:filename, l:start_line, l:source.end_line)
    "else
        "echo printf("%s: start=%d, end=%d", l:filename, l:start_line, l:end_line)
    "endif

    if a:start_line == 1 && a:end_line < 0
        " Cache clear if whole buffer.
        let l:source.keyword_cache = {}
        let l:source.rank_cache_lines = {}
    endif

    " Clear cache line.
    let l:source.rank_cache_lines[l:cache_line] = {}

    if a:srcname =~ '^\d'
        " Buffer.
        let l:buflines = getbufline(a:srcname, l:start_line, l:end_line)
    else
        if l:end_line == '$'
            let l:end_line = l:source.end_line
        endif
        " Dictionary or tags.
        let l:buflines = readfile(l:source.name)[l:start_line : l:end_line]
    endif
    if g:NeoComplCache_DrawWordsRank
        let l:menu = printf('%.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    else
        let l:menu = ''
    endif
    let l:abbr_pattern = '%.' . g:NeoComplCache_MaxKeywordWidth . 's'
    let l:keyword_pattern = s:GetKeywordPattern(a:srcname)

    let [l:max_line, l:line_num] = [len(l:buflines), 0]
    while l:line_num < l:max_line
        if l:line_cnt >= g:NeoComplCache_CacheLineCount
            " Next cache line.
            let l:cache_line += 1
            let l:source.rank_cache_lines[l:cache_line] = {}
            let l:line_cnt = 0
        endif

        let l:line = buflines[l:line_num]
        let [l:match_num, l:match_end] = [match(l:line, l:keyword_pattern), matchend(l:line, l:keyword_pattern)]
        while l:match_num >= 0
            let l:match_str = matchstr(l:line, l:keyword_pattern, l:match_num)

            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
                " Check dup.
                if !has_key(l:source.keyword_cache, l:match_str)
                    " Append list.
                    let l:source.keyword_cache[l:match_str] = { 'word' : l:match_str, 'abbr' : printf(l:abbr_pattern, l:match_str), 'menu' : l:menu,  'dup' : 0, 'filename' : l:filename, 'srcname' : a:srcname }

                    let l:source.rank_cache_lines[l:cache_line][l:match_str] = 1
                elseif !has_key(l:source.rank_cache_lines[l:cache_line], l:match_str) 
                    let l:source.rank_cache_lines[l:cache_line][l:match_str] = 1
                else
                    let l:source.rank_cache_lines[l:cache_line][l:match_str] += 1
                endif
            endif

            " Next match.
            let [l:match_num, l:match_end] = [l:match_end, matchend(l:line, l:keyword_pattern, l:match_end)]
        endwhile

        let l:line_num += 1
        let l:line_cnt += 1
    endwhile
endfunction"}}}

function! s:InitializeSource(srcname)"{{{
    if a:srcname =~ '^\d'
        " Buffer.
        let l:filename = fnamemodify(bufname(a:srcname), ':t')
    else
        " Dictionary or tags.
        let l:filename = split(a:srcname, ',')[1]
    endif

    if a:srcname == bufnr('%')
        " Current buffer.
        let l:end_line = line('$')
    elseif a:srcname =~ '^\d'
        " Other buffer.
        let l:end_line = len(getbufline(a:srcname, 1, '$'))
    else
        " Dictionary or tags.
        let l:end_line = len(readfile(l:filename))
    endif

    let s:source[a:srcname] = { 'keyword_cache' : {}, 'rank_cache_lines' : {}, 'name' : l:filename, 'end_line' : l:end_line , 'cached_last_line' : 1, }
endfunction"}}}

function! s:NeoComplCache.CachingSource(srcname, start_line, end_line)"{{{
    if !has_key(s:source, a:srcname)
        " Initialize source.
        call s:InitializeSource(a:srcname)
    endif

    if a:start_line == '^'
        let l:source = s:source[a:srcname]

        if a:srcname =~ '^\d'
            " Buffer.
            let l:filename = fnamemodify(bufname(a:srcname), ':t')

            " Cache clear when Buffer Renamed.
            if l:filename != l:source.name
                " Buffer name caching.
                let l:source.cached_last_line = 1
                let l:source.name = l:filename
                let l:source.end_line = len(getbufline(a:srcname, 1, '$'))
                call remove(l:source, 'keyword_pattern')
                call s:GetKeywordPattern(a:srcname)
            endif
        endif
        
        let l:start_line = l:source.cached_last_line
        " Check overflow.
        if l:start_line > l:source.end_line
            " Caching end.
            return -1
        endif

        let l:source.cached_last_line += a:end_line
    else
        let l:start_line = a:start_line
    endif

    call s:NeoComplCache.Caching(a:srcname, l:start_line, a:end_line)

    return 0
endfunction"}}}

function! s:NeoComplCache.CachingAllBuffer(caching_num, caching_max)"{{{
    let l:bufnumber = 1
    let l:max_buf = bufnr('$')
    let l:caching_num = 0

    " Check new buffer.
    while l:bufnumber <= l:max_buf
        if buflisted(l:bufnumber)
            " Lazy caching.
            if s:NeoComplCache.CachingSource(l:bufnumber, '^', a:caching_num) == 0
                let l:caching_num += a:caching_num
                if l:caching_num > a:caching_num
                    break
                endif
            endif
       endif

        let l:bufnumber += 1
    endwhile

    " Check filetype dictionary.
    let l:ft_dict = (has_key(g:NeoComplCache_DictionaryFileTypeLists, &filetype))? &filetype : 'default'
    " Ignore if empty.
    if !empty(l:ft_dict) && l:caching_num < a:caching_max
        let l:dict_lists = split(g:NeoComplCache_DictionaryFileTypeLists[l:ft_dict], ',')
        for dict in l:dict_lists
            let l:dict_name = printf('%s,%s', l:ft_dict, dict)
            if (has_key(s:source, l:dict_name) || filereadable(dict)) && l:caching_num < a:caching_max
                " Lazy caching.
                if s:NeoComplCache.CachingSource(l:dict_name, '^', a:caching_num) == 0
                    let l:caching_num += a:caching_num
                endif
            endif
        endfor
    endif

    " Check buffer dictionary.
    if has_key(g:NeoComplCache_DictionaryBufferLists, bufnr('%')) && l:caching_num < a:caching_max
        let l:dict_lists = split(g:NeoComplCache_DictionaryBufferLists[bufnr('%')], ',')
        for dict in l:dict_lists
            let l:dict_name = printf('dict%s,%s', bufnr('%'), dict)
            if (has_key(s:source, l:dict_name) || filereadable(dict)) && l:caching_num < a:caching_max
                " Lazy caching.
                if s:NeoComplCache.CachingSource(l:dict_name, '^', a:caching_num) == 0
                    let l:caching_num += a:caching_num
                endif
            endif
        endfor
    endif

    " Check tags.
    let l:current_tags = (has_key(g:NeoComplCache_TagsLists, tabpagenr()))? tabpagenr() : 'default'
    " Ignore if empty.
    if !empty(l:current_tags) && l:caching_num < a:caching_max
        let l:tags_lists = split(g:NeoComplCache_TagsLists[l:current_tags], ',')
        for tags in l:tags_lists
            let l:tags_name = printf('tags%d,%s', l:current_tags, tags)
            if (has_key(s:source, l:tags_name) || filereadable(tags)) 
                " Lazy caching.
                if s:NeoComplCache.CachingSource(l:tags_name, '^', a:caching_num) == 0
                    let l:caching_num += a:caching_num
                endif

                " Check tags update.
                let l:len = len(readfile(tags))
                if l:len != s:source[l:tags_name].end_line
                    let s:source[l:tags_name].end_line = l:len
                    let s:source[l:tags_name].cached_last_line = 1
                endif
            endif
        endfor
    endif

    " Check deleted buffer.
    for key in keys(s:source)
        if key =~ '^\d' && !buflisted(str2nr(key))
            " Remove item.
            call remove(s:source, key)
        endif
    endfor
endfunction"}}}

function! s:GetKeywordPattern(srcname)"{{{
    let l:source = s:source[a:srcname]
    if !has_key(l:source, 'keyword_pattern')
        if a:srcname =~ '^\d'
            " Buffer.
            let l:ft = getbufvar(a:srcname, '&filetype')
        else
            " Dictionary or tags.
            
            let l:ext = fnamemodify(split(a:srcname, ',')[1], ':e')
            if empty(l:ext)
                let l:ext = fnamemodify(split(a:srcname, ',')[1], ':t')
            endif

            if has_key(g:NeoComplCache_NonBufferFileTypeDetect, l:ext)
                let l:ft = g:NeoComplCache_NonBufferFileTypeDetect[l:ext]
            elseif has_key(g:NeoComplCache_KeywordPatterns, l:ext)
                let l:ft = g:NeoComplCache_KeywordPatterns[l:ext]
            else
                " Assume filetype.
                if a:srcname =~ '^tags' || a:srcname =~ '^dict'
                    " Current buffer filetype.
                    let l:ft = &filetype
                else
                    " Embeded filetype.
                    let l:ft = split(a:srcname, ',')[0]
                endif
            endif
        endif

        let l:source.keyword_pattern = has_key(g:NeoComplCache_KeywordPatterns, l:ft)? 
                    \g:NeoComplCache_KeywordPatterns[l:ft] : g:NeoComplCache_KeywordPatterns['default']
    endif

    return l:source.keyword_pattern
endfunction"}}}
function! s:SetKeywordPattern(filetype, pattern)"{{{
    if !has_key(g:NeoComplCache_KeywordPatterns, a:filetype) 
        let g:NeoComplCache_KeywordPatterns[a:filetype] = a:pattern
    endif
endfunction"}}}

function! s:GetCompleFuncPattern()"{{{
    return has_key(g:NeoComplCache_CompleteFuncLists, &filetype)? 
                \g:NeoComplCache_CompleteFuncLists[&filetype] : g:NeoComplCache_CompleteFuncLists['default']
endfunction"}}}

function! s:NeoComplCache.Enable()"{{{
    augroup NeoCompleCache
        autocmd!
        " Caching events
        autocmd BufReadPost,BufWritePost,CursorHold * call s:NeoComplCache.CachingAllBuffer(g:NeoComplCache_CacheLineCount*5, 
                    \ g:NeoComplCache_CacheLineCount*15)
        " Caching current buffer events
        autocmd InsertEnter * call s:NeoComplCache.Caching(bufnr('%'), '%', g:NeoComplCache_CacheLineCount)
        " Auto complete events
        autocmd CursorMovedI,InsertEnter * call s:NeoComplCache.Complete()
    augroup END

    " Initialize
    let s:complete_lock = 0
    let s:old_text = ''
    let s:source = {}
    let s:prev_numbered_list = []
    let s:rank_cache_count = 0

    " Initialize keyword pattern match like intellisense.
    if !exists('g:NeoComplCache_KeywordPatterns')
        let g:NeoComplCache_KeywordPatterns = {}
    endif
    call s:SetKeywordPattern('default', '[[:alpha:]_.]\w*')
    call s:SetKeywordPattern('lisp', '\h[[:alnum:]_-]*[*!?]\=')
    call s:SetKeywordPattern('scheme', '\h[[:alnum:]_-]*[*!?]\=')
    call s:SetKeywordPattern('ruby', '\([[:alpha:]_$.]\|@@\=\)\([[:alnum:]_]\|::\)*[!?]\=')
    call s:SetKeywordPattern('php', '[[:alpha:]_$]\w*')
    call s:SetKeywordPattern('perl', '\(->\|[[:alpha:]_$@%]\)\([[:alnum:]_]\|::\)*')
    call s:SetKeywordPattern('vim', '$\w\+\|&\=[[:alpha:]_.][[:alnum:]#_:]*')
    call s:SetKeywordPattern('tex', '\\\=[[:alpha:]_]\w*[*]\=')
    call s:SetKeywordPattern('sh', '$\w\+\|[[:alpha:]_.-][[:alnum:]_.-]*')
    call s:SetKeywordPattern('zsh', '$\w\+\|[[:alpha:]_.-][[:alnum:]_.-]*')
    call s:SetKeywordPattern('vimshell', '$\w\+\|[[:alpha:]_.-][[:alnum:]_.-]*')
    call s:SetKeywordPattern('ps1', '$\w\+\|[[:alpha:]_.-][[:alnum:]_.-]*')
    call s:SetKeywordPattern('c', '[[:alpha:]_#.]\w*')
    call s:SetKeywordPattern('cpp', '\(::\|->\|[[:alpha:]_#.]\)\(\w\|::\)*')
    call s:SetKeywordPattern('d', '[[:alpha:]_#.]\(\w\|::\)*!\=')

    " Initialize assume file type lists.
    if !exists('g:NeoComplCache_NonBufferFileTypeDetect')
        let g:NeoComplCache_NonBufferFileTypeDetect = {}
    endif
    " For test.
    let g:NeoComplCache_NonBufferFileTypeDetect['rb'] = 'ruby'

    " Initialize dictionary and tags.
    if !exists('g:NeoComplCache_DictionaryFileTypeLists')
        let g:NeoComplCache_DictionaryFileTypeLists = {}
    endif
    if !has_key(g:NeoComplCache_DictionaryFileTypeLists, 'default')
        let g:NeoComplCache_DictionaryFileTypeLists['default'] = ''
    endif
    if !exists('g:NeoComplCache_DictionaryBufferLists')
        let g:NeoComplCache_DictionaryBufferLists = {}
    endif
    if !exists('g:NeoComplCache_TagsLists')
        let g:NeoComplCache_TagsLists = {}
    endif
    if !has_key(g:NeoComplCache_TagsLists, 'default')
        let g:NeoComplCache_TagsLists['default'] = ''
    endif
    " For test.
    "let g:NeoComplCache_DictionaryFileTypeLists['vim'] = 'CSApprox.vim,LargeFile.vim'
    "let g:NeoComplCache_TagsLists[1] = 'tags,'.$DOTVIM.'\doc\tags'
    "let g:NeoComplCache_DictionaryBufferLists[1] = '256colors2.pl'
    
    " Customizable complete function.
    if !exists('g:NeoComplCache_CompleteFuncLists')
        let g:NeoComplCache_CompleteFuncLists = {}
    endif
    if !has_key(g:NeoComplCache_CompleteFuncLists, 'default')
        let g:NeoComplCache_CompleteFuncLists['default'] = ['g:NeoComplCache_NormalComplete']
    endif

    " Add command.
    command! -nargs=0 NeoCompleCacheCachingBuffer call s:NeoComplCache.CachingCurrentBuffer()
    command! -nargs=0 NeoCompleCacheCachingTags call s:NeoComplCache.CachingTags()
    command! -nargs=0 NeoCompleCacheCachingDictionary call s:NeoComplCache.CachingDictionary()
    command! -nargs=0 Neco echo "   A A\n~(-'_'-)"
    command! -nargs=0 NeoCompleCacheLock call s:NeoComplCache.Lock()
    command! -nargs=0 NeoCompleCacheUnlock call s:NeoComplCache.Unlock()

    " Must g:NeoComplCache_StartCharLength > 1.
    if g:NeoComplCache_KeywordCompletionStartLength < 1
        g:NeoComplCache_KeywordCompletionStartLength = 1
    endif
    " Must g:NeoComplCache_MinKeywordLength > 1.
    if g:NeoComplCache_MinKeywordLength < 1
        g:NeoComplCache_MinKeywordLength = 1
    endif

    " Save options.
    let s:completefunc_save = &completefunc

    " Set completefunc.
    let &completefunc = 'g:NeoComplCache_ManualCompleteFunc'

    " Initialize cache.
    call s:NeoComplCache.CachingAllBuffer(g:NeoComplCache_CacheLineCount*5, g:NeoComplCache_CacheLineCount*15)
endfunction"}}}

function! s:NeoComplCache.Disable()"{{{
    " Restore options.
    let &completefunc = s:completefunc_save
    
    augroup NeoCompleCache
        autocmd!
    augroup END

    delcommand NeoCompleCacheCachingBuffer
    delcommand NeoCompleCacheCachingTags
    delcommand NeoCompleCacheCachingDictionary
    delcommand Neco
    delcommand NeoCompleCacheLock
    delcommand NeoCompleCacheUnlock
endfunction"}}}

function! s:NeoComplCache.Toggle()"{{{
    if s:disable_neocomplcache
        let s:disable_neocomplcache = 0
        call s:NeoComplCache.Enable()
    else
        let s:disable_neocomplcache = 1
        call s:NeoComplCache.Disable()
    endif
endfunction"}}}

function! s:NeoComplCache.CachingCurrentBuffer()"{{{
    let l:current_buf = bufnr('%')
    call s:NeoComplCache.CachingSource(l:current_buf, 1, -1)

    " Disable auto caching.
    let s:source[l:current_buf].cached_last_line = s:source[l:current_buf].end_line+1
endfunction"}}}

function! s:NeoComplCache.CachingTags()"{{{
    " Create source.
    call s:NeoComplCache.CachingAllBuffer(g:NeoComplCache_CacheLineCount*5, g:NeoComplCache_CacheLineCount*15)
    
    " Check tags are exists.
    if has_key(g:NeoComplCache_TagsLists, tabpagenr())
        let l:tags = '^tags' . tabpagenr()
    elseif !empty(g:NeoComplCache_TagsLists['default'])
        let l:tags = '^tagsdefault'
    else
        " Dummy pattern.
        let l:tags = '^$'
    endif
    let l:cache_keyword_buffer_filtered = []
    for key in keys(s:source)
        if key =~ l:tags
            call s:NeoComplCache.CachingSource(key, '^', -1)

            " Disable auto caching.
            let s:source[key].cached_last_line = s:source[key].end_line+1
        endif
    endfor
endfunction"}}}

function! s:NeoComplCache.CachingDictionary()"{{{
    " Create source.
    call s:NeoComplCache.CachingAllBuffer(g:NeoComplCache_CacheLineCount*5, g:NeoComplCache_CacheLineCount*15)

    " Check dictionaries are exists.
    if !empty(&filetype) && has_key(g:NeoComplCache_DictionaryFileTypeLists, &filetype)
        let l:ft_dict = '^' . &filetype
    elseif !empty(g:NeoComplCache_DictionaryFileTypeLists['default'])
        let l:ft_dict = '^default'
    else
        " Dummy pattern.
        let l:ft_dict = '^$'
    endif
    if has_key(g:NeoComplCache_DictionaryBufferLists, bufnr('%'))
        let l:buf_dict = '^dict' . bufnr('%')
    else
        " Dummy pattern.
        let l:buf_dict = '^$'
    endif
    let l:cache_keyword_buffer_filtered = []
    for key in keys(s:source)
        if key =~ l:ft_dict || key =~ l:buf_dict
            call s:NeoComplCache.CachingSource(key, '^', -1)

            " Disable auto caching.
            let s:source[key].cached_last_line = s:source[key].end_line+1
        endif
    endfor
endfunction"}}}

function! s:NeoComplCache.Lock()"{{{
    let s:complete_lock = 1
endfunction"}}}

function! s:NeoComplCache.Unlock()"{{{
    let s:complete_lock = 0
endfunction"}}}

" Global options definition."{{{
if !exists('g:NeoComplCache_MaxList')
    let g:NeoComplCache_MaxList = 100
endif
if !exists('g:NeoComplCache_MaxKeywordWidth')
    let g:NeoComplCache_MaxKeywordWidth = 50
endif
if !exists('g:NeoComplCache_MaxFilenameWidth')
    let g:NeoComplCache_MaxFilenameWidth = 15
endif
if !exists('g:NeoComplCache_PartialMatch')
    let g:NeoComplCache_PartialMatch = 1
endif
if !exists('g:NeoComplCache_KeywordCompletionStartLength')
    let g:NeoComplCache_KeywordCompletionStartLength = 2
endif
if !exists('g:NeoComplCache_MinKeywordLength')
    let g:NeoComplCache_MinKeywordLength = 4
endif
if !exists('g:NeoComplCache_FilenameCompletionStartLength')
    let g:NeoComplCache_FilenameCompletionStartLength = 0
endif
if !exists('g:NeoComplCache_IgnoreCase')
    let g:NeoComplCache_IgnoreCase = 1
endif
if !exists('g:NeoComplCache_DrawWordsRank')
    let g:NeoComplCache_DrawWordsRank = 1
endif
if !exists('g:NeoComplCache_AlphabeticalOrder')
    let g:NeoComplCache_AlphabeticalOrder = 0
endif
if !exists('g:NeoComplCache_FirstCurrentBufferWords')
    let g:NeoComplCache_FirstCurrentBufferWords = 1
endif
if !exists('g:NeoComplCache_CacheLineCount')
    let g:NeoComplCache_CacheLineCount = 30
endif
if !exists('g:NeoComplCache_DeleteRank0')
    let g:NeoComplCache_DeleteRank0 = 0
endif
if !exists('g:NeoComplCache_DisableAutoComplete')
    let g:NeoComplCache_DisableAutoComplete = 0
endif
if !exists('g:NeoComplCache_EnableAsterisk')
    let g:NeoComplCache_EnableAsterisk = 1
endif
if !exists('g:NeoComplCache_QuickMatch')
    let g:NeoComplCache_QuickMatch = 1
endif
if !exists('g:NeoComplCache_CalcRankCount')
    let g:NeoComplCache_CalcRankCount = 5
endif
if !exists('g:NeoComplCache_CalcRankMaxLists')
    let g:NeoComplCache_CalcRankMaxLists = 40
endif
if !exists('g:NeoComplCache_SlowCompleteSkip')
    if has('reltime')
        let g:NeoComplCache_SlowCompleteSkip = 1
    else
        let g:NeoComplCache_SlowCompleteSkip = 0
    endif
endif

if exists('g:NeoComplCache_EnableAtStartup') && g:NeoComplCache_EnableAtStartup
    " Enable startup.
    call s:NeoComplCache.Enable()
endif"}}}

let g:loaded_neocomplcache = 1

" vim: foldmethod=marker
