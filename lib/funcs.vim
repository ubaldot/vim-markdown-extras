vim9script

export def ToggleMark()
  # Toggle checkbox marks in todo lists
  #
  var line = getline('.')
  if match(line, '\[\s*\]') != -1
    setline('.', substitute(line, '\[\s*\]', '[x]', ''))
  elseif match(line, '\[x\]') != -1
    setline('.', substitute(line, '\[x\]', '[ ]', ''))
  endif
enddef

export def ContinueList()
  # Needed for hacking <CR> when you are writing a list
  #
  # Check if the current line starts with '- [ ]' or '- '
  # OBS! If there are issues, check 'formatlistpat' value for markdown
  # filetype

  var variant_1 = '-\s\[\(\s*\|x\)*\]\s\+' # - [ ] bla bla bla
  var variant_2 = '-\s\+\(\[\)\@!' # - bla bla bla
  var variant_3 = '\*\s\+' # * bla bla bla
  var variant_4 = '\d\+\.\s\+' # 123. bla bla bla

  var current_line = getline('.')

  # Check if the current line is an item.
  # Scan the current line through the less general regex (a regex can be
  # contained in another regex)
  var is_item = false
  for variant in [variant_1, variant_2, variant_3, variant_4]
    if current_line =~ $'^\s*{variant}\s*'
      is_item = true
      break
    endif
  endfor

  # If the current line is not in an item list, act as normal,
  # i.e. <cr> = \n, otherwise split the current line depending on where is the
  # cursor
  var this_line = is_item
    ? strcharpart(getline('.'), 0, col('.') - 1)
    : getline('.')
  var next_line = is_item
    ? strcharpart(getline('.'), col('.') - 1)
    : ''

  # double <cr> equal to finish the itemization
  if this_line =~
      $'^\s*\({variant_1}\|{variant_2}\|{variant_3}\|{variant_4}\)\s*$'
      && next_line =~ '^\s*$'
    this_line = ''
    is_item = false
  endif

  # Handle different cases if the current line is an item of a list
  var item_symbol = ''
  if is_item
    if current_line =~ $'^\s*{variant_1}'
      # If - [x], the next item should be - [ ] anyway.
      item_symbol = $"{current_line->matchstr($'^\s*{variant_1}')
            \ ->substitute('x', ' ', 'g')}"
    elseif current_line =~ $'^\s*{variant_2}'
      item_symbol = $"{current_line->matchstr($'^\s*{variant_2}')}"
    elseif current_line =~ $'^\s*{variant_3}'
      item_symbol = $"{current_line->matchstr($'^\s*{variant_3}')}"
    elseif current_line =~ $'^\s*{variant_4}'
      # Get rid of the trailing '.' and convert to number
      var curr_nr = str2nr(
        $"{current_line->matchstr($'^\s*{variant_4}')->matchstr('\d\+')}"
      )
      item_symbol = $"{current_line->matchstr($'^\s*{variant_4}')
            \ ->substitute(string(curr_nr), string(curr_nr + 1), '')}"
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
  endif

  # Add the correct lines
  setline(line('.'), this_line)
  append(line('.'), item_symbol .. next_line)
  cursor(line('.') + 1, len(item_symbol) + 1)
  startinsert

enddef
