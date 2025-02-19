vim9script

export def Echoerr(msg: string)
  echohl ErrorMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

export def Echowarn(msg: string)
  echohl WarningMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

export def ZipLists(l1: list<any>, l2: list<any>): list<list<any>>
    # Zip like function, like in Python
    var min_len = min([len(l1), len(l2)])
    return map(range(min_len), $'[{l1}[v:val], {l2}[v:val]]')
enddef

export def GetTextObject(textobject: string): dict<any>
  # You pass a text object like "inside word", etc. and it returns it, along
  # with the start and end positions. In-fact, when you yank some text, then
  # the registers '[' and ']' are set.
  #
  # Start and end positions are of the form
  # [buffer_number, line_number, column_number, screen_column].
  #
  # For example GetTextObjet('aw') it returns "around word".

  # backup the content of register t (arbitrary choice, YMMV)
  var oldreg = getreg("t")
  # silently yank the text covered by whatever text object
  # was given as argument into register t
  noautocmd execute 'silent normal "ty' .. textobject
  # save the content of register t into a variable
  var text = getreg("t")
  # restore register t
  setreg("t", oldreg)
  # return the content of given text object
  var text_object = {text: text, start_pos: "'[", end_pos: "']"}
  return text_object
enddef

export def Surround(pre: string, post: string, text_object: string = '')
  # Usage:
  #   Select text and hit <leader> + e.g. parenthesis
  #
  # Note that Visual Selections and Text Objects are cousins
  #
  var [line_start, column_start] = [-1, -1]
  var [line_end, column_end]  = [-1, -1]
  if !empty(text_object)
    [line_start, column_start] = GetTextObject(text_object).start_pos[1 : 2]
    [line_end, column_end] = GetTextObject(text_object).end_pos[1 : 2]
  else
    # If no text_object is passed, then the selection is visual
    [line_start, column_start] = getpos("'<")[1 : 2]
    [line_end, column_end] = getpos("'>")[1 : 2]
  endif

  var pre_len = strlen(pre)
  var post_len = strlen(post)
  if line_start > line_end
    var tmp = line_start
    line_start = line_end
    line_end = tmp

    tmp = column_start
    column_start = column_end
    column_end = tmp
  endif
  if line_start == line_end && column_start > column_end
    var tmp = column_start
    column_start = column_end
    column_end = tmp
  endif
  var leading_chars = strcharpart(getline(line_start), column_start - 1 -
    pre_len, pre_len)
  var trailing_chars = strcharpart(getline(line_end), column_end, post_len)

  cursor(line_start, column_start)
  var offset = 0
  if leading_chars == pre
    exe $"normal! {pre_len}X"
    offset = -pre_len
  else
    exe $"normal! i{pre}"
    offset = pre_len
  endif

  # Some chars have been added if you are working on the same line
  if line_start == line_end
    cursor(line_end, column_end + offset)
  else
    cursor(line_end, column_end)
  endif

  if trailing_chars == post
    exe $"normal! l{post_len}x"
  else
    exe $"normal! a{post}"
  endif
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


export def RemoveSurrounding(A: string, B: string, lead: number, trail: number)
  # Remove 'lead' chars from before mark 'A and 'trail' chars after mark 'B
  if line(A) == line(B)
    var part1 = strcharpart(getline(A), 0, col(A) - lead - 1)
    var part2 = strcharpart(getline(A), col(A) - 1, col(B) - col(A) + 1)
    var part3 = strcharpart(getline(A), col(B) + trail)

    echom part1
    echom part2
    echom part3

    var new_line = part1 .. part2 .. part3
      setline(line(A), new_line)
  else
      var first_line = strcharpart(getline(A), 0, col(A) - lead - 1)
        .. strcharpart(getline(A), col(A) - 1)
      echom first_line
      setline(line(A), first_line)

      var last_line = strcharpart(getline(B), 0, col(B) - trail - 1)
        .. strcharpart(getline(B), col(B) - 1)
      echom last_line
      setline(line(B), last_line)
  endif
enddef

