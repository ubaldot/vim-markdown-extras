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

  var current_line = join(
  getline(
  search($'\({variant_1}\|{variant_2}\|{variant_3}\|{variant_4}\|\n\n\)', 'bn'),
  line('.')),
    '\n')

  # Check if the current line is an item or not and check if there is only a
  # bullet or a bullet + some text
  # There is only a buller with no text. Next <CR> shall remove the bullet
  var is_item = false
  var only_bullet = false
  # Check if you only have the bullet with no item
  for variant in [variant_1, variant_2, variant_3, variant_4]
    if current_line =~ $'^\s*{variant}\s*$'
          is_item = true
          only_bullet = true
          break
    elseif current_line =~ $'^\s*{variant}\s*'
      is_item = true
      break
    else
      is_item = false
    endif
  endfor

  echom is_item

  # Scan the current line through the less general regex (a regex can be
  # contained in another regex)
  var this_line = is_item ? strcharpart(current_line, 0, col('.') - 1) : ''
  var next_line = is_item ? strcharpart(current_line, col('.') - 1) : ''
  var item_symbol = ''
  if is_item && !only_bullet
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
  elseif is_item && only_bullet
    this_line = ''
    next_line = ''
  else
    this_line = getline('.')
    next_line = ''
  endif

  # Add the correct newline
  setline(line('.'), this_line)
  append(line('.'), item_symbol .. next_line)
  cursor(line('.') + 1, len(item_symbol) + 1)
  startinsert

enddef
