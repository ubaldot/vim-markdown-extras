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
