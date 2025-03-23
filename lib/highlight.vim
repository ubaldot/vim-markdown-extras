vim9script

# At the moment it only works in Visual
# TODO: use opfunc to make it more general
# TODO: use search mechanism
# Use <BS> to delete a property given its ID. You need a function that detect
# the property ID of the text under cursor.
var prop_id = 0
var prop_name = 'markdown_extras_highlight'
var hi_group = 'IncSearch'

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'hi_group')
      && g:markdown_extras_config['']
  hi_group = g:markdown_extras_config['hi_group']
endif

if empty(prop_type_get(prop_name))
  prop_type_add(prop_name, {highlight: hi_group})
endif

export def AddProp()
  var lA = getpos("'<")[1]
  var cA = getpos("'<")[2]
  var lB = getpos("'>")[1]
  var cB = getpos("'>")[2]

  prop_add(lA, cA, {id: prop_id, type: 'markdown_extras_highlight',
    end_lnum: lB, end_col: cB + 1})
  prop_id += 1
enddef

export def IsOnProp(): dict<any>
  var prop = prop_find({type: prop_name, 'col': col('.')}, 'b')
  if has_key(prop, 'id')
    if col('.') > prop.col + prop.length
      prop = {}
    endif
  endif
  return prop
enddef

export def ClearProp()
  var lA = getpos("'<")[1]
  var lB = getpos("'>")[1]

  prop_clear(lA, lB)
enddef
