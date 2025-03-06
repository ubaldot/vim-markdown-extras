vim9script

import autoload "./constants.vim"


export def Echoerr(msg: string)
  echohl ErrorMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

export def Echowarn(msg: string)
  echohl WarningMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

# TODO it may be limiting to have 'string' only
export def KeysFromValue(dict: dict<string>, target_value: string): list<string>
    # Given a value, return all the keys associated to it
    return keys(filter(copy(dict), $'v:val == "{target_value}"'))
enddef

export def DictToListOfDicts(d: dict<any>): list<dict<any>>
  # Convert a dict in a list of dict.
  #
  # For example, {a: 'foo', b: 'bar', c: 'baz'} becomes
  # [{a: 'foo'}, {b: 'bar'}, {c: 'baz'}]
  #
  var list_of_dicts = []
  for [k, v] in items(d)
    add(list_of_dicts, {[k]: v})
  endfor
  return list_of_dicts
enddef

export def ZipLists(l1: list<any>, l2: list<any>): list<list<any>>
    # Zip-like function, like in Python
    var min_len = min([len(l1), len(l2)])
    return map(range(min_len), $'[{l1}[v:val], {l2}[v:val]]')
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

export def FormatWithoutMoving(a: number = 0, b: number = 0)
  # To be used for formatting through autocmds
  var view = winsaveview()
  if a == 0 && b == 0
    silent exe $":norm! gggqG"
  else
    var interval = b - a + 1
    silent exe $":norm! {a}gg{interval}gqq"
  endif

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
  winrestview(view)
enddef

export def RemoveSurrounding()
    var interval = IsInRange()
    if !empty(interval)
      # Remove left delimiter
      var lA = interval[0][1]
      var cA = interval[0][2]
      var newline =
        strcharpart(getline(lA), 0, cA - 1 - len(keys(open_delimiter_dict)[0]))
        .. strcharpart(getline(lA), cA - 1)
      setline(lA, newline)

      # Remove right delimiter
      var lB = interval[1][1]
      var cB = interval[1][2]
      # The value of cB may no longer be valid since we shortened the line
      if lA == lB
        cB = cB - len(keys(open_delimiter_dict)[0])
      endif

      newline =
        strcharpart(getline(lB), 0, cB)
        .. strcharpart(getline(lB), cB + len(keys(close_delimiter_dict)[0]))
      setline(lB, newline)
    endif
enddef

export def SurroundSimple(open_delimiter: string,
    close_delimiter: string,
    open_delimiters_dict: dict<string>,
    close_delimiters_dict: dict<string>,
    type: string = '')

  if getcharpos("'[") == getcharpos("']")
    return
  endif

  var open_string = open_delimiter
  var open_regex = open_delimiters_dict[open_string]
  var open_delimiter_dict = {open_string: open_regex}

  var close_string = close_delimiter
  var close_regex = close_delimiters_dict[close_string]
  var close_delimiter_dict = {close_string: close_regex}

  # line and column of point A
  var lA = line("'[")
  var cA = col("'[")

  # line and column of point B
  var lB = line("']")
  var cB = col("']")

  var toA = strcharpart(getline(lA), 0, cA - 1) .. open_string
  var fromB = close_string .. strcharpart(getline(lB), cB)

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

  var delimiters_to_remove = []
  for k in keys(constants.TEXT_STYLES_DICT)
      add(delimiters_to_remove, constants.TEXT_STYLES_DICT[k].open_regex)
      add(delimiters_to_remove, constants.TEXT_STYLES_DICT[k].close_regex)
  endfor

  # line and column of point A
  var lA = line("'[")
  var cA = col("'[")

  # line and column of point B
  var lB = line("']")
  var cB = col("']")

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
    toA = strcharpart(getline(lA), 0, cA - 1) .. open_delim
  endif
  echom $'toA: ' .. toA

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
  echom $'fromB: ' .. fromB
  echom ''

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
    if style != 'markdownCode'
      for regex in delimiters_to_remove
        A_to_B = A_to_B->substitute(regex, '', 'g')
      endfor
    endif
    echom $'A_to_B:' .. A_to_B
    # echom '----------\n'

    # Set the whole line
    setline(lA, toA .. A_to_B .. fromB)

  else
    # Set line A
    var afterA = strcharpart(getline(lA), cA - 1)
    if style != 'markdownCode'
      for regex in delimiters_to_remove
        afterA = afterA->substitute(regex, '', 'g')
      endfor
    endif
    var lineA = toA .. afterA
    setline(lA, lineA)

    # Set line B
    var beforeB = strcharpart(getline(lB), 0, cB)
    if style != 'markdownCode'
      for regex in delimiters_to_remove
        beforeB = beforeB->substitute(regex, '', 'g')
      endfor
    endif
    var lineB = beforeB .. fromB
    setline(lB, lineB)

    # Fix intermediate lines
    var ii = 1
    while lA + ii < lB
      var middleline = getline(lA + ii)
      if style != 'markdownCode'
        for regex in delimiters_to_remove
          middleline = middleline-> substitute(regex, '', 'g')
        endfor
      endif
      setline(lA + ii, middleline)
      ii += 1
    endwhile
  endif
