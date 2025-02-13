vim9script

import autoload './utils.vim'

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
  var alias_link = utils.GetTextObject('iw')

  # Handle singularity if the cursor is on '[' or ']'
  if alias_link == '['
    norm! l
    alias_link = utils.GetTextObject('iw')
  elseif alias_link == ']'
    norm! h
    alias_link = utils.GetTextObject('iw')
  endif

  # Check if foo and [foo] match and if there is a [bla bla] after ].
  var alias_link_bracket = utils.GetTextObject('a[')
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

def OpenLink()
    norm! f[l
    var link_id = utils.GetTextObject('i[')
    var link = links_dict[link_id]
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


export def GetLinkID(): number
  var link = input('Insert link: ', '', 'file')
  if empty(link)
    return 0
  endif

  # TODO: use full-path?
  if !IsURL(link)
    link = fnamemodify(link, ':p')
  endif
  var link_line = search(link, 'nw')
  var link_id = 0
  if link_line == 0
    # Entirely new link
    link_id = keys(links_dict)->map('str2nr(v:val)')->max() + 1
    links_dict[$'{link_id}'] = link
    # If it is the first link ever, leave a blank line
    if link_id == 1 && search('\s*#\+\s\+References', 'nw') != 0
      append(line('$'), '' )
    elseif link_id == 1 && search('\s*#\+\s\+References', 'nw') == 0
      append(line('$'), ['', '## References', ''])
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
  var ref_start_line = search('\s*#\+\s\+References', 'nw')
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
    var link_id = GetLinkID()
    if link_id == 0
      return
    endif
    # Surround stuff
    norm! lbi[
    norm! ea]
    execute $'norm! a[{link_id}]'
    norm! F]h
    if !IsURL(links_dict[link_id]) && !filereadable(links_dict[link_id])
      exe $'edit {links_dict[link_id]}'
      # write
    endif
  endif
enddef
