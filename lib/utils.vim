vim9script

export def Echoerr(msg: string)
  echohl ErrorMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

export def Echowarn(msg: string)
  echohl WarningMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

export def ZipLists(l1: list<any>, l2: list<any>): list<list<any>>
    # Zip function, like in Python
    var min_len = min([len(l1), len(l2)])
    return map(range(min_len), $'[{l1}[v:val], {l2}[v:val]]')
enddef

export def GetTextObject(textobject: string): string
  # You pass a text object like "iw" and it returns the text
  # associated to it.
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
      Echowarn($'{&l:formatprg}')
    else
      Echowarn("'formatprg' is empty. Using default formatter.")
    endif
  endif
  winrestview(view)
enddef

def RemoveSurrounding(a: any, b: any)
  echom "TBD"
enddef

export def g:Surround(open_delimiter: string,
    close_delimiter: string,
    open_delimiters_dict: dict<string>,
    close_delimiters_dict: dict<string>,
    text_object: string = '')
  # Usage:
  #   Select text and hit <leader> + e.g. parenthesis
  #
  # open_delimiter and close_delimiter are the strings to add to the text.
  # They also serves as keys for the dics open_delimiters_dict and
  # close_delimiters_dict.
  #
  # We need dicts because we need both the strings to add to the text for
  # surrounding purposes, but also a mechanism to search the surrounding
  # delimiters in the text.
  # We need regex because the delimiters strings may not be disjoint (think
  # for example, in the markdown case, you have '*' delimiter which is
  # contained in the '**' delimiter) and therefore we cannot find the
  # delimiting string as-is.
  # Finally, open_delimiters_dict[ii] is associated to
  # close_delimiters_dict[ii].
  #
  # Remember that Visual Selections and Text Objects are cousins.
  # Also, remember that a yank set the marks '[ and '].

  var open_string = open_delimiter
  var open_regex = close_delimiters_dict[open_string]
  var close_string = close_delimiter
  var close_regex = close_delimiters_dict[close_string]

  if !empty(IsInRange(open_regex, close_regex))
    RemoveSurrounding(open_regex, close_regex)
  else
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

    # -------- The search begins -------------
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

    # Check if the cursor is already in a range of another pair of delimiters
    var open_delim_leftovers = keys(open_delimiters_dict)
      ->filter($"v:val != '{open_string}'")
    var close_delim_leftovers = keys(close_delimiters_dict)
      ->filter($"v:val != '{close_string}'")

    var found_delimiters_interval = []
    # Check if A falls in an existing interval
    # TODO You can remove the target regex here in all_open_delim_regex
    cursor(lA, cA)
    var old_right_delimiter = ''
    for delim in ZipLists(open_delim_leftovers, close_delim_leftovers)
      found_delimiters_interval =
        IsInRange(open_delimiters_dict[delim[0]],
        close_delimiters_dict[delim[1]])

      if !empty(found_delimiters_interval)
        old_right_delimiter = delim[0]
        # Existing blocks shall be disjoint,
        # so we can break as soon as we find a delimiter
        break
      endif
    endfor

    var toA = ''
    if !empty(found_delimiters_interval)
      toA = strcharpart(getline(lA), 0, cA - 1) .. old_right_delimiter .. open_string
    else
      toA = strcharpart(getline(lA), 0, cA - 1) .. open_string
    endif

    # # # Check if also B falls in an existing interval
    cursor(lB, cB)
    var old_left_delimiter = ''
    found_delimiters_interval = []
    for delim in ZipLists(close_delim_leftovers, close_delim_leftovers)
      found_delimiters_interval =
        IsInRange(close_delimiters_dict[delim[0]],
        close_delimiters_dict[delim[1]])

      if !empty(found_delimiters_interval)
        old_left_delimiter = delim[0]
        # Existing blocks shall be disjoint,
        # so we can break as soon as we find a delimiter
        break
      endif
    endfor

    var fromB = ''
    if !empty(found_delimiters_interval)
      fromB = close_string .. old_left_delimiter
        .. strcharpart(getline(lB), cB)
    else
      fromB = close_string .. strcharpart(getline(lB), cB)
    endif

    # # We have compute the partial strings until A and the partial string that
    # # leaves B. Existing delimiters are set.
    # # Next, we have to adjust the text between A and B, by removing all the
    # # possible delimiters.

    if lA == lB
      echom "TBD"
      # Overwrite everything that is in the middle
      var middle = strcharpart(getline(lA), cA - 1, cB - cA)
        -> substitute($'\({all_open_delim_regex[0]}\|{all_open_delim_regex[1]}
              \|{all_open_delim_regex[2]}\|{all_open_delim_regex[3]}\)', '', 'g')
      setline(lA, toA .. middle .. fromB)
    elseif lB - lA == 1
      echom "TBD"
    else
      echom "TBD"
    endif

    echom 'toA: ' .. toA
    echom 'fromB: ' .. fromB
  endif
enddef

export def GetTextBetweenMarks(A: string, B: string): list<string>
    # Usage: GetTextBetweenPoints("`[", "`]").
    #
    # Arguments must be markers
    # called with the back ticks to get the exact position ('a jump to the
    # marker but places the cursor at the beginning of the line.)
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

