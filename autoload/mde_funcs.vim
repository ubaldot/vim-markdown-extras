vim9script

import autoload './mde_constants.vim' as constants
import autoload './mde_utils.vim' as utils
import autoload './mde_highlight.vim' as highlight
import autoload './mde_links.vim' as links

var visited_buffers = []
var visited_buffers_max_length = 100

export def GoToPrevVisitedBuffer()
  if len(visited_buffers) > 1
    remove(visited_buffers, -1)
    exe $"buffer {visited_buffers[-1]}"
  endif
  # echom visited_buffers
enddef

export def AddVisitedBuffer()
    if empty(visited_buffers) || bufnr() != visited_buffers[-1]
      if len(visited_buffers) > visited_buffers_max_length
        remove(visited_buffers, 0)
      endif
      add(visited_buffers, bufnr())
    endif
    # echom visited_buffers
enddef

export def RemoveVisitedBuffer(bufnr: number)
    var tmp = copy(visited_buffers)
    if !empty(tmp)
      tmp->filter($"v:val != {bufnr}")
    endif

    # Remove consecutive duplicates
    visited_buffers = []
    for ii in range(len(tmp))
        if ii == 0 || tmp[ii] != tmp[ii - 1]
            add(visited_buffers, tmp[ii])
        endif
    endfor
    # echom visited_buffers
enddef

export def ToggleMark()
  # Toggle checkbox marks in todo lists

  var line = getline('.')
  if match(line, '\[\s*\]') != -1
    setline('.', substitute(line, '\[\s*\]', '[x]', ''))
  elseif match(line, '\[x\]') != -1
    setline('.', substitute(line, '\[x\]', '[ ]', ''))
  endif
enddef

export def CR_Hacked()
  if getline(line('.')) !~ '^\s*|'
    # Needed for hacking <CR> when you are writing a list
    #
    # Check if the current line starts with '- [ ]' or '- '
    # OBS! If there are issues, check 'formatlistpat' value for markdown
    # filetype
    # OBS! The following scan the current line through the less general regex (a
    # regex can be contained in another regex)
    # Split the line in the cursor and decide what to when you press <cr>.
    # If you are in an itemized list, preserve the leading spaces and prepend
    # the itemize symbol to the second_chunk.
    var variant_1 = '-\s\[\(\s*\|x\)*\]\s\+' # - [ ] bla bla bla
    var variant_2 = '-\s\+\(\[\)\@!' # - bla bla bla
    var variant_3 = '\*\s\+' # * bla bla bla
    var variant_4 = '\d\+\.\s\+' # 123. bla bla bla
    var variant_5 = '>\s\+' # Quoted block

    def GetItemSymbol(current_line: string): string
      # Return itemize symbol, i.e. -, - [ ], *, 123., >
      var item_symbol = ''
      if current_line =~ $'^\s*{variant_1}'
        # If - [x], the next item should be - [ ] anyway.
        item_symbol = $"{current_line->matchstr($'^\s*{variant_1}')
              \ ->substitute('x', ' ', 'g')}"
      elseif current_line =~ $'^\s*{variant_2}'
        item_symbol = $"{current_line->matchstr($'^\s*{variant_2}')}"
      elseif current_line =~ $'^\s*{variant_3}'
        item_symbol = $"{current_line->matchstr($'^\s*{variant_3}')}"
      elseif current_line =~ $'^\s*{variant_5}'
        item_symbol = $"{current_line->matchstr($'^\s*{variant_5}')}"
      elseif current_line =~ $'^\s*{variant_4}'
        # Get rid of the trailing '.' and convert to number
        var curr_nr = str2nr(
          $"{current_line->matchstr($'^\s*{variant_4}')->matchstr('\d\+')}"
        )
        item_symbol = $"{current_line->matchstr($'^\s*{variant_4}')
              \ ->substitute(string(curr_nr), string(curr_nr + 1), '')}"
      endif
      return item_symbol
    enddef

    # Break line at cursor position, e.g.
    #   'today is a <curpos> beautiful day'
    # results im:
    #   first_chunk = 'today is a '
    #   second_chunk = ' beautiful day'
    var first_chunk = strcharpart(getline('.'), 0, charcol('.') - 1)
    var second_chunk = strcharpart(getline('.'), charcol('.') - 1)


    # Handle different cases if the current line is an item of a list
    var line_nr = line('.')
    var current_line = getline(line_nr)
    var item_symbol = GetItemSymbol(current_line)
    # If current line is indendent with at least 2 spaces
    if current_line =~ '^\s\{2,}'
      while current_line !~ '^\s*$' && line_nr != 0 && empty(item_symbol)
        line_nr -= 1
        current_line = getline(line_nr)
        item_symbol = GetItemSymbol(current_line)
        # echom item_symbol
        if !empty(item_symbol)
          break
        endif
      endwhile
    endif

    # if item_symbol = '' it may still mean that we are not in an item list but
    # yet we have an indendent line, hence, we must preserve the leading spaces
    if empty(item_symbol)
      item_symbol = $"{getline('.')->matchstr($'^\s\+')}"
    endif

    # The following is in case the cursor is on the lhs of the item_symbol
    if charcol('.') < strchars(item_symbol)
      if current_line =~ $'^\s*{variant_4}'
        first_chunk = $"{current_line->matchstr($'^\s*{variant_4}')}"
        second_chunk = strcharpart(current_line, strchars(item_symbol))
      else
        first_chunk = item_symbol
        second_chunk = strcharpart(current_line, strchars(item_symbol))
      endif
    endif

    # double <cr> equal to finish the itemization
    if getline('.') == item_symbol || getline('.') =~ '^\s*\d\+\.\s*$'
      first_chunk = ''
      item_symbol = ''
    endif

    # Add the correct lines
    setline(line('.'), first_chunk)
    append(line('.'), item_symbol .. second_chunk)
    cursor(line('.') + 1, strchars(item_symbol) + 1)
    startinsert
  else
    # Table handling
    messages clear
    var curpos = getcursorcharpos()[1 : 2]
    var cell_del_in = searchpos('|', 'b')[1]
    var cell_del_out = searchpos('|')[1]
    var cell_nr = strcharpart(getline(line('.')), 0, charcol('.') - 1)->filter("v:val == '|'")->len()
    # echom "cell_del_out: " .. cell_del_out
    # echom "cell_nr: " .. cell_nr

    setcursorcharpos(curpos)
    var carry_over = strcharpart(getline(line('.')), col('.') - 1, cell_del_out - col('.'))

    var current_line = strcharpart(getline(line('.')), 0, charcol('.') - 1)
            .. ' ' .. strcharpart(getline(line('.')), charcol('.') + len(carry_over) - 1)

    var next_line = strcharpart(getline(line('.')), 0, cell_del_in)->substitute('[^|]', ' ', 'g')
    .. ' ' .. carry_over  .. strcharpart(getline(line('.')), charcol('.') - 1)->substitute('[^|]', '', 'g')

    setline(line('.'), current_line)
    append(line('.'), next_line)
    setcursorcharpos(line('.') + 1, cell_del_in + 2)