export def SurroundNew(open_delimiter: string, close_delimiter: string, text_object: string = '', keep_even: bool = false)
  # Usage:
  #   Select text and hit <leader> + e.g. parenthesis
  #
  # Note that Visual Selections and Text Objects are cousins
  #
  if !empty(IsInRange(open_delimiter, close_delimiter))
    RemoveSurrounding(open_delimiter, close_delimiter)
  else
    # Set marks
    var A_mark = "'<"
    var B_mark = "'>"
    if !empty(text_object)
      # A and B are "'[" and "']". Basically, GetTextObject is called for
      # setting such markers through a yank
      A_mark = GetTextObject(text_object).start_pos
      B_mark = GetTextObject(text_object).end_pos
    endif

    # marks -> (x,y) coordinates
    var A = getcharpos(A_mark)
    var xA = A[1]
    var yA = A[2]
    var B = getcharpos(B_mark)
    var xB = B[1]
    var yB = B[2]

    if A == B
      return
    endif

    # -------- The search begins -------------
    # We check conditions like the following and we adjust the style delimiters
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
    var open_delimiters = ['*', '**', '~~', '`']
    var close_delimiters = ['*', '**', '~~', '`']
    var old_right_delimiter = ''
    var old_left_delimiter = ''

    var found_delimiters_interval = []
    # We assume that open and close delimiters are the same, given that we started
    # developing for markdown
    # Check if A falls in an existing interval
    cursor(xA, yA)
    for delimiterg in ZipLists(open_delimiters, close_delimiters)
      found_delimiters_interval = IsInRange(delimiterg[0], delimiterg[1])
      if !empty(found_delimiters_interval)
        old_right_delimiter = delimiterg[0]
        # Existing blocks shall be disjoint,
        # so we can break as soon as we find a delimiter
        break
      endif
    endfor

    var toA = ''
    if !empty(found_delimiters_interval)
      toA = old_right_delimiter .. open_delimiter .. strcharpart(getline(xA), 0, yA)
    else
      toA = open_delimiter .. strcharpart(getline(xA), 0, yA)
    endif

    # Check if also B falls in an existing interval
    cursor(xB, yB)
    for delimiterg in ZipLists(open_delimiters, close_delimiters)
      found_delimiters_interval = IsInRange(delimiterg[0], delimiterg[1])
      if !empty(found_delimiters_interval)
        old_left_delimiter = delimiterg[0]
        break
      endif
    endfor

    var fromB = ''
    if !empty(found_delimiters_interval)
      FromB = close_delimiter .. old_left_delimiter .. strcharpart(getline(xB), yB - 1)
    else
      FromB = close_delimiter .. strcharpart(getline(xB), yB - 1)
    endif

    if xA == xB
      # Overwrite everything that is in the middle
      var middle = strcharpart(getline(xA), yA - 1, yB - yA)
        -> substitute($'\({open_delimiter[0]}\|{open_delimiter[1]}
              \|{open_delimiter[2]}\|{open_delimiter[3]}\)', '', 'g')
      setline(xA, toA .. middle .. fromB)
    elseif xB - xA = 1
      echom "TBD"
    else
      echom "TBD"
    endif
    # The extremes shall set. Next, we have to arrange what happens in the
    # middle.
    # TODO
    # Add surrounding
    # Capture text as-is
    var captured_text = GetTextBetweenMarks(A, B)
    #
    # Delete old text.
    # OBS! Markers will be also deleted!
    # DeleteTextBetweenMarks(A, B)

    # TEST
    # echom "l: " .. lead
    # echom "t: " ..  trail

    # TODO: This has to be done afterwardsRemove all existing delimiters between A and B
    # If there is a delimiter surrounded by white spaces, keep it as it is not a
    # valid text-style in markdown
    var cleaned_text = captured_text
      ->map((_, val) => substitute(val, '\S\*\+', '', 'g'))
      ->map((_, val) => substitute(val, '\*\+\S', '', 'g'))
      ->map((_, val) => substitute(val, '\S\~\~', '', 'g'))
      ->map((_, val) => substitute(val, '\~\~\S', '', 'g'))
      ->map((_, val) => substitute(val, '\S`', '', 'g'))
      ->map((_, val) => substitute(val, '`\S', '', 'g'))

    # Surround text
    # echom captured_text
    # echom cleaned_text
    var surrounded_text = copy(cleaned_text)
    surrounded_text[0] = delimiterg .. cleaned_text[0]
    surrounded_text[-1] = surrounded_text[-1] .. delimiterg

    # echom surrounded_text
    # Add new text
    var first_line = strcharpart(getline(A), 0, col(A) - 1)
      .. surrounded_text[0]
      .. strcharpart(getline(A), col(A) + len(captured_text[0]) - 1)
    var last_line = strcharpart(getline(B), 0, col(B) - len(captured_text[-1]) - 1)
      .. surrounded_text[-1]
      .. strcharpart(getline(B), col(B))
    echom first_line
    # echom last_line

    if len(surrounded_text)  == 1
      setline(line(A), first_line)
    elseif len(surrounded_text)  == 2
      setline(line(A), first_line)
      setline(line(B), last_line)
    else
      setline(line(A), first_line)
      setline(line(A) + 1, surrounded_text[1 : -1])
      setline(line(B), last_line)
    endif

    # Keep even number of delimiters in the document
    if keep_even
      echom "TBD"
    endif
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

