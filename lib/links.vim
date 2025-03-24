vim9script

import autoload './constants.vim'
import autoload './utils.vim'
import autoload '../after/ftplugin/markdown.vim'

export var links_dict = {}

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
  #
  var link = input('Insert link: ', '', 'customlist,Foo')
  if empty(link)
    return 0
  endif

  # TODO: use full-path?
  if !IsURL(link)
    link = fnamemodify(link, ':p')
  endif
  var reference_line = search('\s*#\+\s\+References', 'nw')
  if reference_line == 0
      append(line('$'), ['', '## References'])
  endif
  var link_line = search(link, 'nw')
  var link_id = 0
  if link_line == 0
    # Entirely new link
    link_id = keys(links_dict)->map('str2nr(v:val)')->max() + 1
    links_dict[$'{link_id}'] = link
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

def LinksPopupCallback(match_id: number, type: string,  popup_id: number, idx: number)
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
      const keys_from_value = utils.KeysFromValue(links_dict, selection)
      # For some reason, links_dict may be empty or messed up
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
      if !IsURL(links_dict[link_id]) && !filereadable(links_dict[link_id])
        exe $'edit {links_dict[link_id]}'
        # write
      endif
    endif
  endif
  matchdelete(match_id)
enddef

def LinksPopupFilter(popup_id: number, key: string): bool
  # TODO: add try-catch
  if key == "\<esc>"
    popup_close(popup_id, -1)
  elseif key == "\<cr>"
    popup_close(popup_id, getcurpos(popup_id)[1])
  elseif index(["j", "\<tab>", "\<C-n>", "\<Down>", "\<ScrollWheelDown>"], key) != -1
    var ln = getcurpos(popup_id)[1]
    win_execute(popup_id, "normal! j")
    if ln == getcurpos(popup_id)[1]
      win_execute(popup_id, "normal! gg")
    endif
  elseif index(["k", "\<S-Tab>", "\<C-p>", "\<Up>", "\<ScrollWheelUp>"], key) != -1
    var ln = getcurpos(popup_id)[1]
    win_execute(popup_id, "normal! k")
    if ln == getcurpos(popup_id)[1]
      win_execute(popup_id, "normal! G")
    endif
  endif
  return true
enddef

const popup_width = (&columns * 2) / 3
const popup_height = (&lines * 2) / 3
var links_popup_opts = {
    title: ' links: ',
    pos: 'center',
    border: [1, 1, 1, 1],
    borderchars:  ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    maxheight: popup_height,
    minwidth: popup_width,
    maxwidth: popup_width,
    scrollbar: 0,
    cursorline: 1,
    mapping: 0,
    wrap: 0,
    drag: 0,
    filter: LinksPopupFilter,
    callback: LinksPopupCallback,
  }

export def IsLink(): dict<list<list<number>>>
  const range_info = utils.IsInRange()
  if !empty(range_info) && keys(range_info)[0] == 'markdownLinkText'
    return range_info
  else
    return {}
  endif
enddef

