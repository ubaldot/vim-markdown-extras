vim9script

import autoload "./constants.vim"


export def Echoerr(msg: string)
  echohl ErrorMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

export def Echowarn(msg: string)
  echohl WarningMsg | echom $'[markdown_extras] {msg}' | echohl None
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
    const style_interval = IsInRange()
    if !empty(style_interval)
      const style = keys(style_interval)[0]
      const interval = values(style_interval)[0]

      # Remove left delimiter
      const lA = interval[0][0]
      const cA = interval[0][1]
      var newline = strcharpart(getline(lA), 0,
              \ cA - 1 - len(constants.TEXT_STYLES_DICT[style].open_delim))
              \ .. strcharpart(getline(lA), cA - 1)
      setline(lA, newline)

      # Remove right delimiter
      const lB = interval[1][0]
      var cB = interval[1][1]
      # The value of cB may no longer be valid since we shortened the line
      if lA == lB
        cB = cB - len(constants.TEXT_STYLES_DICT[style].open_delim)
      endif

      newline = strcharpart(getline(lB), 0, cB)
            \ .. strcharpart(getline(lB),
              \ cB + len(constants.TEXT_STYLES_DICT[style].open_delim))
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
  var cA = col("'[")

  # line and column of point B
  var lB = line("']")
  var cB = col("']")

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

  # This is needed to remove all existing other text-styles between A and B
  var delimiters_to_remove = []
  # We don't want to remove links between A and B
  var regex_for_removal = keys(constants.TEXT_STYLES_DICT)
    ->filter("v:val !~ '\\v(markdownLinkText)'")
  # TODO here we should use open_regex and close_regex but then the substitute()
  # will replace also the \S :-(
  for k in regex_for_removal
      add(delimiters_to_remove, constants.TEXT_STYLES_DICT[k].open_delim)
      add(delimiters_to_remove, constants.TEXT_STYLES_DICT[k].close_delim)
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
    if style != 'markdownCode'
      A_to_B = A_to_B->substitute($'\V{join(delimiters_to_remove, '\|')}', '', 'g')
    endif
    # echom "A_to_B: " .. A_to_B

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
      afterA = afterA
        ->substitute($'\V{join(delimiters_to_remove, '\|')}', '', 'g')
    endif
    var lineA = toA .. afterA
    setline(lA, lineA)

    # Set line B
    var beforeB = strcharpart(getline(lB), 0, cB)
    if style != 'markdownCode'
      beforeB = beforeB
        ->substitute($'\V{join(delimiters_to_remove, '\|')}', '', 'g')
    endif
    var lineB = beforeB .. fromB
    setline(lB, lineB)

    # Fix intermediate lines
    var ii = 1
    while lA + ii < lB
      var middleline = getline(lA + ii)
      if style != 'markdownCode'
        middleline = middleline
          ->substitute($'\V{join(delimiters_to_remove, '\|')}', '', 'g')
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
