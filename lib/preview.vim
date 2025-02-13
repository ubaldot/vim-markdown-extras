vim9script

import autoload "./links.vim"
import autoload './utils.vim'

export def ShowLinkPreview()
  # Generate links_dict
  links.GenerateLinksDict()

  var current_word = expand('<cword>')
  if links.IsLink()
    # TODO relying on the fact that there shall not be spaces in markdown
    # links
    # var link_id = utils.GetTextObject('f ')->matchstr('\w\+\]\[\zs\d\+\ze\]')
    var curr_col = col('.')
    var link_id = getline('.')->matchstr($'\%>{curr_col}c\w\+\]\s*\[\s*\zs\d\+\ze\]')
    if !links.IsURL(links.links_dict[link_id])
      echo "I will preview the file here."
    else
      echo links.links_dict[link_id]
    endif
  endif
enddef

# Key filter function for the hover popup window.
# Only keys to scroll the popup window are supported.
def HoverWinFilterKey(hoverWin: number, key: string): bool
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
    win_execute(hoverWin, $'normal! {key}')
    keyHandled = true
  endif

  if key == "\<Esc>"
    hoverWin->popup_close()
    keyHandled = true
  endif

  return keyHandled
enddef
