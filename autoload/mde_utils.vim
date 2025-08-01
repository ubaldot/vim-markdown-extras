vim9script

import autoload "./mde_constants.vim" as constants

export def Echoerr(msg: string)
  echohl ErrorMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

export def Echowarn(msg: string)
  echohl WarningMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

def UndoFormatting()
  if v:shell_error != 0
    undo
    Echoerr($"'{&l:formatprg->matchstr('^\s*\S*')}' returned errors.")
  else
    # Display format command
    redraw
    if !empty(&l:formatprg)
      echo $'{&l:formatprg}'
    else
      Echowarn("'formatprg' is empty. Using default formatter.")
    endif
  endif
enddef

export def FormatWithoutMoving(type: string = '')
  # 'gq' is remapped to use this function.
  # However, when running the 'gq' as formatter, we need to use as it is
  # shipped with Vim, and therefore we use the bang in 'normal!'
  var view = winsaveview()

  # defer so if the function gets error of any kind, the following are run
  # anyways
  defer UndoFormatting()
  defer winrestview(view)

  var start = 0
  var end = 0
  if type != ''
    start = line("'[")
    end = line("']")
  endif

  if start == 0 && end == 0
    normal! gggqG
  else
    var interval = end - start + 1
    silent exe $"normal! {start}gg{interval}gqq"
  endif
enddef

export def KeysFromValue(dict: dict<string>, target_value: string): list<string>
 # Given a value, return all the keys associated to it
 return keys(filter(copy(dict), $'v:val == "{escape(target_value, "\\")}"'))
enddef

export def RemoveSurrounding(range_info: dict<list<list<number>>> = {})
    const style_interval = empty(range_info) ? IsInRange() : range_info
    if !empty(style_interval)
      const style = keys(style_interval)[0]
      const interval = values(style_interval)[0]

      # Remove left delimiter
      const lA = interval[0][0]
      const cA = interval[0][1]
      const lineA = getline(lA)
      var newline = strcharpart(lineA, 0,
              \ cA - 1 - strchars(constants.TEXT_STYLES_DICT[style].open_delim))
              \ .. strcharpart(lineA, cA - 1)
      setline(lA, newline)

      # Remove right delimiter
      const lB = interval[1][0]
      var cB = interval[1][1]

      # Update cB.
      # If lA == lB, then The value of cB may no longer be valid since
      # we shortened the line
      if lA == lB
        cB = cB - strchars(constants.TEXT_STYLES_DICT[style].open_delim)
      endif

      # Check if you hit a delimiter or a blank line OR if you hit a delimiter
      # but you also have a blank like
      # If you have open intervals (as we do), then cB < lenght_of_line, If
      # not, then don't do anything. This behavior is compliant with
      # vim-surround
      const lineB = getline(lB)
      if  cB < strchars(lineB)
        # You have delimters
        newline = strcharpart(lineB, 0, cB)
              \ .. strcharpart(lineB,
                \ cB + strchars(constants.TEXT_STYLES_DICT[style].close_delim))
      else
        # You hit the end of paragraph
        newline = lineB
      endif
      setline(lB, newline)
    endif
enddef

export def SurroundSimple(style: string, type: string = '')

  if getcharpos("'[") == getcharpos("']")
    return
  endif

  var open_delim = constants.TEXT_STYLES_DICT[style].open_delim
  var close_delim = constants.TEXT_STYLES_DICT[style].close_delim

  # line and column of point A
  var lA = line("'[")
  var cA = charcol("'[")

  # line and column of point B
  var lB = line("']")
  var cB = charcol("']")

  var toA = strcharpart(getline(lA), 0, cA - 1) .. open_delim
  var fromB = close_delim .. strcharpart(getline(lB), cB)

  # If on the same line
  if lA == lB
    # Overwrite everything that is in the middle
    var A_to_B = strcharpart(getline(lA), cA - 1, cB - cA + 1)
    setline(lA, toA .. A_to_B .. fromB)
  else
    var lineA = toA .. strcharpart(getline(lA), cA - 1)
    setline(lA, lineA)
    var lineB = strcharpart(getline(lB), 0, cB - 1) .. fromB
    setline(lB, lineB)
    var ii = 1
    # Fix intermediate lines
    while lA + ii < lB
      setline(lA + ii, getline(lA + ii))
      ii += 1
    endwhile
  endif
enddef