export def GetDelimitersRanges(open_delimiter: string,
    close_delimiter: string,
    open_delimiter_length_max: number = 2,
    close_delimiter_length_max: number = 2
    ): list<list<list<number>>>
  # It returns open-intervals, i.e. the delimiters are excluded
  # Passed delimiters are regex.
  #
  # TODO: It is assumed that the ranges have no intersections. Note that this
  # won't happen if open_delimiter = close_delimiter, as in many languages.
  var saved_cursor = getcursorcharpos()
  cursor(1, 1)

  var ranges = []

  # 2D format due to that searchpos() returns a 2D vector
  var open_delimiter_pos_short = [-1, -1]
  var close_delimiter_pos_short = [-1, -1]
  var open_delimiter_pos_short_final = [-1, -1]
  var close_delimiter_pos_short_final = [-1, -1]
  #
  # 4D format due to that marks have 4-coordinates
  var open_delimiter_pos = [0] + open_delimiter_pos_short + [0]
  var open_delimiter_match = ''
  var open_delimiter_length = 0
  var close_delimiter_pos = [0] + close_delimiter_pos_short + [0]
  var close_delimiter_length = 0
  var close_delimiter_match = ''

  while open_delimiter_pos_short != [0, 0]

    # A. ------------ open_delimiter -----------------
    open_delimiter_pos_short = searchpos(open_delimiter, 'W')

    # If you pass a regex, you don't know how long is the captured
    # string. The captured string length is used as offset.
    open_delimiter_match = strcharpart(
      getline(open_delimiter_pos_short[0]),
      open_delimiter_pos_short[1] - 1, open_delimiter_length_max)
      ->matchstr(open_delimiter)
    open_delimiter_length = len(open_delimiter_match)

    # If the open delimiter is the tail of the line, then the open-interval starts from
    # the next line, column 1
    if open_delimiter_pos_short[1] + open_delimiter_length == col('$')
      open_delimiter_pos_short_final[0] = open_delimiter_pos_short[0] + 1
      open_delimiter_pos_short_final[1] = 1
    else
      # Pick the open-interval
      open_delimiter_pos_short_final[0] = open_delimiter_pos_short[0]
      open_delimiter_pos_short_final[1] = open_delimiter_pos_short[1]
                                             + open_delimiter_length
    endif
    open_delimiter_pos = [0] + open_delimiter_pos_short_final + [0]

    # B. ------ Close delimiter -------
    close_delimiter_pos_short = searchpos(close_delimiter, 'W')
    # If you pass a regex, you don't know how long is the captured string
    close_delimiter_match = strcharpart(
      getline(close_delimiter_pos_short[0]),
      close_delimiter_pos_short[1] - 1, close_delimiter_length_max)
      ->matchstr(close_delimiter)
    close_delimiter_length = len(close_delimiter_match)

    # If the closed delimiter is the lead of the line, then the open-interval
    # starts from the previous line, last column
    if close_delimiter_pos_short[1] - 1 == 0
      close_delimiter_pos_short_final[0] = close_delimiter_pos_short[0] - 1
      close_delimiter_pos_short_final[1] = len(getline(close_delimiter_pos_short_final[0]))
    else
      close_delimiter_pos_short_final[0] = close_delimiter_pos_short[0]
      close_delimiter_pos_short_final[1] = close_delimiter_pos_short[1] - 1
    endif
    close_delimiter_pos = [0] + close_delimiter_pos_short_final + [0]

    add(ranges, [open_delimiter_pos, close_delimiter_pos])
  endwhile
  setcursorcharpos(saved_cursor[1 : 2])

  # Remove the last element junky [[0,0,len(open_delimiter),0], [0,0,-1,0]]
  remove(ranges, -1)

  return ranges
enddef

export def IsBetweenMarks(A: string, B: string): bool
    var cursor_pos = getpos(".")
    var A_pos = getcharpos(A)
    var B_pos = getcharpos(B)

    # Convert in floats of the form "line.column" so the check reduces to a
    # comparison of floats.
    var lower_float = str2float($'{A_pos[1]}.{A_pos[2]}')
    var upper_float = str2float($'{B_pos[1]}.{B_pos[2]}')
    var cursor_pos_float =
      str2float($'{getcharpos(".")[1]}.{getcharpos(".")[2]}')

    # In case the lower limit is larger than the higher limit, swap
    if upper_float < lower_float
      var tmp = upper_float
      upper_float = lower_float
      lower_float = tmp
    endif

    return lower_float <= cursor_pos_float && cursor_pos_float <= upper_float
enddef

export def IsInRange(open_delimiter: string,
    close_delimiter: string): list<list<number>>
  # Arguments must be regex.
  # Return the range of the delimiters if the cursor is within such a range,
  # otherwise return an empty list.
  var interval = []

  # OBS! Ranges are open-intervals!
  var ranges = GetDelimitersRanges(open_delimiter, close_delimiter)

  var saved_mark_a = getcharpos("'a")
  var saved_mark_b = getcharpos("'b")

  for range in ranges
    setcharpos("'a", range[0])
    setcharpos("'b", range[1])
    if IsBetweenMarks("'a", "'b")
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
  # instead of 'a to jump to the exact marker position
  var exact_A = substitute(A, "'", "`", "")
  var exact_B = substitute(B, "'", "`", "")
  execute $'norm! {exact_A}v{exact_B}"_d'
  # This to get rid off E1186
  return ''
enddef
