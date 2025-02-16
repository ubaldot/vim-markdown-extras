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

export def SurroundNew(tag: string, text_object: string = '', keep_even: bool = false)
  # Usage:
  #   Select text and hit <leader> + e.g. parenthesis
  #
  # Note that Visual Selections and Text Objects are cousins
  #
  var A = "'<"
  var B = "'>"
  if !empty(text_object)
    A = GetTextObject(text_object).start_pos
    B = GetTextObject(text_object).end_pos
  endif

  # Remove all existing tags
  var surrounded_text = GetTextBetweenMarks(A, B)
    ->map((_, val) => substitute(val, tag, '', 'g'))

  # Surround text
  insert(surrounded_text, tag, 0)
  insert(surrounded_text, tag, len(surrounded_text))

  echom "surrounded_text: " .. string(surrounded_text)

  # Delete old text
  execute $":{A},{B}d _"

  # Add surrounded text
  InsertInLine(A, join(surrounded_text))

  # Keep even number of tags in the document
  if keep_even
    echom "TBD"
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

export def GetTextBetweenMarks(A: string, B: string): list<string>
    # Usage: GetTextBetweenPoints("'[", "']"). Arguments must be markers.
    #
    var [_, l1, c1, _] = getpos(A)
    var [_, l2, c2, _] = getpos(B)

    if l1 == l2
        # Extract text within a single line
        return [getline(l1)[c1 - 1 : c2 - 2]]
    else
        # Extract text across multiple lines
        var lines = getline(l1, l2)
        lines[0] = lines[0][c1 - 1 : ]  # Trim the first line from c1
        lines[-1] = lines[-1][ : c2 - 2]  # Trim the last line up to c2
        return lines
    endif
enddef

export def InsertInLine(marker: string, text: string)
   # Insert text in the given column
   var line = getline(line(marker))   # Get the current line
   var lnum = line(marker)
   var column = col(marker)
   var new_line = strcharpart(line, 0, column) .. text .. strcharpart(line, column)
   setline(lnum, new_line)                  # Set the modified line back
enddef

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
#         lines[0] = strpart(lines[0], 0, start_col - 1)
#         lines[-1] = strpart(lines[-1], end_col - 1)

#         # set modified text back
#         setline(start_line, lines[0])
#         setline(end_line, lines[-1])

#         # delete middle lines if any
#         if end_line > start_line + 1
#             deletebufline('%', start_line + 1, end_line - 1)
#         endif
#     endif
# enddef



export def g:DeleteTextBetweenMarks(A: string, B: string)
  execute $'norm! {A}v{B}d _'
enddef