export def SurroundSmart(style: string, type: string = '')
  # It tries to preserve the style.
  # In general, you may want to pass constant.TEXT_STYLES_DICT as a parameter.

  def RemoveDelimiters(to_overwrite: string): string
    # Used for removing all the delimiters between A and B.

    var overwritten = to_overwrite

    # This is needed to remove all existing text-styles between A and B, i.e. we
    # want to override existing styles.
    # Note that we don't want to remove links between A and B
    const styles_to_remove = keys(constants.TEXT_STYLES_DICT)
      ->filter("v:val !~ '\\v(markdownLinkText)'")

    for k in styles_to_remove
      # Remove existing open delimiters
      var regex = constants.TEXT_STYLES_DICT[k].open_regex
      var to_remove = constants.TEXT_STYLES_DICT[k].open_delim
      overwritten = overwritten
  ->substitute(regex, (m) => substitute(m[0], $'\V{to_remove}', '', 'g'), 'g')

      # Remove existing close delimiters
      regex = constants.TEXT_STYLES_DICT[k].close_regex
      to_remove = constants.TEXT_STYLES_DICT[k].close_delim
      overwritten = overwritten
  ->substitute(regex, (m) => substitute(m[0], $'\V{to_remove}', '', 'g'), 'g')
    endfor
    return overwritten
  enddef

  if getcharpos("'[") == getcharpos("']")
    return
  endif

  if index(keys(constants.TEXT_STYLES_DICT), style) == -1
    Echoerr($'Style "{style}" not found in dict')
    return
  endif

  var open_delim = constants.TEXT_STYLES_DICT[style].open_delim
  var open_regex = constants.TEXT_STYLES_DICT[style].open_regex

  var close_delim = constants.TEXT_STYLES_DICT[style].close_delim
  var close_regex = constants.TEXT_STYLES_DICT[style].close_regex

  # line and column of point A
  var lA = line("'[")
  var cA = type == 'line' ? 1 : charcol("'[")

  # line and column of point B
  var lB = line("']")
  var cB = type == 'line' ? strchars(getline(lB)) : charcol("']")

  # -------- SMART DELIMITERS BEGIN ---------------------------
  # We check conditions like the following and we adjust the style
  # delimiters
  # We assume that the existing style ranges are (C,D) and (E,F) and we want
  # to place (A,B) as in the picture
  #
  # -E-------A------------
  # ------------F---------
  # ------------C------B--
  # --------D-------------
  #
  # We want to get:
  #
  # -E------FA------------
  # ----------------------
  # ------------------BC--
  # --------D-------------
  #
  # so that all the styles are visible

  # Check if A falls in an existing interval
  cursor(lA, cA)
  var old_right_delimiter = ''
  var found_interval = IsInRange()
  if !empty(found_interval)
    var found_style = keys(found_interval)[0]
    old_right_delimiter = constants.TEXT_STYLES_DICT[found_style].open_delim
  endif

  # Try to preserve overlapping ranges by moving the delimiters.
  # For example. If we have the pairs (C, D) and (E,F) as it follows:
  # ------C-------D------E------F
  #  and we want to add (A, B) as it follows
  # ------C---A---D-----E--B---F
  #  then the results becomes a mess. The idea is to move D before A and E
  #  after E, thus obtaining:
  # ------C--DA-----------BE----F
  #
  # TODO:
  # If you don't want to try to automatically adjust existing ranges, then
  # remove 'old_right_delimiter' and 'old_left_limiter' from what follows,
  # AND don't remove anything between A and B
  #
  # TODO: the following is specifically designed for markdown, so if you use
  # for other languages, you may need to modify it!
  #
  var toA = ''
  if !empty(found_interval) && old_right_delimiter != open_delim
    toA = strcharpart(getline(lA), 0, cA - 1)->substitute('\s*$', '', '')
      .. $'{old_right_delimiter} {open_delim}'
  elseif !empty(found_interval) && old_right_delimiter == open_delim
    # If the found interval is a text style equal to the one you want to set,
    # i.e. you would end up in adjacent delimiters like ** ** => Remove both
    toA = strcharpart(getline(lA), 0, cA - 1)
  else
    # Force space
    toA = strcharpart(getline(lA), 0, cA - 1) .. open_delim
  endif

  # Check if B falls in an existing interval
  cursor(lB, cB)
  var old_left_delimiter = ''
  found_interval = IsInRange()
  if !empty(found_interval)
    var found_style = keys(found_interval)[0]
    old_left_delimiter = constants.TEXT_STYLES_DICT[found_style].close_delim
  endif

  var fromB = ''
  if !empty(found_interval) && old_left_delimiter != close_delim
    # Move old_left_delimiter "outside"
    fromB = $'{close_delim} {old_left_delimiter}'
      .. strcharpart(getline(lB), cB)->substitute('^\s*', '', '')
  elseif !empty(found_interval) && old_left_delimiter == close_delim
      fromB = strcharpart(getline(lB), cB)
  else
    fromB = close_delim .. strcharpart(getline(lB), cB)
  endif

  # ------- SMART DELIMITERS PART END -----------
  # We have compute the partial strings until A and the partial string that
  # leaves B. Existing delimiters are set.
  # Next, we have to adjust the text between A and B, by removing all the
  # possible delimiters left between them.


  # If on the same line
  if lA == lB
    # Overwrite everything that is in the middle
    var A_to_B = ''
    A_to_B = strcharpart(getline(lA), cA - 1, cB - cA + 1)

    # Overwrite existing styles in the middle by removing old delimiters
    if style != 'markdownCode'
      A_to_B = RemoveDelimiters(A_to_B)
    endif
    # echom $'toA: ' .. toA
    # echom $'fromB: ' .. fromB
    # echom $'A_to_B:' .. A_to_B
    # echom '----------\n'

    # Set the whole line
    setline(lA, toA .. A_to_B .. fromB)

  else
    # Set line A
    var afterA = strcharpart(getline(lA), cA - 1)

    if style != 'markdownCode'
      afterA = RemoveDelimiters(afterA)
    endif

    var lineA = toA .. afterA
    setline(lA, lineA)

    # Set line B
    var beforeB = strcharpart(getline(lB), 0, cB)

    if style != 'markdownCode'
      beforeB = RemoveDelimiters(beforeB)
    endif

    var lineB = beforeB .. fromB
    setline(lB, lineB)

    # Fix intermediate lines
    var ii = 1
    while lA + ii < lB
      var middleline = getline(lA + ii)

      if style != 'markdownCode'
        middleline = RemoveDelimiters(middleline)
      endif

      setline(lA + ii, middleline)
      ii += 1
    endwhile
  endif
