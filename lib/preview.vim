vim9script

import autoload "./links.vim"
import autoload './utils.vim'

export def ShowLinkPreview()
  # Generate links_dict
  links.GenerateLinksDict()

  var current_word = expand('<cword>')
  if links.IsLink()
    # Match from the cursor position to the end of line
    var curr_col = col('.')
    var link_id = getline('.')
         ->matchstr($'\%>{curr_col}c\w\+\]\s*\[\s*\zs\d\+\ze\]')
    if !links.IsURL(links.links_dict[link_id])
      PreviewPopup()
      # echo "I will preview the file here."
    else
      echo links.links_dict[link_id]
    endif
  endif
enddef

# Key filter function for the hover popup window.
# Only keys to scroll the popup window are supported.
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
    # TODO: check if you can remove the expand()
    elseif filereadable($'{filename}')
      # file_content = readfile($'{expand(filename)}')
      file_content = readfile($'{filename}')
    else
      file_content = ["Can't preview the file!", "Does file exist?"]
    endif
    var title = [filename, '------------------------']
    return extend(title, file_content)
enddef

export def PreviewPopup()
  # Generate links_dict
  links.GenerateLinksDict()

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
