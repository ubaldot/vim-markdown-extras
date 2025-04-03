vim9script

import autoload './constants.vim'
import autoload './utils.vim'
import autoload './highlight.vim'
import autoload './links.vim'

var visited_buffers = []
var visited_buffer_max_length = 100

export def GoToPrevVisitedBuffer()
  if len(visited_buffers) > 1
    remove(visited_buffers, -1)
    exe $"buffer {visited_buffers[-1]}"
  endif
  # echom visited_buffers
enddef

export def AddVisitedBuffer()
    if empty(visited_buffers) || bufnr() != visited_buffers[-1]
      if len(visited_buffers) > visited_buffer_max_length
        remove(visited_buffers, 0)
      endif
      add(visited_buffers, bufnr())
    endif
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
  # Needed for hacking <CR> when you are writing a list
  #
  # Check if the current line starts with '- [ ]' or '- '
  # OBS! If there are issues, check 'formatlistpat' value for markdown
  # filetype
  var variant_1 = '-\s\[\(\s*\|x\)*\]\s\+' # - [ ] bla bla bla
  var variant_2 = '-\s\+\(\[\)\@!' # - bla bla bla
  var variant_3 = '\*\s\+' # * bla bla bla
  var variant_4 = '\d\+\.\s\+' # 123. bla bla bla
  var variant_5 = '>\s\+' # Quoted block

  def GetItemSymbol(current_line: string): string
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
    # elseif current_line =~ $'^\s\+'
    #   item_symbol = $"{current_line->matchstr($'^\s\+')}"
    endif
    return item_symbol
  enddef

  # Break line at cursor position
  var this_line = strcharpart(getline('.'), 0, col('.') - 1)
  var next_line = strcharpart(getline('.'), col('.') - 1)

  # Check if the current line is an item.
  # OBS! The following scan the current line through the less general regex (a
  # regex can be contained in another regex)
  # TODO: search back the previous \n
  # var is_item = false
  # for variant in [variant_1, variant_2, variant_3, variant_4, variant_5]
  #   if current_line =~ $'^\s*{variant}\s*'
  #     is_item = true
  #     break
  #   endif
  # endfor

  # Handle different cases if the current line is an item of a list
  var line_nr = line('.')
  var current_line = getline(line_nr)
  var item_symbol = GetItemSymbol(current_line)
  if current_line =~ '^\s\{2,}'
    while current_line !~ '^\s*$' && line_nr != 0 && empty(item_symbol)
      line_nr -= 1
      current_line = getline(line_nr)
      item_symbol = GetItemSymbol(current_line)
      echom item_symbol
      if !empty(item_symbol)
        break
      endif
    endwhile
  endif

  # The following is in case the cursor is on the lhs of the item_symbol
  if col('.') < len(item_symbol)
    if current_line =~ $'^\s*{variant_4}'
      this_line = $"{current_line->matchstr($'^\s*{variant_4}')}"
      next_line = strcharpart(current_line, len(item_symbol))
    else
      this_line = item_symbol
      next_line = strcharpart(current_line, len(item_symbol))
    endif
  endif

  # double <cr> equal to finish the itemization
  if getline('.') == item_symbol || getline('.') =~ '^\s*\d\+\.\s*$'
    this_line = ''
    item_symbol = ''
  endif

  # Add the correct lines
  setline(line('.'), this_line)
  append(line('.'), item_symbol .. next_line)
  cursor(line('.') + 1, len(item_symbol) + 1)
  startinsert

enddef

export def RemoveAll()
  # TODO could be refactored to increase speed, but it may not be necessary
  const range_info = utils.IsInRange()
  const prop_info = highlight.IsOnProp()
  const syn_info = synIDattr(synID(line("."), col("."), 1), "name")
  const is_quote_block = getline('.') =~ '^>\s'

  # If on plain text, do nothing, just execute a normal! <BS>
  if empty(range_info) && empty(prop_info)
        && syn_info != 'markdownCodeBlock' && !is_quote_block
    exe "norm! \<BS>"
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