enddef

# TODO: Not used in markdown
export def SurroundToggle(open_delimiter: string,
    close_delimiter: string,
    open_delimiters_dict: dict<string>,
    close_delimiters_dict: dict<string>,
    text_object: string = '')
  # Usage:
  #   Select text and hit <leader> + e.g. parenthesis
  #
  # 'open_delimiter' and 'close_delimiter' are the strings to add to the text.
  # They also serves as keys for the dics 'open_delimiters_dict' and
  # 'close_delimiters_dict'.
  #
  # We need dicts because we need the strings to add to the text for
  # surrounding purposes, but also a mechanism to search the surrounding
  # delimiters in the text.
  # We need regex because the delimiters strings may not be disjoint (think
  # for example, in the markdown case, you have '*' delimiter which is
  # contained in the '**' delimiter) and therefore we cannot find the
  # delimiting string as-is.
  # Finally, open_delimiters_dict[ii] is zipped with
  # close_delimiters_dict[ii], therefore be sure that there is correspondence
  # between opening and closing delimiters.
  #
  # Remember that Visual Selections and Text Objects are cousins.
  # Also, remember that a yank set the marks '[ and '].


  if !empty(IsInRange())
    RemoveSurrounding()
  else
    Surround(open_delimiter,
    close_delimiter,
    open_delimiters_dict,
    close_delimiters_dict,
    text_object
    )
enddef

export def GetTextBetweenMarks(A: string, B: string): list<string>
    # Usage: GetTextBetweenMarks("'A", "'B").
    #
    # Arguments must be marks called with the back ticks to get the exact
    # position ('a jump to the marker but places the cursor
    # at the beginning of the line.)
    #
    var [_, l1, c1, _] = getcharpos(A)
    var [_, l2, c2, _] = getcharpos(B)

    if l1 == l2
        # Extract text within a single line
        return [getline(l1)[c1 - 1 : c2 - 1]]
    else
        # Extract text across multiple lines
        var lines = getline(l1, l2)
        lines[0] = lines[0][c1 - 1 : ]  # Trim the first line from c1
        lines[-1] = lines[-1][ : c2 - 1]  # Trim the last line up to c2
        return lines
    endif
enddef

