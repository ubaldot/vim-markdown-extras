vim9script

var sum = 0.0
export def SumBlock()

  var tmp = getreg('s')
  silent norm! "sy

  var numbers: list<any>
  if @s =~ "\|"
    numbers = split(@s, "\|")
  else
    numbers = split(@s)
  endif

  for v in numbers
    sum += str2float(v)
  endfor

  echo $"sum: {total}"
  total = 0.0
  setreg('s', tmp)
enddef

export def InsertRowDelimiter()
  const p = '^\s*|\s*.*\s*|\s*$'
  const curr_line = line('.')
  if getline(curr_line) =~ p
    appendbufline('%', curr_line, getline(curr_line)
      ->substitute('[^\|]', '-', 'g'))
      # ->substitute('|-', '| ', 'g')
      # ->substitute('-|', ' |', 'g'))
  endif
enddef

def AlignPipes(first: number, last: number)
  var lines = getline(first, last)

  # Split rows into cells
  var rows: list<list<string>> = []
  for line in lines
    var cells = split(line, '|')
      ->map((_, v) => trim(v))
    rows->add(cells)
  endfor

  # Compute max length per column (character-based)
  var ncols = max(rows->mapnew((_, r) => len(r)))
  var widths = repeat([0], ncols)

  for r in rows
    for i in range(len(r))
      widths[i] = max([widths[i], strcharlen(r[i])])
    endfor
  endfor

  # Rebuild aligned lines
  var out: list<string> = []
  for r in rows
    var parts: list<string> = []
    for i in range(len(r))
      parts->add(
        ' ' .. r[i] .. repeat(' ', widths[i] - strcharlen(r[i]) + 1)
      )
    endfor
    out->add($'|{join(parts, "\|")}|')
  endfor

  setline(first, out)
enddef

export def Align()
  const p = '^\s*|\s*.*\s*|\s*$'
  if getline('.') =~# '^\s*|'

    # Save column and position
    const curpos = getcursorcharpos()[1 : 2]

    # Search for first line
    var startline = line('.')
    if startline != 1
      while getline(startline - 1) =~ p
        startline = search(p, 'bW')
      endwhile
    endif
    setcursorcharpos(curpos)

    # Search for last line
    var endline = line('.')
    if endline != line('$')
      while getline(endline + 1) =~ p
        endline = search(p, 'W')
      endwhile
    endif
    setcursorcharpos(curpos)

    # Easy align
    AlignPipes(startline, endline)
    setcursorcharpos(curpos)

  endif
enddef
