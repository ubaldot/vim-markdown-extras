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

def GetColumnAlignments(rows: list<list<string>>, ncols: number): list<string>
  var aligns = repeat(['l'], ncols)

  for row in rows
    if !IsDelimiterRow(row)
      continue
    endif

    for i in range(min([len(row), ncols]))
      var cell = trim(row[i])

      if cell[0] == ':' && cell[-1] == ':'
        aligns[i] = 'c'
      elseif cell[-1] == ':'
        aligns[i] = 'r'
      endif
    endfor

    break
  endfor

  return aligns
enddef

# =========================
#         MAIN
# =========================

def CellWidthSmart(lnum: number, startcol: number, endcol: number): number
  # Computes the width of a cell in chars by taking into account concealed
  # characters
  var line = getline(lnum)
  var width = 0
  var bcol = 1

  for ch in split(line, '\zs')
    if bcol >= endcol
      break
    endif

    if bcol >= startcol
      var [concealed, _, _] = synconcealed(lnum, bcol)

      if !concealed
        width += strdisplaywidth(ch)
      endif
    endif

    bcol += len(ch)
  endfor

  return width
enddef

def CellWidth(lnum: number, startcol: number, endcol: number): number
  var text = strpart(
    getline(lnum),
    startcol - 1,
    endcol - startcol
  )

  return strdisplaywidth(text)
enddef

export def InsertRowDelimiter()

  if !IsTableLine(getline('.'))
    return
  endif

  const saved_cur = getcursorcharpos()

  var curr_line = saved_cur[1]
  var curr_col = 1
  cursor(curr_line, curr_col)

  var ComputeCellWidth = CellWidth
  if exists('g:markdown_extras_config')
        && has_key(g:markdown_extras_config, 'smart_table_format')
        && g:markdown_extras_config.smart_table_format
    ComputeCellWidth = CellWidthSmart
  endif

  # Compute delim
  var delim = ''
  while curr_line == saved_cur[1]
    var pos = searchpos('|', 'W')
    curr_line = pos[0]
    delim ..= '|' .. repeat('-', ComputeCellWidth(curr_line, curr_col + 1, pos[1]))
    curr_col = pos[1]
  endwhile

  appendbufline('%', saved_cur[1], delim)

  setcursorcharpos(saved_cur[1 : 2])
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

  var aligns = GetColumnAlignments(rows, ncols)

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
        parts->add(left_colon .. repeat('-', max([3, dash_count])) .. right_colon)
      else
        # Regular cell: pad spaces
        var pad = widths[i] - strcharlen(cell)

        if aligns[i] ==# 'r'
          parts->add(
            repeat(' ', pad + 1)
            .. cell
            .. ' '
          )

        elseif aligns[i] ==# 'c'
          var left = float2nr(floor(pad / 2.0))
          var right = pad - left

          parts->add(
            repeat(' ', left + 1)
            .. cell
            .. repeat(' ', right + 1)
          )

        else
          parts->add(
            ' '
            .. cell
            .. repeat(' ', pad + 1)
          )
        endif
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


def MarkdownDisplayWidth(text: string): number
  var t = text

  # bold
  t = substitute(t, '\*\*\(.\{-}\)\*\*', '\1', 'g')

  # italic
  t = substitute(t, '\*\(.\{-}\)\*', '\1', 'g')

  # reference links
  t = substitute(t, '\[\([^]]*\)\]\(\[[^]]*\]\)', '\1\2', 'g')

  return strdisplaywidth(t)
enddef