export def GetDelimitersRanges(
    open_delimiter_dict: dict<string>,
    close_delimiter_dict: dict<string>,
    ): list<list<list<number>>>
  # It returns open-intervals, i.e. the delimiters are excluded.
  #
  # Passed delimiters are singleton dicts with key = the delimiter string,
  # value = the regex to exactly capture such a delimiter string
  #
  # It is assumed that the ranges have no intersections. This happens if
  # open_delimiter = close_delimiter, as in many languages.
  #
  # By contradiction, say that open_delimiter = * and close_delimiter = /. You may
  # have something like:
  # ----*---*===/---/-----
  # The part in === is an intersection between two ranges.
  # In these cases, this function will not work.
  # However, languages where open_delimiter = close_delimiter such intersections
  # cannot happen and this function apply.
  #
  var saved_cursor = getcursorcharpos()
  cursor(1, 1)

  var ranges = []

  var open_regex = values(open_delimiter_dict)[0]
  var open_string = keys(open_delimiter_dict)[0]
  var close_regex = values(close_delimiter_dict)[0]
  var close_string = keys(close_delimiter_dict)[0]

  # 2D format due to that searchpos() returns a 2D vector
  var open_regex_pos_short = [-1, -1]
  var close_regex_pos_short = [-1, -1]
  var open_regex_pos_short_final = [-1, -1]
  var close_regex_pos_short_final = [-1, -1]

  # 4D format due to that marks have 4-coordinates
  var open_regex_pos = [0] + open_regex_pos_short + [0]
  var open_regex_match = ''
  var close_regex_pos = [0] + close_regex_pos_short + [0]
  var close_regex_length = 0
  var close_regex_match = ''

  while open_regex_pos_short != [0, 0]

    # A. ------------ open_regex -----------------
    open_regex_pos_short = searchpos(open_regex, 'W')

    # If the open delimiter is the tail of the line,
    # then the open-interval starts from the next line, column 1
    if open_regex_pos_short[1] + len(open_string) == col('$')
      open_regex_pos_short_final[0] = open_regex_pos_short[0] + 1
      open_regex_pos_short_final[1] = 1
    else
      # Pick the open-interval
      open_regex_pos_short_final[0] = open_regex_pos_short[0]
      open_regex_pos_short_final[1] = open_regex_pos_short[1]
                                             + len(open_string)
    endif
    open_regex_pos = [0] + open_regex_pos_short_final + [0]

    # B. ------ Close regex -------
    close_regex_pos_short = searchpos(close_regex, 'W')
    # TODO: if close_regex_pos_short = [0, 0] => anomaly! One tag has been
    # opened and never closed!

    # If the closed delimiter is the lead of the line, then the open-interval
    # starts from the previous line, last column
    if close_regex_pos_short[1] - 1 == 0
      close_regex_pos_short_final[0] = close_regex_pos_short[0] - 1
      close_regex_pos_short_final[1] = len(getline(close_regex_pos_short_final[0]))
    else
      close_regex_pos_short_final[0] = close_regex_pos_short[0]
      close_regex_pos_short_final[1] = close_regex_pos_short[1] - 1
    endif
    close_regex_pos = [0] + close_regex_pos_short_final + [0]

    add(ranges, [open_regex_pos, close_regex_pos])
  endwhile
  setcursorcharpos(saved_cursor[1 : 2])

  # Remove the last element junky [[0,0,len(open_delimiter),0], [0,0,-1,0]]
  # TODO it does not seems to remove anything...
  remove(ranges, -1)

  return ranges
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
    var cursor_pos = getpos(".")
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
  const text_style =
    synIDattr(synID(line("."), col("."), 1), "name") == 'markdownItalic'
    || synIDattr(synID(line("."), col("."), 1), "name") == 'markdownBold'
     ? StarOrUnderscore(synIDattr(synID(line("."), col("."), 1), "name"))
     : synIDattr(synID(line("."), col("."), 1), "name")
  var return_val = {}

  if !empty(text_style)
      && index(keys(constants.TEXT_STYLES_DICT), text_style) != -1

    # Search start delimiter
    const open_delim =
      eval($'constants.TEXT_STYLES_DICT.{text_style}.open_delim')
    const open_regex =
      eval($'constants.TEXT_STYLES_DICT.{text_style}.open_regex')
    var start_delim = searchpos(open_regex, 'nbW')
    start_delim[1] += len(open_delim)

    # Search end delimiter
    const close_delim =
     eval($'constants.TEXT_STYLES_DICT.{text_style}.close_delim')
    const close_regex =
      eval($'constants.TEXT_STYLES_DICT.{text_style}.close_regex')
    var end_delim = searchpos(close_regex, 'ncW')

    # TODO: Very ugly hack due to the LINK_CLOSE_REGEX ending up on ]
    if synIDattr(synID(end_delim[0], end_delim[1], 1), "name")
        == 'markdownLinkTextDelimiter'
      end_delim[1] -= 1
    endif

    return_val =  {[text_style]: [start_delim, end_delim]}
  endif

  return return_val
enddef

# Not used in markdown
export def DeleteTextBetweenMarks(A: string, B: string): string
  # To jump to the exact position (and not at the beginning of a line) you
  # have to call the marker with the backtick ` rather than with ', e.g. `a
  # instead of 'a
  # TODO
  # This implementation most likely modify the jumplist.
  # Find a solution based on functions instead
  var exact_A = substitute(A, "'", "`", "")
  var exact_B = substitute(B, "'", "`", "")
  execute $'norm! {exact_A}v{exact_B}"_d'
  # This to get rid off E1186
  return ''
enddef

export def SetBlock(open_block: dict<string>,
    close_block: dict<string>,
    type: string = '')
  # Put the selected text between open_block and close_block.
  var label = ''
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'block_label')
    label = g:markdown_extras_config['block_label']
  else
    label = input('Enter code-block language: ')
  endif

  # TODO return or remove surrounding?
  if !empty(IsInRange())
      || getline('.') == $'{keys(open_block)[0] .. label}'
      || getline('.') == $'{keys(close_block)[0]}'
    return
  endif


  # We set cA=1 and cB = len(geline(B)) so we pretend that we are working
  # always line-wise
  var lA = line("'[")
  var cA = 1

  var lB = line("']")
  var cB = len(getline(lB))

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
    setline(lB, "  " .. strcharpart(lastline, 0, cB))
    append(lB, [$'{keys(close_block)[0]}', strcharpart(lastline, cB)])
  endif
enddef

export def UnsetBlock(open_block: dict<string>, close_block: dict<string>)
  # TODO Replace with IsInRange() once vim-surround is fixed
  if synIDattr(synID(line("."), col("."), 1), "name") == 'markdownCodeBlock'
    const pos_start = searchpos(constants.CODEBLOCK_OPEN_REGEX, 'nbW')
    const pos_end = searchpos(constants.CODEBLOCK_CLOSE_REGEX, 'nbW')

    const lA = pos_start[0]
    const lB = pos_end[0]
    deletebufline('%', lA - 1)
    deletebufline('%', lB)

    for line in range(lA - 1, lB - 1)
      setline(line, getline(line)->substitute('^\s*', '', 'g'))
    endfor
  endif
enddef
