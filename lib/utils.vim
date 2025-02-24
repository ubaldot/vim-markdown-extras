vim9script

export def Echoerr(msg: string)
  echohl ErrorMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

export def Echowarn(msg: string)
  echohl WarningMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

export def DictToListOfDicts(d: dict<any>): list<dict<any>>
  # Convert a dict in a list of dict.
  #
  # Dor example, {a: 'foo', b: 'bar', c: 'baz'} becomes
  # [{a: 'foo'}, {b: 'bar'}, {c: 'baz'}]
  #
  var list_of_dicts = []
  for [k, v] in items(d)
    add(list_of_dicts, {[k]: v})
  endfor
  return list_of_dicts
enddef

export def ZipLists(l1: list<any>, l2: list<any>): list<list<any>>
    # Zip function, like in Python
    var min_len = min([len(l1), len(l2)])
    return map(range(min_len), $'[{l1}[v:val], {l2}[v:val]]')
enddef

export def RegexList2RegexOR(regex_list: list<string>,
    very_magic: bool = false): string
  # Convert a list of regex into an atom where each regex is separated by a OR
  # condition

  var result = ''
  if very_magic
    result =  regex_list->map((_, val) => substitute(val, '^\(\\v\)', '', ''))
          ->join('|')->printf('\v(%s)')
  else
    result = regex_list->join('\|')->printf('\(%s\)')
  endif
  return result
enddef

export def GetTextObject(textobject: string): string
  # You pass a text object like 'iw' and it returns the text
  # associated to it.
  #
  # Note that when you yank some text, the registers '[' and ']' are set, so
  # after call this function, you can retrieve start and end position of the
  # text-object by looking at such marks.

  # Backup the content of register t (arbitrary choice, YMMV)
  var oldreg = getreg("t")
  # silently yank the text covered by whatever text object
  # was given as argument into register t
  noautocmd execute 'silent normal "ty' .. textobject
  # save the content of register t into a variable
  var text = getreg("t")
  # restore register t
  setreg("t", oldreg)
  return text
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
    echoerr $"'{&l:formatprg->matchstr('^\s*\S*')}' returned errors."
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

export def RemoveSurrounding(
    open_delimiter_dict: dict<string>,
    close_delimiter_dict: dict<string>)
    # You may consider to add a loop to iterate among all the possible
    # delimiters pair
    var interval = IsInRange(open_delimiter_dict, close_delimiter_dict)
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
      # echom "cB: " .. cB
      # The value of cB may no longer be valid since we shortened the line
      if lA == lB
        cB = cB - len(keys(open_delimiter_dict)[0])
      endif

      newline =
        strcharpart(getline(lB), 0, cB)
        .. strcharpart(getline(lB), cB + len(keys(close_delimiter_dict)[0]))
      setline(lB, newline)
      # echom "lB: " .. newline
    endif
enddef

