vim9script

# =========================
# Helpers
# =========================

def IsTableLine(line: string): bool
  return line =~# '^\s*|\s*.*\s*|\s*$'
enddef

def SplitRow(line: string): list<string>
  # Drop leading/trailing |, then split
  var inner = line
    ->substitute('^\s*|\s*', '', '')
    ->substitute('\s*|\s*$', '', '')
  return split(inner, '\s*|\s*', true)
enddef

def IsDelimiterRow(row: list<string>): bool
  for cell in row
    if cell !~# '^\s*[:-]\+\s*$'
      return false
    endif
  endfor
  return true
enddef

# =========================
# Core alignment
# =========================

def AlignPipes(first: number, last: number)
  var lines = getline(first, last)

  # Parse rows
  var rows: list<list<string>> = []
  for l in lines
    rows->add(SplitRow(l))
  endfor

  # Compute column count
  var ncols = 0
  for r in rows
    ncols = max([ncols, len(r)])
  endfor

  # Compute max width per column (character-based)
  var widths = repeat([0], ncols)

  for r in rows
    if IsDelimiterRow(r)
      continue
    endif
    for i in range(len(r))
      widths[i] = max([widths[i], strcharlen(r[i])])
    endfor
  endfor

  # Rebuild lines
  var out: list<string> = []

  for r in rows
    var is_delim = IsDelimiterRow(r)
    var parts: list<string> = []

    for i in range(ncols)
      var cell = i < len(r) ? r[i] : ''

      if is_delim
        parts->add(repeat('-', widths[i] + 2))
      else
        parts->add(
          ' ' .. cell .. repeat(' ', widths[i] - strcharlen(cell) + 1)
        )
      endif
    endfor

    out->add('|' .. join(parts, '|') .. '|')
  endfor

  setline(first, out)
enddef

# =========================
# Public entry point
# =========================

export def InsertRowDelimiter()
  const p = '^\s*|\s*.*\s*|\s*$'
  const curr_line = line('.')

  if getline(curr_line) =~# p
    appendbufline(
      '%',
      curr_line,
      getline(curr_line)->substitute('[^|]', '-', 'g')
    )
  endif
enddef


export def Align()
  if !IsTableLine(getline('.'))
    return
  endif

  # Save cursor position
  var curpos = getcursorcharpos()[1 : 2]

  # Find table start
  var startline = line('.')
  while startline > 1 && IsTableLine(getline(startline - 1))
    startline -= 1
  endwhile

  # Find table end
  var endline = line('.')
  while endline < line('$') && IsTableLine(getline(endline + 1))
    endline += 1
  endwhile

  AlignPipes(startline, endline)

  # Restore cursor
  setcursorcharpos(curpos)
enddef

def ReplaceCell(buf: list<string>)
  const tab_col_prop = SearchRowDelimitersRange()

  if empty(tab_col_prop)
    return
  endif

  var tab_col_height = tab_col_prop.endline - tab_col_prop.startline - 1
  var pad_size = len(buf) - tab_col_height

  # Find total number of table columns (aka cells)
  cursor(line('.'), 1)
  const num_tab_cols = getline(line('.'))->filter("v:val == '\|'")->len()

  # Find col1 and col2 of the target cell
  for _ in range(tab_col_prop.tab_col_nr - 1)
    searchpos('|')
  endfor
  const tab_col_delim_pos1 = getcursorcharpos()[2]
  const tab_col_delim_pos2 = searchpos('|')[1]

  # Replace lines
  cursor(tab_col_prop.startline + 1, 1)
  var ii_offset = -1
  var new_line = ''
  for [ii, val] in items(buf[: tab_col_height - 1])
    ii_offset = ii + tab_col_prop.startline + 1
    new_line = strcharpart(getline(ii_offset), 0, tab_col_delim_pos1)
    .. $' {val} ' .. strcharpart(getline(ii_offset), tab_col_delim_pos2 - 1)
    setline(ii_offset, new_line)
  endfor

  if len(buf) > tab_col_height
    for [ii, val] in items(buf[tab_col_height : ])
      ii_offset = tab_col_prop.startline + tab_col_height
      new_line = repeat('| ', tab_col_prop.tab_col_nr) .. val .. ' |'
      append(ii_offset, new_line)
    endfor
  endif

  Align()
enddef

def SearchRowDelimitersRange(): dict<any>
  messages clear
    const delim_regex = '\v^\|\s*-+\s*(\|\s*-+\s*)*\|\s*$'
    var delim_range = {}

  if getline('.') =~# '^\s*|' && getline('.') !~ delim_regex

    const tab_col_nr = strcharpart(getline(line('.')), 0, col('.') - 1)
      ->filter("v:val == '\|'")->len()

    # Start row delimiters search
    # Save column and position
    const curpos = getcursorcharpos()[1 : 2]

    # Search for first line
    var startline = line('.')
    while getline(startline) !~ delim_regex && getline(startline) !~ '^$' && startline != 1
      startline -= 1
    endwhile
    setcursorcharpos(curpos)

    if getline(startline) =~ '^$'
      echoerr 'Upper delimiter not found!'
      return delim_range
    endif

    # Search for last line
    var endline = line('.')
    while getline(endline) !~ delim_regex && getline(endline) !~ '^$' && endline != line('$')
      endline += 1
    endwhile

    setcursorcharpos(curpos)

    if getline(endline) =~ '^$' || endline == line('$')
      echoerr 'Lower delimiter not found!'
      return delim_range
    endif

    delim_range = {tab_col_nr: tab_col_nr, startline: startline, endline: endline}
  endif

  return delim_range
enddef

var foo = ['ciao ciao',
'bella signora',
'mi farei proprio una bella chiavata'
]

command! RRR ReplaceCell(foo)

# nmap ga <ScriptCmd>Align()<cr>

# xnoremap <c-s> <ScriptCmd>SumBlock()<cr>
# inoremap <silent> <Bar> <Bar><Esc><ScriptCmd>Align()<CR>a
# command! -nargs=0 TableDelimiter InsertRowDelimiter()
