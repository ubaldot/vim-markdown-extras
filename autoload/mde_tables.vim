vim9script


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
#         MAIN
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

# =========================
# Cells replacement
# =========================

def ReplaceCell(buf: list<string>)
  const cell_prop = SearchRowDelimitersRange()

  if empty(cell_prop)
    return
  endif

  var cell_height = cell_prop.endline - cell_prop.startline - 1
  var pad_size = len(buf) - cell_height

  # Find number of cells per row
  cursor(line('.'), 1)
  const num_cells = getline(line('.'))->filter("v:val == '\|'")->len()

  # Find col1 and col2 of the target cell
  for _ in range(cell_prop.cell_nr - 1)
    searchpos('|')
  endfor
  const cell_delim_pos1 = getcursorcharpos()[2]
  const cell_delim_pos2 = searchpos('|')[1]

  # Replace lines
  cursor(cell_prop.startline + 1, 1)
  var ii_offset = -1
  var new_line = ''
  for [ii, val] in items(buf[: cell_height - 1])
    ii_offset = ii + cell_prop.startline + 1

    new_line = strcharpart(getline(ii_offset), 0, cell_delim_pos1)
      .. $' {val} ' .. strcharpart(getline(ii_offset), cell_delim_pos2 - 1)

    setline(ii_offset, new_line)
  endfor

  # Padding if the buffer to insert is too large
  if len(buf) > cell_height
    for [ii, val] in items(buf[cell_height : ])
      ii_offset = cell_prop.startline + cell_height

      new_line = repeat('| ', cell_prop.cell_nr) .. val .. ' |'

      append(ii_offset, new_line)
    endfor
  endif

  # Make it nice and put the cursor on a nice spot
  Align()
  cursor(line('.'), 1)
  for _ in range(cell_prop.cell_nr - 1)
    search('|')
  endfor
  norm! w

enddef

def SearchRowDelimitersRange(): dict<any>
  var delim_range = {}

  if IsTableLine(getline('.')) && !IsDelimiterRow(SplitRow(getline('.')))

    const cell_nr = strcharpart(getline(line('.')), 0, col('.') - 1)
      ->filter("v:val == '\|'")->len()

    # Start row delimiters search
    # Save column and position
    const curpos = getcursorcharpos()[1 : 2]

    # Search for first line
    var startline = line('.')
    # while getline(startline) !~ delim_regex && getline(startline) !~ '^$' && startline != 0
    while !IsDelimiterRow(SplitRow(getline(startline))) && getline(startline) !~ '^$' && startline != 0
      startline -= 1
    endwhile
    setcursorcharpos(curpos)

    if startline == 0
      echoerr 'You are on the first line'
      return delim_range
    endif

    # Search for last line
    var endline = line('.')
    while !IsDelimiterRow(SplitRow(getline(endline))) && getline(endline) !~ '^$' && endline != line('$')
      endline += 1
    endwhile

    setcursorcharpos(curpos)

    if endline == line('$')
      echoerr 'You are on the last line'
      return delim_range
    endif

    delim_range = {cell_nr: cell_nr, startline: startline, endline: endline}
  endif

  return delim_range
enddef

# ------- TEST VALUES ---------
var foo = ['hello hello',
  'bella signora',
  'mi farei proprio una bella chiavata'
]

command! RRR ReplaceCell(foo)