def FormatPipesSmart(first: number, last: number)
  var rows: list<list<string>> = []

  for line in getline(first, last)
    rows->add(SplitRow(line))
  endfor

  var ncols = 0

  for row in rows
    ncols = max([ncols, len(row)])
  endfor

  var widths = repeat([0], ncols)

  # Compute max visible width per column.
  for row in rows
    if IsDelimiterRow(row)
      continue
    endif

    for c in range(len(row))
      widths[c] = max([
        widths[c],
        MarkdownDisplayWidth(row[c])
      ])
    endfor
  endfor

  var aligns = GetColumnAlignments(rows, ncols)

  # Rebuild.
  var out: list<string> = []

  for row in rows
    var parts: list<string> = []

    if IsDelimiterRow(row)
      for c in range(ncols)
        var cell = c < len(row) ? row[c] : ''

        var left_colon = cell =~# '^:' ? ':' : ''
        var right_colon = cell =~# ':$' ? ':' : ''

        var dashes =
          widths[c]
          + 2
          - strlen(left_colon)
          - strlen(right_colon)

        parts->add(
          left_colon
          .. repeat('-', max([3, dashes]))
          .. right_colon
        )
      endfor
    else
      for c in range(ncols)
        var cell = c < len(row) ? row[c] : ''

        var pad = widths[c] - MarkdownDisplayWidth(cell)

        if aligns[c] ==# 'r'
          parts->add(
            repeat(' ', pad + 1)
            .. cell
            .. ' '
          )

        elseif aligns[c] ==# 'c'
          var left = float2nr(floor(pad / 2.0))
          var right = pad - left

          parts->add(
            repeat(' ', left + 1)
            .. cell
            .. repeat(' ', right + 1)
          )

        else
          parts->add(
            ' '
            .. cell
            .. repeat(' ', pad + 1)
          )
        endif
      endfor
    endif

    out->add('|' .. join(parts, '|') .. '|')
  endfor

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

  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'smart_table_format')
      && g:markdown_extras_config['smart_table_format']
    FormatPipesSmart(table_firstline, table_lastline)
  else
    FormatPipes(table_firstline, table_lastline)
  endif
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

def GetCellText(): list<string>
  var cell_info = SearchCellDelimiters()

  if empty(cell_info)
    return ['']
  endif

  var text: list<string> = []

  for lnum in range(
        cell_info.startline + 1,
        cell_info.endline - 1
      )

    var line = getline(lnum)

    var cell =
      strcharpart(
        line,
        cell_info.startcol + 1,
        cell_info.endcol - cell_info.startcol - 2
      )

    add(text, trim(cell))
  endfor

  # Remove trailing empty lines
  while !empty(text) && empty(text[-1])
    remove(text, -1)
  endwhile

  return empty(text) ? [''] : text
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

var popup_state = {}

def RenderPopupText(
    id: number,
    lines: list<string>,
    cursor: string
    ): list<string>

  var display = copy(lines)
  if empty(display)
    display = ['']
  endif

  var state = popup_state[id]

  display[state.row] =
    strcharpart(display[state.row], 0, state.col)
    .. cursor
    .. strcharpart(display[state.row], state.col)

  return display
enddef

def PopupFilter(
    id: number,
    key: string,
    ): bool

  var state = popup_state[id]
  var text = state.text

  var k = keytrans(key)

  if k ==# '<Esc>'
    remove(popup_state, id)
    popup_close(id, -1)
    RestoreCursor()
    return true
  endif

  if k ==# '<CursorHold>'
      || k ==# '<CursorMoved>'
      || k ==# '<FocusGained>'
      || k ==# '<FocusLost>'
    return true
  endif

  try

    # Printable characters
    if k !~ '^<'

      var line = text[state.row]

      text[state.row] =
        strcharpart(line, 0, state.col)
        .. k
        .. strcharpart(line, state.col)

      state.col += strchars(k)

    elseif k ==# '<Space>'

      var line = text[state.row]

      text[state.row] =
        strcharpart(line, 0, state.col)
        .. ' '
        .. strcharpart(line, state.col)

      state.col += 1

    elseif k ==# '<Tab>'

      var tab = repeat(' ', &tabstop)
      var line = text[state.row]

      text[state.row] =
        strcharpart(line, 0, state.col)
        .. tab
        .. strcharpart(line, state.col)

      state.col += strchars(tab)

    elseif k ==# '<Left>'

      if state.col > 0
        state.col -= 1
      elseif state.row > 0
        state.row -= 1
        state.col = strchars(text[state.row])
      endif

    elseif k ==# '<Right>'

      var lenline = strchars(text[state.row])

      if state.col < lenline
        state.col += 1
      elseif state.row < len(text) - 1
        state.row += 1
        state.col = 0
      endif

    elseif k ==# '<Up>'

      if state.row > 0
        state.row -= 1
        state.col = min([
          state.col,
          strchars(text[state.row])
        ])
      endif

    elseif k ==# '<Down>'

      if state.row < len(text) - 1
        state.row += 1
        state.col = min([
          state.col,
          strchars(text[state.row])
        ])
      endif

    elseif k ==# '<BS>'

      if state.col > 0

        var line = text[state.row]

        text[state.row] =
          strcharpart(line, 0, state.col - 1)
          .. strcharpart(line, state.col)

        state.col -= 1

      elseif state.row > 0

        var prevlen = strchars(text[state.row - 1])

        text[state.row - 1] ..= text[state.row]

        remove(text, state.row)

        state.row -= 1
        state.col = prevlen

      endif

    elseif k ==# '<C-U>'

      text[state.row] = ''
      state.col = 0

    elseif k ==# '<S-CR>'

      var line = text[state.row]

      var left =
        strcharpart(line, 0, state.col)

      var right =
        strcharpart(line, state.col)

      text[state.row] = left
      insert(text, right, state.row + 1)

      state.row += 1
      state.col = 0

    elseif k ==# '<CR>'
      # Move cursor to end of last line
      state.row = len(text) - 1
      state.col = strchars(text[-1])

      FillCell(id)

      remove(popup_state, id)
      popup_close(id, -1)
      RestoreCursor()

      return true

    elseif k ==# '<Del>'

      var line = text[state.row]

      if state.col < strchars(line)
        text[state.row] =
          strcharpart(line, 0, state.col)
          .. strcharpart(line, state.col + 1)
      elseif state.row < len(text) - 1
        text[state.row] ..= text[state.row + 1]
        remove(text, state.row + 1)
      endif
    endif

  catch

    if has_key(popup_state, id)
      remove(popup_state, id)
    endif

    popup_clear()
    RestoreCursor()
    throw v:exception

  endtry

  popup_settext(
    id,
    RenderPopupText(id, text, state.cursor)
  )

  return true
