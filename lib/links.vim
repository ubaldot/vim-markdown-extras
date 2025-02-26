vim9script

import autoload './utils.vim'
import autoload '../after/ftplugin/markdown.vim'

export var links_dict = {}

export def IsLink(): bool
  # Check if the word under the cursor is a link
  #
  # Compare foo with [foo]. If they match, then what is inside the [] it
  # possibly be a link. Next, it check if there is a (bla_bla) just after ].
  # Link alias must be words.
  # Assume that a link (or a filename) cannot be broken into multiple lines
  var saved_curpos = getcurpos()
  var is_link = false
  var alias_link = utils.GetTextObject('i]').text

  # Handle singularity if the cursor is on '[' or ']'
  if alias_link == '['
    norm! l
    alias_link = utils.GetTextObject('i]').text
  elseif alias_link == ']'
    norm! h
    alias_link = utils.GetTextObject('i]').text
  endif

  # Check if foo and [foo] match and if there is a [bla bla] after ].
  var alias_link_bracket = utils.GetTextObject('a[').text
  if alias_link == alias_link_bracket[1 : -2]
    norm! f]
    if getline('.')[col('.')] == '('
        || getline('.')[col('.')] == '['
      var line_open_parenthesis = line('.')
      norm! l%
      var line_close_parenthesis = line('.')
      if line_open_parenthesis == line_close_parenthesis
        # echo "Is a link"
        is_link = true
      else
        # echo "Is not a link"
        is_link = false
      endif
    else
      # echo "Is not a link"
      is_link = false
    endif
  else
    # echo "Is not a link"
    is_link = false
  endif
  setpos('.', saved_curpos)
  return is_link
enddef

def g:IsLinkNew()
  var range = utils.IsInRange(
    markdown.link_open_dict,
    markdown.link_close_dict
  )
  echom range
enddef

def OpenLink()
    norm! f[l
    # Only work for [blabla][]
    var link_id = utils.GetTextObject('i[').text
    var link = links_dict[link_id]
    if filereadable(link)
      norm! gf
    elseif IsURL(link)
      norm! gx
    else
      utils.Echoerr($"File {link} does not exists!")
    endif
enddef

export def GetLinkID(): number
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
      append(line('$'), ['', '## References', ''])
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
  var url_prefixes = [ 'https://', 'http://', 'ftp://', 'ftps://',
    'sftp://', 'telnet://', 'file://']
  for url_prefix in url_prefixes
    if link =~ $'^{url_prefix}'
      return true
    endif
  endfor
    return false
enddef

export def GenerateLinksDict()
  # Generate the links_dict but it requires that there is a
  # Reference section at the end
  var ref_start_line = search('\s*#\+\s\+References', 'nw')
  # TODO: error message if not found!
  var refs = getline(ref_start_line + 1, '$')
    ->filter('v:val =~ "^\\[\\d\\+\\]:\\s"')
  for item in refs
     var key = item->substitute('\[\(\d\+\)\].*', '\1', '')
     var value = item->substitute('^\[\d\+]\:\s*\(.*\)', '\1', '')
     links_dict[key] = value
  endfor
enddef

export def RemoveLink()
  # Initialization
  if empty(links_dict)
    GenerateLinksDict()
  endif
  # TODO: it may not be the best but it works so far
  if IsLink()
      search('[')
      norm! "_da[
      search(']', 'bc')
      norm! "_x
      search('[', 'bc')
      norm! "_x
  endif
enddef

def CreateLink(textobject: string = '')

  var link_id = GetLinkID()
  if link_id == 0
    return
  endif

  utils.SurroundSmart("[",
    "]",
    markdown.link_open_dict,
    markdown.link_close_dict,
    textobject)
  # add link value
  execute $'norm! a[{link_id}]'
  norm! F]h
  if !IsURL(links_dict[link_id]) && !filereadable(links_dict[link_id])
    exe $'edit {links_dict[link_id]}'
    # write
  endif
enddef


# TODO
def CleanupReferences()
  echoerr Not Implemented!
enddef

export def HandleLink()
  # Initialization
  if empty(links_dict)
    GenerateLinksDict()
  endif
  if IsLink()
    OpenLink()
  else
    CreateLink()
  endif
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
  if links.IsLink()
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
