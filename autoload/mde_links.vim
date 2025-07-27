vim9script

import autoload './mde_constants.vim' as constants
import autoload './mde_utils.vim' as utils

var main_id: number
var prompt_id: number

var prompt_cursor: string
var prompt_sign: string
var prompt_text: string

var fuzzy_search: bool

var popup_width: number
var links_popup_opts: dict<any>

var large_files_threshold: number

const references_comment =
  "<!-- DO NOT REMOVE vim-markdown-extras references DO NOT REMOVE-->"

export def URLToPath(url: string): string
  # Strip the file:// prefix
  var path = substitute(url, '^file://', '', '')

  # Decode percent-encoded characters
  path = substitute(path, '%\(\x\x\)', '\=nr2char(str2nr(submatch(1), 16))', 'g')

  # Handle Windows: convert forward slashes to backslashes only if it's a drive letter path
  if has('win32') || has('win64')
    if path =~? '^/[a-zA-Z]: '
      # Strip leading slash
      path = substitute(path, '^/', '', '')
    endif
    path = substitute(path, '/', '\\', 'g')
  endif

  return path
enddef

export def PathToURL(path: string): string
  # Normalize backslashes to forward slashes
  var tmp = substitute(path, '\\', '/', 'g')

  # If Windows-style path with drive letter, ensure proper format
  var url = ''
  if tmp =~? '^[a-zA-Z]: /'
    url = 'file:///' .. tmp
  else
    url = 'file://' .. tmp
  endif

  # Percent-encode unsafe characters
  url = substitute(url, '[^A-Za-z0-9._~!$&''()*+,;=:@/]', '\="%" .. printf("%02X", char2nr(submatch(0)))', 'g')
  return url
enddef

def InitScriptLocalVars()
  # Set script-local variables
  main_id = -1
  prompt_id = -1

  prompt_cursor = '▏'
  prompt_sign = '> '
  prompt_text = ''

  if exists('g:markdown_extras_config')
      && has_key(g:markdown_extras_config, 'fuzzy_search')
    fuzzy_search = g:markdown_extras_config['fuzzy_search']
  else
    fuzzy_search = true
  endif

  if exists('g:markdown_extras_config')
      && has_key(g:markdown_extras_config, 'large_files_threshold')
      && g:markdown_extras_config['large_files_threshold'] > 0
    large_files_threshold = g:markdown_extras_config['large_files_threshold']
  else
    large_files_threshold = 0
  endif

  if empty(prop_type_get('PopupToolsMatched'))
    prop_type_add('PopupToolsMatched', {highlight: 'WarningMsg'})
  endif

  popup_width = (&columns * 2) / 3
  links_popup_opts = {
      pos: 'center',
      border: [1, 1, 1, 1],
      borderchars:  ['─', '│', '─', '│', '├', '┤', '╯', '╰'],
      minwidth: popup_width,
      maxwidth: popup_width,
      scrollbar: 0,
      cursorline: 1,
      mapping: 0,
      wrap: 0,
      drag: 0,
    }
enddef

def GetFileSize(filename: string): number
  var filesize = ''
  # TODO: Using system() slow down significantly the opening and the file preview
  if filereadable(filename)
    if has('win32')
      filesize = system('powershell -NoProfile -ExecutionPolicy Bypass -Command '
        .. $'"(Get-Item \"{filename}\").length"')
    elseif has('unix') && system('uname') =~ 'Darwin'
      filesize = system($'stat -f %z {escape(filename, " ")}')
    elseif has('unix')
      filesize = system($'stat --format=%s {escape(filename, "  ")}')
    else
      utils.Echowarn($"Cannot determine the size of {filename}")
      filesize = "-2"
    endif
  else
    utils.Echoerr($"File {filename} is not readable")
    filesize = "-1"
  endif
  return filesize->substitute('\n', '', 'g')->str2nr()
enddef

export def RefreshLinksDict(): dict<string>
  # Generate the b:markdown_extras_links by parsing the 'references_comment'
  # Section.
  #
  # b:markdown_extras_links is a dict where the keys are numbers and the
  # values are valid URLs, e.g. https://, file://, ...
  #
  # Note that URLs starting with file:// are converted back and forth from URL
  # to local paths within the script.

  # Cleanup the current b:markdown_extras_links
  var links_dict = {}
  const references_line = search($'^{references_comment}', 'nw')
  if references_line != 0
    for l in range(references_line + 1, line('$'))
      var ref = getline(l)
      if !empty(ref)
        var key = ref->matchstr('\[\zs\d\+\ze\]')
        if !empty(key)
        var value = ref->matchstr('\[\d\+]:\s*\zs.*')
        if empty(value)
          value = trim(getline(l + 1))
        endif
        links_dict[key] = value
        # echom "key: " .. key
        # echom "value: " .. value
        endif
      endif
    endfor
  endif
  return links_dict
