vim9script

def Echoerr(msg: string)
  echohl ErrorMsg | echom $'[markdown_extras] {msg}' | echohl None
enddef

def Echowarn(msg: string)
  echohl WarningMsg | echom $'[markdown_extras] {msg}' | echohl None
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

def GetTextObject(textobject: string): string
  # You pass a text object like "inside word", etc. and it returns it.
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
  return text
enddef

export def VisualSurround(pre: string, post: string)
  # Usage:
  #   Visual select text and hit <leader> + parenthesis
  #
  var pre_len = strlen(pre)
  var post_len = strlen(post)
  var [line_start, column_start] = getpos("'<")[1 : 2]
  var [line_end, column_end] = getpos("'>")[1 : 2]
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

  # echom "leading_chars: " .. leading_chars
  # echom "trailing_chars: " .. trailing_chars

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

def MDIsLink(): bool
  # Compare foo with [foo]. If they match, then what is inside the [] it
  # possibly be a link. Next, it check if there is a (bla_bla) just after ].
  # Link alias must be words.
  # Assume that a link (or a filename) cannot be broken into multiple lines
  var saved_curpos = getcurpos()
  var is_link = false
  var alias_link = GetTextObject('iw')

  # Handle singularity if the cursor is on '[' or ']'
  if alias_link == '['
    norm! l
    alias_link = GetTextObject('iw')
  elseif alias_link == ']'
    norm! h
    alias_link = GetTextObject('iw')
  endif

  # Check if foo and [foo] match and if there is a [bla bla] after ].
  var alias_link_bracket = GetTextObject('a[')
  if alias_link == alias_link_bracket[1 : -2]
    norm! f]
    if getline('.')[col('.')] == '('
        || getline('.')[col('.')] == '['
      var line_open_parenthesis = line('.')
      norm! l%
      var line_close_parenthesis = line('.')
      if line_open_parenthesis == line_close_parenthesis
        # echo "Is a link"
        is_link = true
      else
        # echo "Is not a link"
        is_link = false
      endif
    else
      # echo "Is not a link"
      is_link = false
    endif
  else
    # echo "Is not a link"
    is_link = false
  endif
  setpos('.', saved_curpos)
  return is_link
enddef

export def MDToggleMark()
  var line = getline('.')
  if match(line, '\[\s*\]') != -1
    setline('.', substitute(line, '\[\s*\]', '[x]', ''))
  elseif match(line, '\[x\]') != -1
    setline('.', substitute(line, '\[x\]', '[ ]', ''))
  endif
enddef

def OpenLink()
    norm! f[l
    var link_id = GetTextObject('i[')
    var link = links_dict[link_id]
    if filereadable(link)
      exe $'edit {link}'
    elseif exists(':Open') != 0
      exe $'Open {link}'
    elseif IsURL(link)
      # TODO: I have :Open everywhere but on macos
      silent exe $'!{g:start_cmd} -a safari.app "{link}"'
    else
      echoerr $"File {link} does not exists!"
    endif
enddef

var links_dict = {}

def GetLinkID(): number
  var link = input('Insert link: ', '', 'file')
  if empty(link)
    return 0
  endif

  # TODO: use full-path?
  if !IsURL(link)
    link = fnamemodify(link, ':p')
  endif
  var link_line = search(link, 'nw')
  var link_id = 0
  if link_line == 0
    # Entirely new link
    link_id = keys(links_dict)->map('str2nr(v:val)')->max() + 1
    links_dict[$'{link_id}'] = link
    # If it is the first link ever, leave a blank line
    if link_id == 1 && search('\s*#\+\s\+References', 'nw') != 0
      append(line('$'), '' )
    elseif link_id == 1 && search('\s*#\+\s\+References', 'nw') == 0
      append(line('$'), ['', '## References', ''])
    endif
    append(line('$'), $'[{link_id}]: {link}' )
  else
    # Reuse existing link
    var tmp = getline(link_line)->substitute('\v^\[(\d*)\].*', '\1', '')
    link_id = str2nr(tmp)
  endif
  return link_id
enddef

def IsURL(link: string): bool
  var url_prefixes = [ 'https://', 'http://', 'ftp://', 'ftps://',
    'sftp://', 'telnet://', 'file://']
  for url_prefix in url_prefixes
    if link =~ $'^{url_prefix}'
      return true
    endif
  endfor
    return false
enddef

def GenerateLinksDict()
  var ref_start_line = search('\s*#\+\s\+References', 'nw')
  var refs = getline(ref_start_line + 1, '$')
    ->filter('v:val =~ "^\\[\\d\\+\\]:\\s"')
  for item in refs
     var key = item->substitute('\[\(\d\+\)\].*', '\1', '')
     var value = item->substitute('^\[\d\+]\:\s*\(.*\)', '\1', '')
     links_dict[key] = value
  endfor
enddef

export def MDRemoveLink()
  # Initialization
  if empty(links_dict)
    GenerateLinksDict()
  endif
  # TODO: it may not be the best but it works so far
  if MDIsLink()
      search('[')
      norm! "_da[
      search(']', 'bc')
      norm! "_x
      search('[', 'bc')
      norm! "_x
  endif
enddef

# TODO
def MDCleanupReferences()
  echoerr Not Implemented!
enddef

export def MDHandleLink()
  # Initialization
  if empty(links_dict)
    GenerateLinksDict()
  endif
  if MDIsLink()
    OpenLink()
  else
    var link_id = GetLinkID()
    if link_id == 0
      return
    endif
    # Surround stuff
    norm! lbi[
    norm! ea]
    execute $'norm! a[{link_id}]'
    norm! F]h
    if !IsURL(links_dict[link_id]) && !filereadable(links_dict[link_id])
      exe $'edit {links_dict[link_id]}'
      # write
    endif
  endif
