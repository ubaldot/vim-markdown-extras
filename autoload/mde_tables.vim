vim9script

var gui_cursor: list<dict<any>>

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

export def SumBlock()
  var sum: float = 0.0

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

  echo $'sum: {sum}'
  setreg('s', tmp)
enddef

# ======================
#   TABLE FORMATTING
# ======================

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

  # Remove blank table rows
  var out_clean: list<string> = []
  for l in out
      var cells = SplitRow(l)
      # Keep the line if there is at least one non-empty cell
      if !empty(filter(cells, 'v:val !=# ""'))
          out_clean->add(l)
      endif
  endfor

  # Set the formatted lines back in buffer
  setline(first, out_clean)

  # Delete old trailing rows in case we removed intermediate blank rows
  if len(out) > len(out_clean)
    const first_line_to_be_removed = first + len(out_clean)
    const last_line_to_be_removed = first + len(out) - 1
    deletebufline('%', first_line_to_be_removed, last_line_to_be_removed)
  endif
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

    # Search for last line
    var endline = line('.')
    while !IsDelimiterRowExtended(SplitRow(getline(endline)))
        && getline(endline) !~ '^$' && endline != line('$')
      endline += 1
    endwhile

    # TODO: fix this
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

# =========================
# Cells replacement
# =========================

def GetCellText()
  echo "TODO"
enddef

def ReplaceCell(buf: list<string>, text_alignment: string = '')
  const cell_info = SearchCellDelimiters()

  if empty(cell_info)
    return
  endif

  var buf_padded = buf

  var cell_height = cell_info.endline - cell_info.startline - 1
  var cell_width = cell_info.endcol - cell_info.startcol + 1

  # Pad buffer if needed (buf is too short, we add blank chunks)
  if len(buf) < cell_height
    var pad_string = repeat(' ', cell_width)
    for _ in range(cell_height - len(buf))
      add(buf_padded, pad_string)
    endfor
  endif

  # Replace lines
  cursor(cell_info.startline + 1, 1)
  var ii_offset = -1
  var new_line = ''
  var aligned_val = ''

  # TODO: write logic for different text alignment
  for [ii, val] in items(buf_padded[: cell_height - 1])
    ii_offset = ii + cell_info.startline + 1

    new_line = strcharpart(getline(ii_offset), 0, cell_info.startcol)
      .. $' {val} ' .. strcharpart(getline(ii_offset), cell_info.endcol - 1)

    setline(ii_offset, new_line)
  endfor

  # Pad other cells if the buffer to insert is too large
  if len(buf_padded) > cell_height
    for [ii, val] in items(buf_padded[cell_height : ])
      ii_offset = cell_info.startline + cell_height

      new_line = repeat('| ', cell_info.cell_nr) .. val .. ' |'

      append(ii_offset, new_line)
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

# =========================
#   CELLS UPDATE IN POPUP
# =========================

def HideCursor()
  # hide cursor
  set t_ve=
  gui_cursor = hlget("Cursor")
  hlset([{name: 'Cursor', cleared: true}])
enddef

def RestoreCursor()
  set t_ve&
  if hlget("Cursor")[0]->get('cleared', false)
    hlset(gui_cursor)
  endif
enddef

def PopupFilter(
      id: number,
      key: string,
      popup_text: list<string>,
      popup_cursor: string
    ): bool

  var k = keytrans(key)

  if k == "<Esc>"
    popup_close(id, -1)
    RestoreCursor()
    return true
  endif

  # Get rid off the cursor, you will append it later on again
  popup_text[-1] = strcharpart(popup_text[-1], 0, strchars(popup_text[-1]) - 1)

  # Try/catch because you never know a user what can type
  try
    # All characters that don't start with '<'
    if  k !~ '^<'
      popup_text[-1] ..= k
    # Now all characters that start with '<', e.g., <BS>, <CR>, <Tab>, ...
    elseif k == '<Space>'
      popup_text[-1] ..= ' '
    elseif k == '<Tab>'
      popup_text[-1] ..= '    '
    elseif k ==# '<S-CR>'
      add(popup_text, '')
    elseif k ==# '<BS>'
      # Either remove a char or it goes to the previous line if the current
      # line is empty
      var n = strchars(popup_text[-1])
      if n > 0
        popup_text[-1] = strcharpart(popup_text[-1], 0, n - 1)
      elseif n == 0 && len(popup_text) > 1
        remove(popup_text, -1)
      endif
    elseif k == "<C-U>"
       popup_text[-1] = ''
    elseif k == "<CR>"
      FillCell(id)
      popup_close(id, -1)
      RestoreCursor()
      return true
    else
      echo "unknown key"
    endif
  catch
    popup_clear()
    RestoreCursor()
    throw "Undefined error. Perhaps you are in the first or last line of the buffer?"
  endtry

  popup_text[-1] ..= popup_cursor
  popup_settext(id, popup_text)
  return true
enddef


def FillCell(id: number)
			var bufnr = winbufnr(id)
			var cell_text = getbufline(bufnr, 1, '$')
      cell_text[-1] = strcharpart(cell_text[-1], 0, strchars(cell_text[-1]) - 1)
      ReplaceCell(cell_text)
enddef


def AppendTextToCellPopup()
  echom "TODO"
enddef


export def CreateCellPopup(starting_text: list<string> = [''])
  if !IsTableLine(getline('.'))
    return
  endif

  HideCursor()

  const cursor_shape = '|'
  var popup_text = empty(starting_text) ? [cursor_shape] : starting_text

  const cell_info = SearchCellDelimiters()

  var opts = {
    border: [1, 1, 1, 1],
    borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    line: getcursorcharpos()[1],
    col: getcursorcharpos()[2],
    filter: (id, key) => PopupFilter(id, key, popup_text, cursor_shape),
    scrollbar: 0,
    mapping: 0
  }

  var prompt_id = popup_create(popup_text, opts)
  popup_settext(prompt_id, popup_text)
enddef

# ==================================
#   CELLS UPDATE IN SPLIT WINDOWS
# ==================================

def AppendTextToCellWindow()
  echo "TODO"
enddef

def FillCellFromSplitWindow()
  stopinsert
  var cell_text = getline(1, '$')
  close
  ReplaceCell(cell_text)
enddef

export def CreateCellSplitWindow()
  if !IsTableLine(getline('.'))
    return
  endif

  new
	setlocal buftype=nofile bufhidden=wipe noswapfile
  resize 5
  startinsert

  inoremap <buffer> <CR> <ScriptCmd>FillCellFromSplitWindow()<CR>
  inoremap <buffer> <S-CR> <CR>
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
command! RRR ReplaceCell(foo_long)
command! QQQ CreateCellPopup()
command! AAA CreateCellSplitWindow()

# dict use for testing individual functions
export var funcs_ref_dict = {
  IsTableLine: IsTableLine,
  SplitRow: SplitRow,
  IsDelimiterRow: IsDelimiterRow,
  IsBlankRow: IsBlankRow,
  InsertRowDelimiter: InsertRowDelimiter,
  ReplaceCell: ReplaceCell,
  FormatPipes: FormatPipes,
  FormatTable: FormatTable,
  SearchCellDelimiters: SearchCellDelimiters
}