enddef

export def IsLess(l1: list<number>, l2: list<number>): bool
  # Lexicographic comparison on common prefix, i.e.for two vectors in N^n and
  # N^m you compare their projections onto the smaller subspace.

  var min_length = min([len(l1), len(l2)])
  var result = false

  for ii in range(min_length)
    if l1[ii] < l2[ii]
      result = true
      break
    elseif l1[ii] > l2[ii]
      result = false
      break
    endif
  endfor
  return result
enddef

export def IsGreater(l1: list<number>, l2: list<number>): bool
  # Lexicographic comparison on common prefix, i.e.for two vectors in N^n and
  # N^m you compare their projections onto the smaller subspace.

  var min_length = min([len(l1), len(l2)])
  var result = false

  for ii in range(min_length)
    if l1[ii] > l2[ii]
      result = true
      break
    elseif l1[ii] < l2[ii]
      result = false
      break
    endif
  endfor
  return result
enddef

export def IsEqual(l1: list<number>, l2: list<number>): bool
  var min_length = min([len(l1), len(l2)])
  return l1[: min_length - 1] == l2[: min_length - 1]
enddef

export def IsBetweenMarks(A: string, B: string): bool
    var cursor_pos = getcharpos(".")
    var A_pos = getcharpos(A)
    var B_pos = getcharpos(B)

    if IsGreater(A_pos, B_pos)
      var tmp = B_pos
      B_pos = A_pos
      A_pos = tmp
    endif

    # Check 'A_pos <= cursor_pos <= B_pos'
    var result = (IsGreater(cursor_pos, A_pos) || IsEqual(cursor_pos, A_pos))
      && (IsGreater(B_pos, cursor_pos) || IsEqual(B_pos, cursor_pos))

    return result
enddef

