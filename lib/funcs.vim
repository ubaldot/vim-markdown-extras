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
       # If - [x], the next item should be - [ ] anyway.
       tmp = $"{current_line->matchstr($'^\s*{variant_1}')->substitute('x', ' ', 'g')}"
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

# ----------------------------
# Set-unset code-blocks
# ----------------------------
def SetBlockStartEndLines(start_line: number = -1,
      \ end_line: number = -1): list<number>
  # Check if the passed lines are valid, or ask for user input
  # If any of the lines has a negative number, it returns an empty list

  var range_str = ''
  var l0 = -1
  var l1 = -1

  # UBA
  if start_line == -1 || end_line == -1
    range_str = input('Enter range of the code-block: ')
    if empty(range_str)
      return []
    endif
    l0 = str2nr(split(range_str, ',')[0])
    l1 = str2nr(split(range_str, ',')[1])
    # Lines must be positive
    if l0 < 1 || l1 < 1
     return []
    endif
  else
    l0 = start_line
    l1 = end_line
  endif

  return [l0, l1]
enddef



def SetBlock(tag: string, start_line: number = -1,
      \  end_line: number = -1, fence: string = '')
  # This is redundant, the check already happens in ToggleCodeBlock
  if IsInsideBlock(tag) || getline(line('.')) =~ $'^{tag}'
    return
  endif

  # Get actual first and last line of the block
  var block_range = SetBlockStartEndLines(start_line, end_line)
  if empty(block_range)
    return
  endif

  # TODO Will never happen...
  var user_fence = 'kbvasLvkbdfkb'

  # If you don't want any language, just set
  #   g:markdown_extras_config['code_block_language'] = ''
  #
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'code_block_language')
    user_fence = g:markdown_extras_config['code_block_language']
  endif

  if user_fence == 'kbvasLvkbdfkb'
    user_fence = input('Enter code-block language: ')
  endif

  var l0 = block_range[0]
  var l1 = block_range[1]

  # Create block (indenting included)
  # append(l0 - 1, $'{tag}{user_fence}')
  append(l0, $'{tag}{user_fence}')
  # cursor(l0 + 1, 1)

  silent! execute $':{l0 + 1},{l1}s/^\s\+//'
  silent! execute $':{l0 + 2},{l1}>'
  append(l1, tag)
enddef

def UnsetBlock(tag: string)
  if !IsInsideBlock(tag) || getline(line('.')) =~ $'^{tag}'
    return
  else
    var l0 = search(tag, 'cnb')
    var l1 = search(tag, 'cn')

    # Remove indent
    silent! execute $':{l0 + 1},{l1 + 1}s/^\s\+//'

    # Remove tags
    deletebufline(bufnr('%'), l0)
    deletebufline(bufnr('%'), l1 - 1)
  endif
enddef


def GetBlocksRanges(tag: string): list<list<number>>
 # Return a list of lists, where each element delimits a block in the current buffer.
 # E.g. [[38, 33], [46 89]] => two blocks with their range in current buffer
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
        # Extremes are excluded
        # This is the end of a block, add the range to the list
        add(ranges, [start_line, ii])
        start_line = -1
      endif
    endif
  endfor
  return ranges
enddef

# ciai aii aiaia XXX#
def IsInsideBlock(tag: string): bool
  var is_inside_block = false
  var ranges = GetBlocksRanges(tag)
  var current_line = line('.')

  # Check if inside a block
  for range in ranges
    if current_line >= range[0] && current_line <= range[1]
      is_inside_block = true
      break
    endif
  endfor

  return is_inside_block
enddef


export def ToggleBlock(tag: string, line_start: number = -1,
      \  line_end: number = -1, fence: string = '')
  # Set or unset
  if getline(line('.')) =~ $'^{tag}'
    return
  endif

  if !IsInsideBlock(tag)
    SetBlock(tag, line_start, line_end, fence)
  else
    UnsetBlock(tag)
  endif
enddef