enddef

export def SearchLink(backwards: bool = false)
  const pattern = constants.LINK_OPEN_DICT['[']
  if !backwards
    search(pattern)
  else
    search(pattern, 'b')
  endif
enddef

def GetLinkID(): number
  # When user add a new link, it either create a new ID and return it or it
  # just return an existing ID if the link already exists

  b:markdown_extras_links = RefreshLinksDict()

  var current_wildmenu = &wildmenu
  set nowildmenu
  var link = input("Create new link (you can use 'tab'): ", '', 'file')
  if empty(link)
    &wildmenu = current_wildmenu
    return 0
  endif
  &wildmenu = current_wildmenu

  if !IsURL(link)
    link = PathToURL(fnamemodify(link, ':p'))
  endif
  var reference_line = search($'^{references_comment}', 'nw')
  if reference_line == 0
      append(line('$'), ['', references_comment])
  endif
  var link_line = search(link, 'nw')
  var link_id = 0
  if link_line == 0
    # Entirely new link
    link_id = keys(b:markdown_extras_links)->map('str2nr(v:val)')->max() + 1
    b:markdown_extras_links[$'{link_id}'] = link
    # If it is the first link ever, leave a blank line
    if link_id == 1
      append(line('$'), '')
    endif
    append(line('$'), $'[{link_id}]: {link}' )
  else
    # Reuse existing link
    var tmp = getline(link_line)->substitute('\v^\[(\d*)\].*', '\1', '')
    link_id = str2nr(tmp)
  endif
  return link_id
enddef

export def IsURL(link: string): bool
  for url_prefix in constants.URL_PREFIXES
    if link =~ $'^{url_prefix}'
      return true
    endif
  endfor
    return false
enddef

def LinksPopupCallback(type: string,
    popup_id: number,
    idx: number,
    match_id: number
  )
  if idx > 0
    const selection = getbufline(winbufnr(popup_id), idx)[0]
    var link_id = -1
    if selection == "Create new link"
      link_id = GetLinkID()
      if link_id == 0
        matchdelete(match_id)
        return
      endif
    else
      const keys_from_value =
        utils.KeysFromValue(b:markdown_extras_links, selection)
      # For some reason, b:markdown_extras_links may be empty or messed up
      if empty(keys_from_value)
        utils.Echoerr('Reference not found')
        matchdelete(match_id)
        return
      endif
      link_id = str2nr(keys_from_value[0])
    endif

    utils.SurroundSmart("markdownLinkText", type)

    # add link value
    search(']')
    execute $'norm! a[{link_id}]'
    if selection == "Create new link"
      norm! F]h
      if b:markdown_extras_links[link_id] =~ '^file://'
          && !filereadable(URLToPath(b:markdown_extras_links[link_id]))
        exe $'edit {b:markdown_extras_links[link_id]}'
        # write
      endif
    endif
  endif
  matchdelete(match_id)
enddef

export def IsLink(): dict<list<list<number>>>
  # If the word under cursor is a link, then it returns info about
  # it. Otherwise it won't return anything.
  const range_info = utils.IsInRange()
  if !empty(range_info) && keys(range_info)[0] == 'markdownLinkText'
    return range_info
  elseif synIDattr(synID(line("."), charcol("."), 1), "name") == 'markdownUrl'
    # Find beginning of the URL
    var a = [line('.'), 1]
    var b = searchpos(' ', 'nbW')
    var start_pos = [0, 0]
    if utils.IsLess(a, b) && b != [0, 0]
      start_pos = [b[0], b[1] + 1]
    else
      start_pos = a
    endif

    # Find end of the URL
    a = searchpos(' ', 'nW')
    b = [line('.'), charcol('$') - 1]
    var end_pos = [0, 0]
    if utils.IsLess(a, b) && a != [0, 0]
      end_pos = [a[0], a[1] - 1]
    else
      end_pos = b
    endif
    return {'markdownUrl': [start_pos, end_pos]}
  else
    return {}
  endif
