vim9script


def IsTableLine(line: string): bool
  # It is enough that you have one column delimited by | ... | to be a table
  return line =~# '^\s*|\s*.*\s*|\s*$'
enddef

def SplitRow(line: string): list<string>
  # Drop leading/trailing |, then split.
  #
  # For delimiters, we expect to have lists like ['-----', ':----:', '---:']
  var inner = line
    ->substitute('^\s*|\s*', '', '')
    ->substitute('\s*|\s*$', '', '')
  return split(inner, '\s*|\s*', true)
enddef

def IsDelimiterRow(row: list<string>): bool
  # The ':' in a table delimiter establish the text alignment in
  # markdown. For instance, ':------' is left-align text, ':-------:' is
  # center-aligned text and '------:' is right-aligned text.
  #
  # Therefore, the idea to detect delimiters is to check lists like
  # ['------', '-----', '-----'] or lists like this:
  # [':------', ':--------:', '---------'], etc.
  for cell in row
    if cell !~# '^\s*[:-]\+\s*$'
      return false
    endif
  endfor
  return true
enddef

def IsBlankRow(row: list<string>): bool
    # A row is blank if all cells are empty strings
    return empty(row->filter('v:val !=# ""'))
enddef

def IsDelimiterRowExtended(row: list<string>): bool
  # A delimiter is either a classic markdown delimiter or a blank line
  return IsDelimiterRow(row) || IsBlankRow(row)
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

# =========================
# Cells replacement
# =========================

def ReplaceCell(buf: list<string>, text_alignment: string = 'l')
  const cell_info = SearchCellDelimiters()

  if empty(cell_info)
    return
  endif

  var cell_height = cell_info.endline - cell_info.startline - 1
  var pad_size = len(buf) - cell_height

  # Replace lines
  cursor(cell_info.startline + 1, 1)
  var ii_offset = -1
  var new_line = ''
  var aligned_val = ''
  for [ii, val] in items(buf[: cell_height - 1])
    ii_offset = ii + cell_info.startline + 1

    new_line = strcharpart(getline(ii_offset), 0, cell_info.startcol)
      .. $' {val} ' .. strcharpart(getline(ii_offset), cell_info.endcol - 1)

    setline(ii_offset, new_line)
  endfor

  # Padding if the buffer to insert is too large
  if len(buf) > cell_height
    for [ii, val] in items(buf[cell_height : ])
      ii_offset = cell_info.startline + cell_height

      new_line = repeat('| ', cell_info.cell_nr) .. val .. ' |'

      append(ii_offset, new_line)
    endfor
  endif

  # Padding if the buffer to insert is too small
  if len(buf) < cell_height

    var range_to_pad = range(cell_info.startline + len(buf) + 1, cell_info.endline - 1)
    for ii in range_to_pad

      new_line = strcharpart(getline(ii), 0, cell_info.startcol - 1)
         .. repeat(' ', cell_info.endcol - cell_info.startcol)
        .. strcharpart(getline(ii), cell_info.endcol - 1)

      setline(ii, new_line)
    endfor
  endif

  # Make the table nice
  FormatTable()

  # Put the cursor on a nice spot
  cursor(line('.'), 1)
  for _ in range(cell_info.cell_nr - 1)
    search('|')
  endfor
  norm! w

enddef

def FormatPipes(first: number, last: number)
  var lines = getline(first, last)

  # Parse rows into lists of cells
  var rows: list<list<string>> = []
  for l in lines
    rows->add(SplitRow(l))
  endfor

  # Compute number of columns
  var ncols = 0
  for r in rows
    ncols = max([ncols, len(r)])
  endfor

  # Compute max width per column (text width only)
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
        # Preserve alignment colons
        var left_colon  = cell =~# '^:' ? ':' : ''
        var right_colon = cell =~# ':$' ? ':' : ''

        # Compute number of dashes to pad
        var dash_count = widths[i] + 2 - strcharlen(left_colon) - strcharlen(right_colon)
        parts->add(left_colon .. repeat('-', dash_count) .. right_colon)
      else
        # Regular cell: pad spaces
        parts->add(' ' .. cell .. repeat(' ', widths[i] - strcharlen(cell) + 1))
      endif
    endfor

    # Join cells with | and add leading/trailing |
    out->add('|' .. join(parts, '|') .. '|')
  endfor

  # Set the formatted lines back in buffer
  setline(first, out)
enddef

export def FormatTable()
  if !IsTableLine(getline('.'))
    return
  endif

  # Make the table nice
  const table_firstline = search('^$', 'nbW') == 0
    ? 1
    : search('^$', 'nbW') + 1

  const table_lastline = search('^$', 'nW') == 0
    ? line('$')
    : search('^$', 'nW') - 1

  FormatPipes(table_firstline, table_lastline)
enddef

def SearchCellDelimiters(): dict<any>
  # Extract information about the current cell, such as left and righ
  # columns, upper and lower lines, number of cells, etc.

  var cell_info = {}

  if IsTableLine(getline('.'))
      && !IsDelimiterRowExtended(SplitRow(getline('.')))

    # Search for first line
    var startline = line('.')
    # while getline(startline) !~ delim_regex && getline(startline) !~ '^$' && startline != 0
    while !IsDelimiterRowExtended(SplitRow(getline(startline)))
        && getline(startline) !~ '^$' && startline != 0
      startline -= 1
    endwhile

    if startline == 0
      echoerr 'You are on the first line'
      return cell_info
    endif

    # Search for last line
    var endline = line('.')
    while !IsDelimiterRowExtended(SplitRow(getline(endline)))
        && getline(endline) !~ '^$' && endline != line('$')
      endline += 1
    endwhile

    if endline == line('$')
      echoerr 'You are on the last line'
      return cell_info
    endif

    # Find number of cells per row
    const curpos = getcursorcharpos()[1 : 2]
    cursor(line('.'), 1)

    const num_cells = getline(line('.'))->filter("v:val == '\|'")->len() - 1

    setcursorcharpos(curpos)

    # Search for cell_nr
    const cell_nr = strcharpart(getline(line('.')), 0, col('.') - 1)
      ->filter("v:val == '\|'")->len()

    # Find startcol and endcol
    cursor(line('.'), 1)

    for _ in range(cell_nr - 1)
      searchpos('|')
    endfor
    const startcol = getcursorcharpos()[2]
    const endcol = searchpos('|')[1]

    setcursorcharpos(curpos)

    # Find text alignment
    var text_alignment = ''
    var cell_head_delim = strcharpart(getline(startline), startcol, endcol - startcol - 1)
    if cell_head_delim =~ '^\s*:-*:\s*$'
      text_alignment = 'c'
    elseif cell_head_delim =~ '^\s*-*:\s*$'
      text_alignment = 'r'
    else
      # Default,
      #  ':-----'
      #  '------'
      #  '^$'
      text_alignment = 'l'
    endif

    # Assemble result
    cell_info = {cell_nr: cell_nr,
      num_cells: num_cells,
      startcol: startcol,
      endcol: endcol,
      startline: startline,
      endline: endline,
      text_alignment: text_alignment}
  endif

  return cell_info
enddef

# ------- TEST VALUES ---------
var foo_short = ['hello hello',
]

var foo_equal = ['hello hello',
  'bella signora',
]

var foo_long = ['hello hello',
  'bella signora',
  'mi farei proprio una bella chiavata'
]
command! RRR ReplaceCell(foo_short)
