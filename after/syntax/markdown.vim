vim9script

# Other possible options: 0x2B1C (white empty box)
# 0x2705 Green checkbox
# 0x2714 Only checkbox
var use_nerd_fonts = true

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_nerd_fonts')
      && g:markdown_extras_config['use_nerd_fonts']
  use_nerd_fonts = g:markdown_extras_config['use_nerd_fonts']
endif

if use_nerd_fonts
  exe 'syntax match todoCheckbox ''\v\s*-\s\[\s*\]''hs=e-4 conceal cchar='
   .. nr2char(0x25A1)
  exe 'syntax match todoCheckbox ''\v\s*-\s\[x\]''hs=e-4 conceal cchar='
  .. nr2char(0x2714)
  hi def link todoCheckbox Todo
endif