enddef


export def MDContinueList()
  # OBS! If there are issues, check 'formatlistpat' value for markdown
  # filetype
  # For continuing items list and enumerations
  # Check if the current line starts with '- [ ]' or '- '
  var variant_1 = '-\s\[\s*\]\s\+' # - [ ] bla bla bla
  var variant_2 = '-\s\+' # - bla bla bla
  var variant_3 = '\*\s\+' # * bla bla bla
  var variant_4 = '\d\+\.\s\+' # 123. bla bla bla

  var current_line = join(
  getline(
  search($'\({variant_1}\|{variant_2}\|{variant_3}\|{variant_4}\|\n\n\)', 'bn'),
  line('.')),
    '\n')

  var tmp = ''
  # There is only a buller with no text. Next <CR> shall remove the bullet
  var only_bullet = false


  # Check if you only have the bullet with no item
  for variant in [variant_1, variant_2, variant_3, variant_4]
    if current_line =~ $'^\s*{variant}\s*$'
          append(line('.'), '')
          deletebufline('%', line('.'))
          only_bullet = true
          break
    endif
  endfor

  # Scan the current line through the less general regex (a regex can be
  # contained in another regex)
  if !only_bullet
     if current_line =~ $'^\s*{variant_1}'
       tmp = $"{current_line->matchstr($'^\s*{variant_1}')}"
     elseif current_line =~ $'^\s*{variant_2}'
       tmp = $"{current_line->matchstr($'^\s*{variant_2}')}"
     elseif current_line =~ $'^\s*{variant_3}'
       tmp = $"{current_line->matchstr($'^\s*{variant_3}')}"
     elseif current_line =~ $'^\s*{variant_4}'
       # Get rid of the trailing '.' and convert to number
       var curr_nr = str2nr(
         $"{current_line->matchstr($'^\s*{variant_4}')->matchstr('\d\+')}"
       )
       tmp = $"{current_line->matchstr($'^\s*{variant_4}')
             \ ->substitute(string(curr_nr), string(curr_nr + 1), '')}"
     endif
  endif

  # Add the correct newline
  append(line('.'), $"{tmp}")
  cursor(line('.') + 1, col('$') - 1)
  startinsert

enddef

# Set-unset blocks

def SetBlock(tag: string, start_line: number, end_line: number)
  append(start_line - 1, tag)
  norm! '<k
  while line('.') != end_line
    norm! j0d^>>
  endwhile
  append(line('.'), tag)
enddef

# TODO
def UnsetBlock(tag: string)
  echom "TO BE IMPLEMENTED"
enddef

def GetBlockRanges(tag: string): list<list<number>>
 # Initialize an empty list to store ranges
  var ranges = []

  # Initialize a variable to keep track of the start line
  var start_line = -1

  # Loop through each line in the buffer
  for ii in range(1, line('$'))
    # Get the current line content
    var line_content = getline(ii)

    # Check if the line contains the delimiter
    if line_content =~ tag
      # If start_line is -1, this is the start of a block
      if start_line == -1
        start_line = ii
      else
        # This is the end of a block, add the range to the list
        add(ranges, [start_line, ii])
        start_line = -1
      endif
    endif
  endfor
  return ranges
enddef

def ToggleBlock(tag: string, line_start: number, line_end: number)
  var inside_block = false
  var ranges = GetBlocksRanges(tag)
  var current_line = line('.')

  # Check if inside a block
  for range in ranges
    if current_line >= range[0] && current_line <= range[1]
      inside_block = true
      break
    endif
  endfor

  # Set or unset
  if inside_block
    SetBlock(tag, line_start, line_end)
  else
    UnsetBlock(tag)
  endif
enddef