enddef

def IsBinary(link: string): bool
  # Check if a file is binary
  var is_binary = false

  # Override if binary and not too large
  if filereadable(link)
    # Large file: open in a new Vim instance if
    const file_type = system($'file --brief -mime "{link}"')
    if executable('file') && file_type !~ '^ASCII text' && file_type !~ '^empty'
      is_binary = true
    # In case 'file' is not available, like in Windows, search for the NULL
    # byte. Guard if the file is too large
    elseif !empty(readfile(link)->filter('v:val =~# "\\%u0000"'))
        is_binary = true
    endif
  else
    utils.Echoerr($"File {link} is not readable")
  endif

  return is_binary
enddef

def GetRightWindowID(): number
  var cur_winid = win_getid()
  var cur_winpos = win_screenpos(win_id2win(cur_winid))
  var cur_top = cur_winpos[0]
  var cur_left = cur_winpos[1]

  var winids = getwininfo()
  for win in winids
    if win.winid != cur_winid
      var [top, left] = win_screenpos(win.winid)
      if top == cur_top && left > cur_left
        return win.winid
      endif
    endif
  endfor
  return -1 # No right window found
enddef

export def OpenLink(is_split: bool = false)
    InitScriptLocalVars()
    # Get link name depending of reference-style or inline link or just a
    # link, like for example when it is in the reference Section
    const saved_curpos = getcurpos()
    var link = ''

    if synIDattr(synID(line("."), charcol("."), 1), "name") != 'markdownUrl'
      # Start the search from the end of the text-link
      var symbol = ''
      norm! f]
      if searchpos('[', 'nW') == [0, 0]
        symbol = '('
      elseif searchpos('(', 'nW') == [0, 0]
        symbol = '['
      else
        symbol = utils.IsLess(searchpos('[', 'nW'), searchpos('(', 'nW'))
          ? '['
          : '('
      endif

      exe $"norm! f{symbol}l"

      if symbol == '['
        b:markdown_extras_links = RefreshLinksDict()
        const link_id = utils.GetTextObject('i[').text
        link = b:markdown_extras_links[link_id]
      else
        link = utils.GetTextObject('i(').text
      endif
    else
        const link_interval = values(IsLink())[0]
        const start = link_interval[0][1] - 1
        const length = link_interval[1][1] - link_interval[0][1] + 1
        link = strcharpart(getline('.'), start, length)
    endif

    # COMMON
    # Assume that a file is always small (=1 byte) is no large_file_support is
    # enabled
    const file_size = link =~ '^file://' && large_files_threshold > 0
      ? GetFileSize(URLToPath(link))
      : 0

    if link =~ '^file://'
        && (0 <= file_size && file_size <= large_files_threshold )
        && !IsBinary(URLToPath(link))
      if is_split
        if GetRightWindowID() == -1
          win_execute(win_getid(), 'vsplit')
        endif
        win_execute(GetRightWindowID(), $'edit {URLToPath(link)}')
      else
        exe $'edit {URLToPath(link)}'
      endif
    else
      exe $":Open {fnameescape(URLToPath(link))}"
    endif
    setcharpos('.', saved_curpos)
enddef

