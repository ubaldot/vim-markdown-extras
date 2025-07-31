vim9script

import autoload "./mde_links.vim" as links
import autoload "./mde_utils.vim" as utils

var index: any
var index_id = -1

def IndexCallback(id: number, idx: number)
  if idx > 0

    var selection = ''
    if typename(index) == "list<string>"
      selection = getbufline(winbufnr(id), idx)[0]
    elseif typename(index) == "list<list<string>>"
      selection = getbufline(winbufnr(id), idx)[0]
      var index_names = index->mapnew((_, val) => val[0])
      var ii = index(index_names, selection)
      selection = index[ii][1]
    elseif typename(index) == "dict<string>"
      var selection_key = getbufline(winbufnr(id), idx)[0]
      selection = index[selection_key]
    endif

    if !empty(selection)
      if links.IsURL(selection) && selection =~ '^file://'
        exe $'edit {fnameescape(links.URLToPath(selection))}'
      elseif links.IsURL(selection)
        exe $'Open {selection}'
      elseif filereadable(fnameescape(selection))
        exe $'edit {fnameescape(selection)}'
      elseif selection =~ "^function("
        try
          var Tmp = eval(selection)
          Tmp()
        catch
          utils.Echoerr("Function must be global "
                \ .. "OR the function has some error(s)")
        endtry
      endif
    endif

    index_id = -1
  endif
enddef

export def ShowIndex(passed_index: string='')
  var index_found = false

  if !empty(passed_index)
    # TODO: remove the eval() with something better
    index = eval(passed_index)
    index_found = true
  elseif exists('g:markdown_extras_index') != 0
      && !empty('g:markdown_extras_index')
    index = g:markdown_extras_index
    index_found = true
  else
    utils.Echoerr("Cannot find index" )
  endif

  if index_found
    const popup_width = (&columns * 2) / 3
    const popup_height = min([len(index), &lines / 2])
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
        callback: IndexCallback,
        mapping: 0,
        wrap: 0,
        drag: 0,
      }
    if typename(index) == "list<string>"
      index_id = popup_create(index, opts)
      links.ShowPromptPopup(index_id, index, " index: ")
    elseif typename(index) == "list<list<string>>"
      var index_names = index->mapnew((_, val) => val[0])
      index_id = popup_create(index_names, opts)
      links.ShowPromptPopup(index_id, index_names, " index: ")
    elseif typename(index) == "dict<string>"
      index_id = popup_create(keys(index), opts)
      links.ShowPromptPopup(index_id, keys(index), " index: ")
    else
      utils.Echoerr("Wrong argument type passed to ':MDEIndex' "
            \ .. $" (you passed a {typename(index)})")
    endif
  endif
enddef
