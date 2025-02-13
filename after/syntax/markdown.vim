vim9script

var use_nerd_fonts = true

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_nerd_fonts')
      && g:markdown_extras_config['use_nerd_fonts']
  use_nerd_fonts = g:markdown_extras_config['use_nerd_fonts']
endif

if use_nerd_fonts
  syntax match todoCheckbox '\v\s*-|\s\[\s*\]'hs=e-4 conceal cchar=O
  syntax match todoCheckbox '\v\s*-|\s\[x\]'hs=e-4 conceal cchar=X
  hi def link todoCheckbox Todo
endif