export def ConvertLinks()
  const references_line = search($'^{references_comment}', 'nw')
  if references_line == 0
      append(line('$'), ['', references_comment])
  endif

  b:markdown_extras_links = RefreshLinksDict()
  # TODO this pattern is a bit flaky
  const pattern = '\[*\]\s\?('
  const saved_view = winsaveview()
  cursor(1, 1)
  var lA = -1
  var cA = -1
  var curr_pos = [lA, -cA]
  while curr_pos != [0, 0]
    curr_pos = searchpos(pattern, 'W')
    lA = curr_pos[0]
    cA = curr_pos[1]
    if strcharpart(getline(lA), cA, 2) =~ '('
      norm! f(l
      var link = utils.GetTextObject('i(').text
      var link_id = keys(b:markdown_extras_links)
        ->map((_, val) => str2nr(val))->max() + 1
      # Fix current line
      exe $"norm! ca([{link_id}]"

      # Fix dict
      b:markdown_extras_links[link_id] = link
      var lastline = line('$')
      append(lastline, $'[{link_id}]: {link}')
      # TODO Find last proper line
      # var line = search('\s*#\+\s*References', 'n') + 2
      # var lastline = -1
      # while getline(line) =~ '^\s*\[*\]: ' && line <= line('$')
      #   echom line
      #   if line == line('$')
      #     lastline = line - 1
      #   elseif getline(line) !~ '^\[*\]: '
      #     lastline = line - 1
      #     break
      #   endif
      #   line += 1
      # endwhile
      # append(lastline, $'[{link_id}]: {link}')
    endif
  endwhile
    winrestview(saved_view)
enddef


export def RemoveLink(range_info: dict<list<list<number>>> = {})
  const link_info = empty(range_info) ? IsLink() : range_info
  # TODO: it may not be the best but it works so far
  echom "link_info: " .. string(keys(link_info))
  if !empty(link_info) && keys(link_info)[0] != 'markdownUrl'
      const saved_curpos = getcurpos()
      # Start the search from the end of the text-link
      norm! f]
      # Find the closest between [ and (
      var symbol = ''
      if searchpos('[', 'nW') == [0, 0]
        symbol = '('
      elseif searchpos('(', 'nW') == [0, 0]
        symbol = '['
      else
        symbol = utils.IsLess(searchpos('[', 'nW'), searchpos('(', 'nW'))
          ? '['
          : '('
      endif

      # Remove actual link
      search(symbol)
      exe $'norm! "_da{symbol}'

      # Remove text link - it is always between square brackets
      search(']', 'bc')
      norm! "_x
      search('[', 'bc')
      norm! "_x
      setcharpos('.', saved_curpos)
  endif
enddef

def ClosePopups()
  # This function tear down everything
  # popup_close(main_id, -1)
  # popup_close(prompt_id, -1)
  # TODO: this will clear any opened popup
  popup_clear()
  # RestoreCursor()
  prop_type_delete('PopupToolsMatched')
enddef

export def PopupFilter(id: number,
    key: string,
    slave_id: number,
    results: list<string>,
    match_id: number = -1,
    ): bool

  var maxheight = popup_getoptions(slave_id).maxheight

  if key == "\<esc>"
    if match_id != -1
      matchdelete(match_id)
    endif
    ClosePopups()
    return true
  endif

  echo ''
  # You never know what the user can type... Let's use a try-catch
  try
    if key == "\<CR>"
      popup_close(slave_id, getcurpos(slave_id)[1])
      ClosePopups()
    elseif index(["\<Right>", "\<PageDown>"], key) != -1
      win_execute(slave_id, 'normal! ' .. maxheight .. "\<C-d>")
    elseif index(["\<Left>", "\<PageUp>"], key) != -1
      win_execute(slave_id, 'normal! ' .. maxheight .. "\<C-u>")
    elseif key == "\<Home>"
      win_execute(slave_id, "normal! gg")
    elseif key == "\<End>"
      win_execute(slave_id, "normal! G")
    elseif index(["\<tab>", "\<C-n>", "\<Down>", "\<ScrollWheelDown>"], key)
        != -1
      var ln = getcurpos(slave_id)[1]
      win_execute(slave_id, "normal! j")
      if ln == getcurpos(slave_id)[1]
        win_execute(slave_id, "normal! gg")
      endif
    elseif index(["\<S-Tab>", "\<C-p>", "\<Up>", "\<ScrollWheelUp>"], key) !=
        -1
      var ln = getcurpos(slave_id)[1]
      win_execute(slave_id, "normal! k")
      if ln == getcurpos(slave_id)[1]
        win_execute(slave_id, "normal! G")
      endif
    # The real deal: take a single, printable character
    elseif key =~ '^\p$' || keytrans(key) ==# "<BS>" || key == "\<c-u>"
      if key =~ '^\p$'
        prompt_text ..= key
      elseif keytrans(key) ==# "<BS>"
        if strchars(prompt_text) > 0
          prompt_text = prompt_text[: -2]
        endif
      elseif key == "\<c-u>"
        prompt_text = ""
      endif

      popup_settext(id, $'{prompt_sign}{prompt_text}{prompt_cursor}')

      # What you pass to popup_settext(slave_id, ...) is a list of strings with
      # text properties attached, e.g.
      #
      # [
      #   { "text": "filename.txt",
      #     "props": [ {"col": 2, "length": 1, "type": "PopupToolsMatched"},
      #     ... ]
      #   },
      #   { "text": "another_file.txt",
      #     "props": [ {"col": 1, "length": 1, "type": "PopupToolsMatched"},
      #     ... ]
      #   },
      #   ...
      # ]
      #
      var filtered_results_full = []
      var filtered_results: list<dict<any>>

      if !empty(prompt_text)
        if fuzzy_search
          filtered_results_full = results->matchfuzzypos(prompt_text)
          var pos = filtered_results_full[1]
          filtered_results = filtered_results_full[0]
            ->map((ii, match) => ({
              text: match,
              props: pos[ii]->copy()->map((_, col) => ({
                col: col + 1,
                length: 1,
                type: 'PopupToolsMatched'
              }))}))
        else
          filtered_results_full = copy(results)
            ->map((_, text) => matchstrpos(text,
                  \ '\V' .. $"{escape(prompt_text, '\')}"))
            ->map((idx, match_info) => [results[idx], match_info[1],
              match_info[2]])

          filtered_results = copy(filtered_results_full)
            ->map((_, val) => ({
              text: val[0],
              props: val[1] >= 0 && val[2] >= 0
                ? [{
                  type: 'PopupToolsMatched',
                  col: val[1] + 1,
                  end_col: val[2] + 1
                }]
                : []
            }))
            ->filter("!empty(v:val.props)")
        endif
      endif

      var opts = popup_getoptions(id)
      var num_hits = !empty(filtered_results)
        ? len(filtered_results)
        : len(results)
      popup_setoptions(id, opts)

      if !empty(prompt_text)
        popup_settext(slave_id, filtered_results)
      else
        popup_settext(slave_id, results)
      endif
    else
      utils.Echowarn('Unknown key')
    endif
  catch
    ClosePopups()
    utils.Echoerr('Internal error')
  endtry

  return true