export def OpenLink()
    norm! f[l
    # Only work for [blabla][]
    # var link_id = xxx->matchstr('\[*\]\s*\[\zs\d\+\ze')
    const link_id = utils.GetTextObject('i[').text
    const link = links_dict[link_id]
    if exists(':Open') != 0
      exe $":Open {link}"
    else
      utils.Echowarn('You need a Vim version that has the :Open command')
    endif
enddef

export def GenerateLinksDict()
  # Generate the links_dict by parsing the # References section,
  # but it requires that there is a # Reference section at the end
  #
  # Cleanup the current links_dict
  links_dict = {}
  const references_line = search('\s*#\+\s\+References', 'nw')
  if references_line == 0
      append(line('$'), ['', '## References'])
  endif
  var refs = getline(references_line + 1, '$')
    ->filter('v:val =~ "^\\[\\d\\+\\]:\\s"')
  for item in refs
     var key = item->substitute('\[\(\d\+\)\].*', '\1', '')
     var value = item->substitute('^\[\d\+]\:\s*\(.*\)', '\1', '')
     links_dict[key] = value
  endfor
enddef

export def RemoveLink(range_info: dict<list<list<number>>> = {})
  const link_info = empty(range_info) ? IsLink() : range_info
  # TODO: it may not be the best but it works so far
  if !empty(link_info)
      search('[')
      norm! "_da[
      search(']', 'bc')
      norm! "_x
      search('[', 'bc')
      norm! "_x
  endif
enddef

export def CreateLink(type: string = '')

  if getcharpos("'[") == getcharpos("']")
    return
  endif

  GenerateLinksDict()
  # line and column of point A
  var lA = line("'[")
  var cA = type == 'line' ? 1 : col("'[")

  # line and column of point B
  var lB = line("']")
  var cB = type == 'line' ? len(getline(lB)) : col("']")

  # The regex reads:
  # Take all characters, including newlines, from (l0,c0) to (l1,c1 + 1)'
  const match_pattern = $'\%{lA}l\%{cA}c\_.*\%{lB}l\%{cB + 1}c'
  const match_id = matchadd('Changed', match_pattern)
  redraw

  links_popup_opts.callback =
    (popup_id, idx) => LinksPopupCallback(match_id, type, popup_id, idx)
  popup_create(values(links_dict)->insert("Create new link"), links_popup_opts)
enddef


# TODO
def CleanupReferences()
  echoerr Not Implemented!
enddef

# --------------------- Popups --------------------------------------------

def OpenLinkPopup(links_list: list<string>, popup_id: number, choice: number)
    var link = links_list[choice - 1]
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

# TODO: we need a mapping for this
export def g:ReferencesPopup()
  GenerateLinksDict()
  # Build a list such that each item correspond to a link.
  # This to establish an order and a mapping between menu choice->list
  # element
  var items = values(links_dict)
  var links_list = []
  for val in items
    links_list->add(val)
  endfor
  if !empty(items)
    var choice = links_list->popup_menu({
      title: ' References ',
      borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
      callback: (popup_id, choice) => OpenLinkPopup(links_list, popup_id, choice) })
  else
    utils.Echowarn('No references found!')
  endif
enddef

# TODO: make a function for consolidating the references
# (SanitizeReferences())


# TODO JUST ADDED!
export def AddLinkPopup()
  # Generate links_dict
  GenerateLinksDict()

  var previewText = []
  var refFiletype = 'txt'
  # TODO: only word are allowed as link aliases
  var current_word = expand('<cword>')
  if !empty(IsLink())
    # Search from the current cursor position to the end of line
    var curr_col = col('.')
    var link_id = getline('.')
      ->matchstr($'\%>{curr_col}c\w\+\]\s*\[\s*\zs\d\+\ze\]')
    var link_name = links.links_dict[link_id]
    if links.IsURL(link_name)
      previewText = [link_name]
      refFiletype = 'txt'
    else
      previewText = GetFileContent(link_name)
      refFiletype = 'txt'
    endif
  endif

  popup_clear()
  var winid = previewText->popup_atcursor({moved: 'any',
           close: 'click',
           fixed: true,
           maxwidth: 80,
           border: [0, 1, 0, 1],
           borderchars: [' '],
           filter: PreviewWinFilterKey})
  win_execute(winid, $'setlocal ft={refFiletype}')
enddef

def g:Foo(A: any, L: any, P: any): list<string>
  return values(links_dict)
enddef

# var x = input('foo: ', '', 'customlist,Foo')


# def CustomComplete(findstart: number, base: string): any
#     if findstart
#         return match(getline('.'), '\S\+$')  # Find the start of the word
#     else
#         var candidates = ['apple', 'applecaca', 'banana', 'blueberry', 'blackberry', 'grape', 'grapefruit']
#         var filtered = copy(candidates)->filter((_, val) => val =~# printf('^%s', base))
#         return map(filtered, Bar)
#     endif
# enddef

# def Bar(idx: number, val: any): any
#   return {word: val, menu: '[Custom]'}
# enddef

# setlocal completefunc=CustomComplete
# inoremap X <C-X><C-U>
