vim9script

import autoload "./mde_links.vim" as links
import autoload "./mde_utils.vim" as utils

var indices_id = -1

def IndicesCallback(id: number, idx: number)
  if idx > 0

    if typename(g:markdown_extras_indices) == "list<string>"
      var selection = getbufline(winbufnr(id), idx)[0]
      exe $'edit {selection}'
    elseif typename(g:markdown_extras_indices) == "dict<string>"
      var selection = getbufline(winbufnr(id), idx)[0]
      exe $'edit {g:markdown_extras_indices[selection]}'
    endif
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
    if typename(g:markdown_extras_indices) == "list<string>"
      indices_id = popup_create(g:markdown_extras_indices, opts)
      links.ShowPromptPopup(indices_id, g:markdown_extras_indices, " indices: ")
    elseif typename(g:markdown_extras_indices) == "dict<string>"
      indices_id = popup_create(keys(g:markdown_extras_indices), opts)
      links.ShowPromptPopup(indices_id, keys(g:markdown_extras_indices), " indices: ")
    endif
  else
    utils.Echoerr("'g:markdown_extras_indices' not set" )
  endif
enddef