enddef

export def ShowPromptPopup(slave_id: number,
    links: list<string>,
    title: string,
    match_id: number = -1
  )
  # This could be called by other scripts and its id may be undefined.
  InitScriptLocalVars()
  # This is the UI thing
  var slave_id_core_line = popup_getpos(slave_id).core_line
  var slave_id_core_col = popup_getpos(slave_id).core_col
  var slave_id_core_width = popup_getpos(slave_id).core_width

  # var base_title = $'{search_type}:'
  var opts = {
    title: title,
    minwidth: slave_id_core_width,
    maxwidth: slave_id_core_width,
    line: slave_id_core_line - 3,
    col: slave_id_core_col - 1,
    borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    border: [1, 1, 0, 1],
    mapping: 0,
    scrollbar: 0,
    wrap: 0,
    drag: 0,
  }

  # Filter
  opts.filter = (id, key) => PopupFilter(id, key, slave_id, links, match_id)

  prompt_text = ""
  prompt_id = popup_create([prompt_sign .. prompt_cursor], opts)
enddef

export def CreateLink(type: string = '')
  if !empty(synIDattr(synID(line("."), charcol("."), 1), "name"))
    return
  endif

  InitScriptLocalVars()
  const references_line = search($'^{references_comment}', 'nw')
  if references_line == 0
      append(line('$'), ['', references_comment])
  endif

  if getcharpos("'[") == getcharpos("']")
    return
  endif

  b:markdown_extras_links = RefreshLinksDict()

  # line and column of point A
  var lA = line("'[")
  var cA = type == 'line' ? 1 : col("'[")

  # line and column of point B
  var lB = line("']")
  var cB = type == 'line' ? strchars(getline(lB)) : col("']")

  if getregion(getcharpos("'["), getcharpos("']"))[0] =~ '^\s*$'
    return
  endif

  # The regex reads:
  # Take all characters, including newlines, from (l0,c0) to (l1,c1 + 1)'
  const match_pattern = $'\%{lA}l\%{cA}c\_.*\%{lB}l\%{cB + 1}c'
  const match_id = matchadd('Changed', match_pattern)
  redraw

  links_popup_opts.callback =
    (popup_id, idx) => LinksPopupCallback(type, popup_id, idx, match_id)

  var links = values(b:markdown_extras_links)->insert("Create new link")
  var popup_height = min([len(links), (&lines * 2) / 3])
  links_popup_opts.minheight = popup_height
  links_popup_opts.maxheight = popup_height
  main_id = popup_create(links, links_popup_opts)

  # if len(links) > 1
    ShowPromptPopup(main_id, links, " links: ", match_id)
  # endif
enddef

