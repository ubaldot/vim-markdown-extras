vim9script

# Conceal underlined text
# \ start="<u>\S\@="
# \ end="\S\@<=<\/u>\|^$"
syntax region markdownUnderline
    \ matchgroup=htmlTagName
    \ start="<u>"
    \ end="<\/u>\|^$"
    \ contains=markdownLineStart,@Spell
    \ concealends
highlight def link markdownUnderline Underlined
#
#
# Other possible options: 0x2B1C (white empty box)
# 0x2705 Green checkbox
# 0x2714 Only checkbox
# 0x25A2 Big large empty square
var use_nerd_fonts = true

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_nerd_fonts')
      && g:markdown_extras_config['use_nerd_fonts']
  use_nerd_fonts = g:markdown_extras_config['use_nerd_fonts']
endif

if use_nerd_fonts
  var empty_checkbox = 0x25A2
  var marked_checkbox = 0x2714

  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'empty_checkbox')
    empty_checkbox = g:markdown_extras_config[ 'empty_checkbox']
  endif

  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'marked_checkbox')
    marked_checkbox = g:markdown_extras_config[ 'marked_checkbox']
  endif

  exe 'syntax match todoCheckbox ''\v\s*-\s\[\s*\]''hs=e-4 conceal cchar='
   .. nr2char(empty_checkbox)
  exe 'syntax match todoCheckbox ''\v\s*-\s\[x\]''hs=e-4 conceal cchar='
  .. nr2char(marked_checkbox)
  hi def link todoCheckbox Todo
endif