export def IsInRange(): dict<list<list<number>>>
  # Return a dict like {'markdownCode': [[21, 19], [22, 21]]}.
  # The returned intervals are open.
  #
  # NOTE: Due to that bundled markdown syntax file returns 'markdownItalic' and
  # 'markdownBold' regardless is the delimiters are '_' or '*', we need the
  # StarOrUnrescore() function

  def StarOrUnderscore(text_style: string): string
    var text_style_refined = ''

    var tmp_star = $'constants.TEXT_STYLES_DICT.{text_style}.open_regex'
    const star_delim = eval(tmp_star)
    const pos_star = searchpos(star_delim, 'nbW')

    const tmp_underscore = $'constants.TEXT_STYLES_DICT.{text_style}U.open_regex'
    const underscore_delim = eval(tmp_underscore)
    const pos_underscore = searchpos(underscore_delim, 'nbW')

    if pos_star == [0, 0]
      text_style_refined = text_style .. "U"
    elseif pos_underscore == [0, 0]
      text_style_refined = text_style
    elseif IsGreater(pos_underscore, pos_star)
      text_style_refined = text_style .. "U"
    else
      text_style_refined = text_style
    endif
    return text_style_refined
  enddef

  # Main function start here
  # text_style comes from vim-markdown
  const text_style = synIDattr(synID(line("."), charcol("."), 1), "name")
  const text_style_adjusted =
    text_style == 'markdownItalic' || text_style == 'markdownBold'
     ? StarOrUnderscore(synIDattr(synID(line("."), charcol("."), 1), "name"))
     : synIDattr(synID(line("."), charcol("."), 1), "name")
  var return_val = {}

  if !empty(text_style_adjusted)
      && index(keys(constants.TEXT_STYLES_DICT), text_style_adjusted) != -1

    const saved_curpos = getcursorcharpos()

    # Search start delimiter
    const open_delim =
      eval($'constants.TEXT_STYLES_DICT.{text_style_adjusted}.open_delim')

    var open_delim_pos = searchpos($'\V{open_delim}', 'bW')
    var current_style = synIDattr(synID(line("."), charcol("."), 1), "name")
    # We search for a markdown delimiter or an htmlTag.
    while current_style != $'{text_style}Delimiter'
        && current_style != 'htmlTag'
      && open_delim_pos != [0, 0]
      open_delim_pos = searchpos($'\V{open_delim}', 'bW')
      current_style = synIDattr(synID(line("."), charcol("."), 1), "name")
    endwhile

    # To avoid infinite loops if some weird delimited text is highlighted
    if open_delim_pos == [0, 0]
      return {}
    endif
    open_delim_pos[1] += strchars(open_delim)

    # Search end delimiter.
    # The end delimiter may be a blank line, hence
    # things become a bit cumbersome.
    setcursorcharpos(saved_curpos[1 : 2])
    const close_delim =
     eval($'constants.TEXT_STYLES_DICT.{text_style_adjusted}.close_delim')
    var close_delim_pos = searchpos($'\V{close_delim}', 'nW')
    var blank_line_pos = searchpos($'^$', 'nW')
    var first_met = [0, 0]
    current_style = synIDattr(synID(line("."), charcol("."), 1), "name")

    while current_style != $'{text_style}Delimiter'
        && current_style != 'htmlEndTag'
        && getline(line('.')) !~ '^$'
      close_delim_pos = searchpos($'\V{close_delim}', 'nW')
      blank_line_pos = searchpos($'^$', 'nW')
      if close_delim_pos == [0, 0]
        first_met = blank_line_pos
      elseif blank_line_pos == [0, 0]
        first_met = close_delim_pos
      else
        first_met = IsLess(close_delim_pos, blank_line_pos)
        ? close_delim_pos
        : blank_line_pos
      endif
      setcursorcharpos(first_met)
      current_style = synIDattr(synID(line("."), charcol("."), 1), "name")
    endwhile

    # If we hit a blank line, then we take the previous line and last column,
    # to keep consistency in returning open-intervals
    if getline(line('.')) =~ '^$'
      first_met[0] = first_met[0] - 1
      first_met[1] = strchars(getline(first_met[0]))
    else
      first_met[1] -= 1
    endif

    setcursorcharpos(saved_curpos[1 : 2])
    return_val =  {[text_style_adjusted]: [open_delim_pos, first_met]}
  endif

  return return_val
enddef

export def SetBlock(type: string = '')
  # TODO: you may want to make this feature 'Smart' like 'SurroundSmart'. At
  # the moment is more like 'SurroundSimple'.
  #
  # If we are overlapping another thing, don't do anything
  const syn_info = synIDattr(synID(line("."), charcol("."), 1), "name")
  if !empty(IsInRange())
      || syn_info == 'markdownCodeDelimiter'
      || syn_info == 'markdownCodeBlock'
    return
  endif

  # Put the selected text between open_block and close_block.
  var label = ''
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'block_label')
    label = g:markdown_extras_config['block_label']
  else
    label = input('Enter code-block language: ')
  endif

  const open_block = constants.CODEBLOCK_OPEN_DICT
  const close_block = constants.CODEBLOCK_CLOSE_DICT