# -------- Preview functions --------------------------------
def PreviewWinFilterKey(previewWin: number, key: string): bool
  var keyHandled = false

  if key == "\<C-E>"
      || key == "\<C-D>"
      || key == "\<C-F>"
      || key == "\<PageDown>"
      || key == "\<C-Y>"
      || key == "\<C-U>"
      || key == "\<C-B>"
      || key == "\<PageUp>"
      || key == "\<C-Home>"
      || key == "\<C-End>"
    # scroll the hover popup window
    win_execute(previewWin, $'normal! {key}')
    keyHandled = true
  endif

  if key == "\<Esc>"
    previewWin->popup_close()
    keyHandled = true
  endif

  return keyHandled
enddef

def GetFileContent(filename: string): list<string>
    var file_content = []
    if bufexists(filename)
      file_content = getbufline(filename, 1, '$')
    elseif filereadable($'{filename}')
      file_content = readfile($'{filename}')
    else
      file_content = ["Can't preview the file!", "Does the file exist?"]
    endif
    var title = [filename, '']
    return extend(title, file_content)
enddef

export def PreviewPopup()
  InitScriptLocalVars()
  b:markdown_extras_links = RefreshLinksDict()

  var previewText = []
  var link_name = ''
  const saved_curpos = getcurpos()
  const link_info = IsLink()
  # CASE 1: on an alias
  if !empty(link_info) && keys(link_info)[0] != 'markdownUrl'
    # Search from the current cursor position to the end of line
    # Start the search from the end of the text-link
    norm! f]
    # Find the closest between [ and (
    var symbol = ''
    if searchpos('[', 'nW') == [0, 0]
      symbol = '('
    elseif searchpos('(', 'nW') == [0, 0]
      symbol = '['
    else
      symbol = utils.IsLess(searchpos('[', 'nW'), searchpos('(', 'nW'))
        ? '['
        : '('
    endif

    exe $"norm! f{symbol}l"

    var link_id = ''
    if symbol == '['
      b:markdown_extras_links = RefreshLinksDict()
      link_id = utils.GetTextObject('i[').text
      link_name = b:markdown_extras_links[link_id]
    else
      link_name = utils.GetTextObject('i(').text
    endif
  # CASE 2: on an actual link, like those in the reference Section
  elseif keys(link_info)[0] == 'markdownUrl'
    const link_interval = values(link_info)[0]
    const start = link_interval[0][1] - 1
    const length = link_interval[1][1] - link_interval[0][1] + 1
    link_name = strcharpart(getline('.'), start, length)
  endif

  if !empty(link_name)
    # TODO At the moment only .md files have syntax highlight.
    var refFiletype = $'{fnamemodify(link_name, ":e")}' == 'md'
      ? 'markdown'
      : 'text'
    const file_size = !IsURL(link_name) && large_files_threshold > 0
          ? GetFileSize(link_name)
          : 0
    if link_name !~ '^file://'
        || (filereadable(link_name) && file_size > large_files_threshold)
      previewText = [link_name]
      refFiletype = 'text'
    else
      previewText = GetFileContent(URLToPath(link_name))
    endif

    popup_clear()
    var winid = previewText->popup_atcursor({moved: 'any',
             close: 'click',
             fixed: true,
             maxwidth: 80,
             maxheight: (&lines * 2) / 3,
             border: [0, 1, 0, 1],
             borderchars: [' '],
             filter: PreviewWinFilterKey})

    # TODO: Set syntax highlight
    # if !IsURL(link_name)
    #   var old_synmaxcol = &synmaxcol
    #   &synmaxcol = 300
    #   var buf_extension = $'{fnamemodify(link_name, ":e")}'
    #   var found_filetypedetect_cmd =
    #     autocmd_get({group: 'filetypedetect'})
    #     ->filter($'v:val.pattern =~ "*\\.{buf_extension}$"')
    #   echom found_filetypedetect_cmd
    #   var set_filetype_cmd = ''
    #   if empty(found_filetypedetect_cmd)
    #     if index([$"{$HOME}/.vimrc", $"{$HOME}/.gvimrc"], expand(link_name)) != -1
    #      set_filetype_cmd = '&filetype = "vim"'
    #     else
    #      set_filetype_cmd = '&filetype = ""'
    #     endif
    #   else
    #     set_filetype_cmd = found_filetypedetect_cmd[0].cmd
    #   endif
    #   win_execute(winid, set_filetype_cmd)
    #   &synmaxcol = old_synmaxcol
    # endif

    win_execute(winid, $"setlocal ft={refFiletype}")
    setcharpos('.', saved_curpos)
  endif
enddef
