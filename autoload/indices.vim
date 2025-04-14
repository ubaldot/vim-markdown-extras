vim9script

import autoload "./links.vim"
import autoload "./utils.vim"

var indices_id = -1

def IndicesCallback(id: number, idx: number)
  if idx > 0
    var selection = getbufline(winbufnr(id), idx)[0]
    exe $'edit {selection}'
    indices_id = -1
  endif
enddef

export def ShowIndices()
  if exists('g:markdown_extras_indices') != 0 && !empty('g:markdown_extras_indices')
    const popup_width = (&columns * 2) / 3
    const popup_height = min([len(g:markdown_extras_indices), &lines / 2])
    var opts = {
        pos: 'center',
        border: [1, 1, 1, 1],
        borderchars:  ['─', '│', '─', '│', '├', '┤', '╯', '╰'],
        minwidth: popup_width,
        maxwidth: popup_width,
        minheight: popup_height,
        maxheight: popup_height,
        scrollbar: 0,
        cursorline: 1,
        callback: IndicesCallback,
        mapping: 0,
        wrap: 0,
        drag: 0,
      }
    indices_id = popup_create(g:markdown_extras_indices, opts)
    links.ShowPromptPopup(indices_id, g:markdown_extras_indices, " indices: ")
  else
    utils.Echoerr("'g:markdown_extras_indices' not set" )
  endif
enddef
