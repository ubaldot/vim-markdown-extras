vim9script

import autoload "./mde_links.vim" as links
import autoload "./mde_utils.vim" as utils

var indices: any
var indices_id = -1

def IndicesCallback(id: number, idx: number)
  if idx > 0

    var selection = ''
    if typename(indices) == "list<string>"
      selection = getbufline(winbufnr(id), idx)[0]
    elseif typename(indices) == "list<list<string>>"
      selection = getbufline(winbufnr(id), idx)[0]
      var indices_names = indices->mapnew((_, val) => val[0])
      var ii = index(indices_names, selection)
      selection = indices[ii][1]
    elseif typename(indices) == "dict<string>"
      var selection_key = getbufline(winbufnr(id), idx)[0]
      selection = indices[selection_key]
    endif

    # echom "sel: " .. selection
    # echom "typesel: " .. typename(eval(selection))

    if !empty(selection)
      # if typename(eval(selection)) =~ "^func("
      #   echom "IsFunc"
        # var Tmp = eval(selection)
        # Tmp()
      if links.IsURL(selection) && selection =~ '^file://'
        exe $'edit {fnameescape(links.URLToPath(selection))}'
      elseif links.IsURL(selection)
        exe $'Open {selection}'
      else
        exe $'edit {fnameescape(selection)}'
      endif
    endif

    indices_id = -1
  endif
enddef

export def ShowIndices(passed_indices: string='')
  var indices_found = false

  if !empty(passed_indices)
    # TODO: remove the eval() with something better
    indices = eval(passed_indices)
    indices_found = true
  elseif exists('g:markdown_extras_indices') != 0
      && !empty('g:markdown_extras_indices')
    indices = g:markdown_extras_indices
    indices_found = true
  else
    utils.Echoerr("Cannot find indices" )
  endif

  if indices_found
    const popup_width = (&columns * 2) / 3
    const popup_height = min([len(indices), &lines / 2])
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
    if typename(indices) == "list<string>"
      indices_id = popup_create(indices, opts)
      links.ShowPromptPopup(indices_id, indices, " indices: ")
    elseif typename(indices) == "list<list<string>>"
      var indices_names = indices->mapnew((_, val) => val[0])
      indices_id = popup_create(indices_names, opts)
      links.ShowPromptPopup(indices_id, indices_names, " indices: ")
    elseif typename(indices) == "dict<string>"
      indices_id = popup_create(keys(indices), opts)
      links.ShowPromptPopup(indices_id, keys(indices), " indices: ")
    else
      utils.Echoerr($"Wrong argument type to ':MDEIndex' ({typename(indices)})")
    endif
  endif
enddef
