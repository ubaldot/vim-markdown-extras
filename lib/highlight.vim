vim9script

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

export def AddProp(type: string = '')
  if getcharpos("'[") == getcharpos("']")
    return
  endif

  # line and column of point A
  var lA = line("'[")
  var cA = type == 'line' ? 1 : col("'[")

  # line and column of point B
  var lB = line("']")
  var cB = type == 'line' ? len(getline(lB)) : col("']")

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