def SurroundSmart(open_delimiter: string,
    close_delimiter: string,
    open_delimiters_dict: dict<string>,
    close_delimiters_dict: dict<string>,
    text_object: string = '')

  var open_string = open_delimiter
  var open_regex = open_delimiters_dict[open_string]
  var open_delimiter_dict = {open_string: open_regex}

  var close_string = close_delimiter
  var close_regex = close_delimiters_dict[close_string]
  var close_delimiter_dict = {close_string: close_regex}
  # Set marks
  var A = getcharpos("'<")
  var B = getcharpos("'>")
  if !empty(text_object)
    # GetTextObject is called for setting '[ and '] marks through a yank.
    GetTextObject(text_object)
    A = getcharpos("'[")
    B = getcharpos("']")
  endif

  # marks -> (x,y) coordinates
  # line and column
  var lA = A[1]
  var cA = A[2]

  # line and column
  var lB = B[1]
  var cB = B[2]

  if A == B
    return
  endif

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

  # We need a list-of-dicts [{a: 'foo'}, {b: 'bar'}, {c: 'baz'}]
  var open_delimiters_dict_list = DictToListOfDicts(open_delimiters_dict)
  var close_delimiters_dict_list = DictToListOfDicts(close_delimiters_dict)

  # Check if A falls in an existing interval
  var found_delimiters_interval = []
  cursor(lA, cA)
  var old_right_delimiter = ''
  for delim in ZipLists(open_delimiters_dict_list,
      close_delimiters_dict_list)

    found_delimiters_interval = IsInRange(delim[0], delim[1])

    if !empty(found_delimiters_interval)
      old_right_delimiter = keys(delim[0])[0]
      # Existing blocks shall be disjoint,
      # so we can break as soon as we find a delimiter
      break
    endif
  endfor

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
  # for other languages, you have to modify it!
  var toA = ''
  if !empty(found_delimiters_interval) && old_right_delimiter != open_string
    toA = strcharpart(getline(lA), 0, cA - 1)->substitute('\s*$', '', '')
      .. $'{old_right_delimiter} {open_string}'
  elseif !empty(found_delimiters_interval) && old_right_delimiter == open_string
    # If the found interval is a text style equal to the one you want to set,
    # i.e. you would end up in adjacent delimiters like ** ** => Remove both
    toA = strcharpart(getline(lA), 0, cA - 1)
  else
    toA = strcharpart(getline(lA), 0, cA - 1) .. open_string
  endif

  # Check if B falls in an existing interval
  cursor(lB, cB)
  var old_left_delimiter = ''
  found_delimiters_interval = []
  for delim in ZipLists(close_delimiters_dict_list,
      close_delimiters_dict_list)

    found_delimiters_interval = IsInRange(delim[0], delim[0])

    if !empty(found_delimiters_interval)
      old_left_delimiter = keys(delim[0])[0]
      # Existing blocks shall be disjoint,
      # so we can break as soon as we find a delimiter
      break
    endif
  endfor

  var fromB = ''
  if !empty(found_delimiters_interval) && old_left_delimiter != close_string
    fromB = $'{close_string} {old_left_delimiter}'
      .. strcharpart(getline(lB), cB)->substitute('^\s*', '', '')
  elseif !empty(found_delimiters_interval) && old_left_delimiter == close_string
      fromB = strcharpart(getline(lB), cB)
  else
    fromB = close_string .. strcharpart(getline(lB), cB)
  endif

  # ------- SMART DELIMITERS PART END -----------
  # We have compute the partial strings until A and the partial string that
  # leaves B. Existing delimiters are set.
  # Next, we have to adjust the text between A and B, by removing all the
  # possible delimiters left between them.

  var all_delimiters_regex =
    RegexList2RegexOR(values(open_delimiters_dict), true)

  # If on the same line
  if lA == lB
    # Overwrite everything that is in the middle
    var A_to_B = ''

    A_to_B = strcharpart(getline(lA), cA - 1, cB - cA + 1)
      ->substitute(all_delimiters_regex, '', 'g')

    setline(lA, toA .. A_to_B .. fromB)

  else
    var lineA = toA .. strcharpart(getline(lA), cA - 1)
      ->substitute(all_delimiters_regex, '', 'g')
    echom "lineA: " .. lineA
    setline(lA, lineA)
    var lineB = strcharpart(getline(lB), 0, cB - 1)
      ->substitute(all_delimiters_regex, '', 'g') .. fromB
    echom "lineB: " .. lineB
    setline(lB, lineB)
    var l = 1
    # Fix intermediate lines
    while lA + l < lB
      setline(lA + l, getline(lA + l)->substitute(all_delimiters_regex, '', 'g') )
      l += 1
    endwhile
  endif

enddef

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


  if !empty(IsInRange(open_delimiter_dict, close_delimiter_dict))
    RemoveSurrounding(open_regex, close_regex)
  else
    Surround(open_delimiter,
    close_delimiter,
    open_delimiters_dict,
    close_delimiters_dict,
    text_object
    )
enddef

export def GetTextBetweenMarks(A: string, B: string): list<string>
    # Usage: GetTextBetweenPoints("`[", "`]").
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

    # B. ------ Close delimiter -------
    close_regex_pos_short = searchpos(close_regex, 'W')

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

export def IsInRange(
    open_delimiter_dict: dict<string>,
    close_delimiter_dict: dict<string>,
    ): list<list<number>>
  # Arguments must be singleton dicts.
  # Return the range of the delimiters if the cursor is within such a range,
  # otherwise return an empty list.
  var interval = []

  # OBS! Ranges are open-intervals!
  var ranges = GetDelimitersRanges(open_delimiter_dict, close_delimiter_dict)

  var saved_mark_a = getcharpos("'a")
  var saved_mark_b = getcharpos("'b")

  for range in ranges
    setcharpos("'a", range[0])
    setcharpos("'b", range[1])
    if IsBetweenMarks("'a", "'b")
      # echom "cur_pos: " .. string(getcharpos('.'))
      # echom "range[0]: " .. string(range[0])
      # echom "range[1]: " .. string(range[1])
      echom IsBetweenMarks("'a", "'b")
      interval = [range[0], range[1]]
      break
    endif
  endfor

  # Restore marks 'a and 'b
  setcharpos("'a", saved_mark_a)
  setcharpos("'b", saved_mark_b)

  return interval
enddef

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


# TODO
export var Surround = SurroundSmart
if exists('g:markdown_extras_config')
    && has_key(g:markdown_extras_config, 'smart_delimiters')
    && g:markdown_extras_config['smart_delimiters']
  Surround = SurroundSimple
endif
