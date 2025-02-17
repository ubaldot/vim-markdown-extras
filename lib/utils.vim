vim9script

export def Echoerr(msg: string)
  echohl ErrorMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

export def Echowarn(msg: string)
  echohl WarningMsg | echom $'[markdown_extras] {msg}' | echohl None
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


def RemoveSurrounding(A: string, B: string, lead: number, trail: number)
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

export def SurroundNew(open_tag: string, close_tag: string, text_object: string = '', keep_even: bool = false)
  # Usage:
  #   Select text and hit <leader> + e.g. parenthesis
  #
  # Note that Visual Selections and Text Objects are cousins
  #
  var A = "'<"
  var B = "'>"
  if !empty(text_object)
    # A and B are "'[" and "']". Basically, GetTextObject is called for
    # setting such markers through a yank
    A = GetTextObject(text_object).start_pos
    B = GetTextObject(text_object).end_pos
  endif

  if getpos(A) == getpos(B)
    return
  endif

  # Capture the tags: TODO: replace with "IsInBetweenMarks"
  var lead = strcharpart(getline(A), col(A) - len(open_tag) - 1, len(open_tag))
  var trail = strcharpart(getline(B), col(B), len(close_tag))

  if lead == tagg && trail == tagg
    RemoveSurrounding(A, B, len(lead), len(trail))
    # Remove surrounding
  else
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

    # Remove all existing tags
    # If there is a tag surrounded by white spaces, keep it as it is not a
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
    surrounded_text[0] = tagg .. cleaned_text[0]
    surrounded_text[-1] = surrounded_text[-1] .. tagg

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

    # Keep even number of tags in the document
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
    var [_, l1, c1, _] = getpos(A)
    var [_, l2, c2, _] = getpos(B)

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

export def g:InsertLinesAtMark(marker: string, lines: list<string>)
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

# export def g:DeleteTextBetweenMarks(A: string, B: string)
#     var start_pos = getpos(A)
#     var end_pos = getpos(B)

#     var start_line = start_pos[1]
#     var start_col = start_pos[2]
#     var end_line = end_pos[1]
#     var end_col = end_pos[2]

#     # ensure a comes before b
#     if start_line > end_line || (start_line == end_line && start_col > end_col)
#         [start_line, start_col, end_line, end_col] =
#                      [end_line, end_col, start_line, start_col]
#     endif

#     # if both markers are on the same line, delete only the in-between text
#     if start_line == end_line
#         var line = getline(start_line)
#         var new_line = strpart(line, 0, start_col - 1) .. strpart(line, end_col - 1)
#         setline(start_line, new_line)
#     else
#         # get affected lines
#         var lines = getline(start_line, end_line)

#         # modify first and last line to remove text between a and b
         # lines[-1] = strpart(lines[-1], end_col - 1)

#         # set lines if any
#         if end_line > start_line + 1
#             deletebufline('%', start_line + 1, end_line - 1)
#         endif
#     endif
# enddef



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