export def InsertLinesAtMark(marker: string, lines: list<string>)
    var pos = getpos(marker)  # Get (line, column) position of the marker
    var line_num = pos[1]     # Line number
    var col = pos[2]          # Column number

    # Get the existing line at the marker
    var current_line = getline(line_num)

    # If the input list is empty, do nothing
    if empty(lines)
        return
    endif

    # If there's only one line in the list, insert it inline
    if len(lines) == 1
        var new_line = strcharpart(current_line, 0, col - 1) .. lines[0] .. strcharpart(current_line, col - 1)
        setline(line_num, new_line)
    else
        # Modify the first line (before the marker)
        var first_part = strcharpart(current_line, 0, col - 1)
        var last_part = strcharpart(current_line, col - 1)

        # Construct the final text to insert
        var new_lines = [first_part .. lines[0]] + lines[1 : ] + [last_part]

        # Insert the lines into the buffer
        # setline(line_num - 1, new_lines)
        append(line_num - 1, new_lines)
    endif
enddef

# export def InsertInLine(marker: string, text: list<string>)
#    # Insert text in the given column
#    var line = getline(line(marker))   # Get the current line
#    var lnum = line(marker)
#    var column = col(marker)
#    var new_line = strcharpart(line, 0, column) .. text .. strcharpart(line, column)
#    setline(lnum, new_line)                  # Set the modified line back
# enddef


export def GetDelimitersRanges(open_delimiter: string,
    close_delimiter: string,
    open_delimiter_length_max: number = 2,
    close_delimiter_length_max: number = 2
    ): list<list<list<number>>>
  # It returns open-intervals, i.e. the delimiters are excluded
  # If there is a spare delimiter, it won't be considered. Delimiters are
  # regex
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
  # 4D format due to that markers have 4-coordinates
  var open_delimiter_pos = [0] + open_delimiter_pos_short + [0]
  var open_delimiter_match = ''
  var open_delimiter_length = 0
  var close_delimiter_pos = [0] + close_delimiter_pos_short + [0]
  var close_delimiter_length = 0
  var close_delimiter_match = ''

  while open_delimiter_pos_short != [0, 0]
    echom "open_delimiter: " .. open_delimiter
    open_delimiter_pos_short = searchpos(open_delimiter, 'W')

    # If you pass a regex, you don't know how long is the captured string
    open_delimiter_match = strcharpart(
      getline(open_delimiter_pos_short[0]),
      open_delimiter_pos_short[1] - 1, open_delimiter_length_max)
      ->matchstr(open_delimiter)
    open_delimiter_length = len(open_delimiter_match)

    if open_delimiter_pos_short[1] + open_delimiter_length == col('$')
      # If the open delimiter is the tail of the line, then the open-interval starts from
      # the next line, column 1
      open_delimiter_pos_short_final[0] = open_delimiter_pos_short[0] + 1
      open_delimiter_pos_short_final[1] = 1
    else
      # Pick the open-interval
      open_delimiter_pos_short_final[0] = open_delimiter_pos_short[0]
      open_delimiter_pos_short_final[1] = open_delimiter_pos_short[1] + open_delimiter_length
    endif
    open_delimiter_pos = [0] + open_delimiter_pos_short_final + [0]

    # Close delimiter
    close_delimiter_pos_short = searchpos(close_delimiter, 'W')
    # If you pass a regex, you don't know how long is the captured string
    close_delimiter_match = strcharpart(
      getline(close_delimiter_pos_short[0]),
      close_delimiter_pos_short[1] - 1, close_delimiter_length_max)
      ->matchstr(close_delimiter)
    close_delimiter_length = len(close_delimiter_match)

    # If the closed delimiter is the lead of the line, then the open-interval starts from
    # the previous line, last column
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
  # echom "ranges :" .. string(ranges)
  remove(ranges, -1)
  # echom "ranges :" .. string(ranges)

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
    var cursor_pos_float = str2float($'{getcharpos(".")[1]}.{getcharpos(".")[2]}')

    # Debugging
    # echom "cur_pos: " .. cursor_pos_float
    # echom "a: " .. string(lower_float)
    # echom "b: " .. string(upper_float)

    # In case the lower limit is larger than the higher limit, swap
    if upper_float < lower_float
      var tmp = upper_float
      upper_float = lower_float
      lower_float = tmp
    endif

    return lower_float <= cursor_pos_float && cursor_pos_float <= upper_float

enddef

export def IsInRange(open_delimiter: string, close_delimiter: string): list<list<number>>
  # Return the range of the delimiters if the cursor is within such a range,
  # otherwise return an empty list.
  # Arguments must be regex.
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

  echom "interval: " .. string(interval)
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
  execute $'norm! {exact_A}v{exact_B}d _'
  # This to get rid off E1186
  return ''
enddef