#     var first_line = strcharpart(getline(line('.')), 0, charcol('.') - 1)
# ..strcharpart(getline(line('.')), charcol('.'), col('$') - 1)->substitute('[^|]', ' ', 'g')

#     var second_line =  strcharpart(getline(line('.')), charcol('.'), col('$') - 1)->substitute('[^|]', '', 'g')

#     for _ in range(cell_nr)
#       search('|')
#     endfor
#     var target_pos = [line('.') + 1, col('.') + 2]

#     append(line('.'), first_chunk .. second_chunk)
#     cursor(target_pos)
#     norm! dt|
  endif
enddef

export def RemoveAll()
  # TODO could be refactored to increase speed, but it may not be necessary
  const range_info = utils.IsInRange()
  const prop_info = highlight.IsOnProp()
  const syn_info = synIDattr(synID(line("."), charcol("."), 1), "name")
  const is_quote_block = getline('.') =~ '^>\s'

  # If on plain text, do nothing
  if empty(range_info) && empty(prop_info)
        && syn_info != 'markdownCodeBlock' && !is_quote_block
    return
  endif

  # Start removing the text props
  if !empty(prop_info)
    prop_remove({'id': prop_info.id, 'all': 0})
    return
  endif

  # Check markdownCodeBlocks
  if syn_info == 'markdownCodeBlock'
    utils.UnsetBlock(syn_info)
    return
  endif

  # Text styles removal setup
  if !empty(range_info)
    const target = keys(range_info)[0]
    var text_styles = copy(constants.TEXT_STYLES_DICT)
    unlet text_styles['markdownLinkText']

    if index(keys(text_styles), target) != -1
      utils.RemoveSurrounding(range_info)
    elseif target == 'markdownLinkText'
      links.RemoveLink()
    endif
    return
  endif

  if is_quote_block
    utils.UnsetQuoteBlock()
  endif
enddef

# ---- auto-completion --------------
export def OmniFunc(findstart: number, base: string): any
    # Define the dictionary
    b:markdown_extras_links = links.RefreshLinksDict()

    if findstart == 1
        # Find the start of the word
        var line = getline('.')
        var start = charcol('.')
        while start > 1 && getline('.')[start - 1] =~ '\d'
            start -= 1
        endwhile
        return start
    else
        var matches = []
        for key in keys(b:markdown_extras_links)
            add(matches, {word: $'{key}]', menu: b:markdown_extras_links[key]})
        endfor
        return {words: matches}
    endif
enddef