# We set cA=1 and cB = len(geline(B)) so we pretend that we are working
  # always line-wise
  var lA = line("'[")
  var cA = 1

  var lB = line("']")
  var cB = strchars(getline(lB))

  var firstline = getline(lA)
  var lastline = getline(lB)

  if firstline == lastline
    append(lA - 1, $'{keys(open_block)[0] .. label}')
    lA += 1
    lB += 1
    setline(lA, "  " .. getline(lA)->substitute('^\s*', '', ''))
    append(lA, $'{keys(open_block)[0] .. label}')
  else
    # Set first part
    setline(lA, strcharpart(getline(lA), 0, cA - 1))
    append(lA, [$'{keys(open_block)[0] .. label}',
      "  " .. strcharpart(firstline, cA - 1)])
    lA += 2
    lB += 2

    # Set intermediate part
    var ii = 1
    while lA + ii <= lB
      setline(lA + ii, "  " .. getline(lA + ii)->substitute('^\s*', '', ''))
      ii += 1
    endwhile

    # Set last part
    setline(lB, $'  {lastline}')
    append(lB, [$'{keys(close_block)[0]}', ''])
  endif
enddef

export def UnsetBlock(syn_info: string = '')
  const syn_str = empty(syn_info)
    ? synIDattr(synID(line("."), charcol("."), 1), "name")
    : syn_info
  if syn_str == 'markdownCodeBlock'
    const pos_start = searchpos(values(constants.CODEBLOCK_OPEN_DICT)[0], 'nbW')
    const pos_end = searchpos(values(constants.CODEBLOCK_CLOSE_DICT)[0], 'nW')

    const lA = pos_start[0]
    const lB = pos_end[0]
    deletebufline('%', lA - 1)
    deletebufline('%', lA - 1)
    deletebufline('%', lB - 2)
    deletebufline('%', lB - 2)

    for line in range(lA - 1, lB - 2)
      setline(line, getline(line)->substitute('^\s*', '', 'g'))
    endfor
  endif
enddef

export def SetQuoteBlock(type: string = '')

  # We set cA=1 and cB = strchars(geline(B)) so we pretend that we are working
  # always line-wise
  var lA = line("'[")
  var lB = line("']")

  for line_nr in range(lA, lB)
    setline(line_nr, $'> {getline(line_nr)}')
  endfor
enddef

export def UnsetQuoteBlock()
  const open_regex = values(constants.QUOTEBLOCK_OPEN_DICT)[0]
  # Line that starts with everything but '\s*>'-ish
  const close_regex = values(constants.QUOTEBLOCK_CLOSE_DICT)[0]

  const saved_curpos = getcurpos()
  var line_nr = saved_curpos[1]
  var line_content = getline(line_nr)

  if line_content !~ open_regex
    return
  endif

  # Moving up
  while line_content !~ close_regex && line_nr > 0
    setline(line_nr, line_content->substitute('>\s', '', ''))
    line_nr -= 1
    line_content = getline(line_nr)
  endwhile

  # Moving down
  setcharpos('.', saved_curpos)
  line_nr = line('.') + 1
  line_content = getline(line_nr)
  while line_content !~ close_regex && line_nr <= line('$')
    setline(line_nr, line_content->substitute('>\s', '', ''))
    line_nr += 1
    line_content = getline(line_nr)
  endwhile
  setcharpos('.', saved_curpos)
enddef

export def GetTextObject(textobject: string): dict<any>
  # You pass a text object like 'iw' and it returns the text
  # associated to it along with the start and end positions.
  #
  # Note that when you yank some text, the registers '[' and ']' are set, so
  # after call this function, you can retrieve start and end position of the
  # text-object by looking at such marks.
  #
  # The function also work with motions.

  # Backup the content of register t (arbitrary choice, YMMV) and marks
  var oldreg = getreg("t")
  var saved_A = getcharpos("'[")
  var saved_B = getcharpos("']")
  # silently yank the text covered by whatever text object
  # was given as argument into register t. Yank also set marks '[ and ']
  noautocmd execute 'silent normal "ty' .. textobject

  var text = getreg("t")
  var start_pos = getcharpos("'[")
  var end_pos = getcharpos("']")

  # restore register t and marks
  setreg("t", oldreg)
  setcharpos("'[", saved_A)
  setcharpos("']", saved_B)

  return {text: text, start: start_pos, end: end_pos}
enddef