enddef

def FillCell(id: number)
  ReplaceCell(popup_state[id].text)
enddef


export def AppendTextToCellPopup()
  CreateCellPopup(GetCellText())
enddef

export def CreateCellPopup(starting_text: list<string> = [''])

  if !IsTableLine(getline('.'))
    return
  endif

  HideCursor()

  const cursor_shape = '|'

  var popup_text = empty(starting_text)
      ? ['']
      : copy(starting_text)

  var opts = {
    border: [1, 1, 1, 1],
    borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    scrollbar: 0,
    mapping: 0,
    filter: PopupFilter,
  }

  var prompt_id = popup_atcursor(popup_text, opts)

  popup_state[prompt_id] = {
    row: len(popup_text) - 1,
    col: strchars(popup_text[-1]),
    text: popup_text,
    cursor: '|',
  }


  popup_settext(
      prompt_id,
      RenderPopupText(
          prompt_id,
          popup_text,
          cursor_shape
      )
  )

enddef

# ==================================
#   CELLS UPDATE IN SPLIT WINDOWS
# ==================================

export def AppendTextToCellWindow()
  CreateCellSplitWindow(GetCellText())
enddef

def FillCellFromSplitWindow()
  stopinsert
  var cell_text = getline(1, '$')
  close
  ReplaceCell(cell_text)
enddef

export def CreateCellSplitWindow(text = [''])
  if !IsTableLine(getline('.'))
    return
  endif

  new
	setlocal buftype=nofile bufhidden=wipe noswapfile
  resize 5

  setline(1, text)

  startinsert
  norm! $

  inoremap <buffer> <CR> <ScriptCmd>FillCellFromSplitWindow()<CR>
  inoremap <buffer> <S-CR> <CR>
  inoremap <buffer> <esc> <cmd>bdelete<CR><esc>
enddef

# dict use for testing individual functions
export var funcs_ref_dict = {
  IsTableLine: IsTableLine,
  SplitRow: SplitRow,
  IsDelimiterRow: IsDelimiterRow,
  IsBlankRow: IsBlankRow,
  InsertRowDelimiter: InsertRowDelimiter,
  ReplaceCell: ReplaceCell,
  FormatPipes: FormatPipes,
  FormatPipesSmart: FormatPipesSmart,
  CellWidth: CellWidth,
  CellWidthSmart: CellWidthSmart,
  FormatTable: FormatTable,
  SearchCellDelimiters: SearchCellDelimiters
}
