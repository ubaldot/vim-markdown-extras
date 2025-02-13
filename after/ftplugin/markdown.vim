vim9script

import autoload "../../lib/funcs.vim"
&l:tabstop = 2


if executable('prettier')
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'formatprg')
    &l:formatprg = g:markdown_extras_config['formatprg']
  else
    &l:formatprg = $"prettier --prose-wrap always --print-width {&l:textwidth} "
          .. $"--stdin-filepath {shellescape(expand('%'))}"
  endif

  # Autocmd to format with ruff
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'format_on_save')
        && g:markdown_extras_config['format_on_save']
    augroup MARKDOWN_FORMAT_ON_SAVE
      autocmd! * <buffer>
      autocmd BufWritePre <buffer> funcs.FormatWithoutMoving()
    augroup END
  endif
else
  funcs.Echowarn("'prettier' not installed!'")
endif

export def Make(format = "html")
  if executable('pandoc')
    var input_file = expand('%:p')
    var output_file = $'{expand('%:p:r')}.{format}'
    var css_style = ""
    if format ==# 'html'
    if exists('g:markdown_extras_config') != 0
        && has_key(g:markdown_extras_config, 'css_style')
          && g:markdown_extras_config['css_style']
      css_style = g:markdown_extras_config['css_style']
    endif

    if exists('g:markdown_extras_config') != 0
        && has_key(g:markdown_extras_config, 'makeprg')
          && g:markdown_extras_config['makeprg']
      &l:makeprg = g:markdown_extras_config['makeprg']
    else
      &l:makeprg = $'pandoc --standalone --metadata title="{expand("%:t")}"'
                  .. $'--from=markdown --css={css_style} '
                  .. $'--output "{output_file}" "{input_file}"'
    endif

    make
    echom &l:makeprg

    if exists(':Open') != 0
      exe $'Open {output_file}'
    endif
  else
    funcs.Echowarn("'pandoc' is not installed.)
  endif
enddef

export def MakeCompleteList(A: any, L: any, P: any): list<string>
  return ['html', 'docx', 'pdf', 'txt', 'jira', 'csv', 'ipynb', 'latex',
    'odt', 'rtf']
enddef

# Usage :Make, :Make pdf, :Make docx, etc
command! -nargs=? -buffer -complete=customlist,MakeCompleteList
      \ Make Make(<f-args>)

# -------- Mappings ------------
# This is very ugly: you add a - [ ] by pasting the content of register 'o'
setreg("o", "- [ ] ")

if exists(':OutlineToggle') != 0
  nnoremap <buffer> <silent> <leader>o <Cmd>OutlineToggle ^- [ <cr>
endif

# Redefinition of <cr>
inoremap <buffer> <silent> <CR> <ScriptCmd>funcs.MDContinueList()<CR>

if empty(maparg("<Plug>MarkdownItalic"))
  noremap <script> <buffer> <Plug>MarkdownItalic <esc><ScriptCmd>funcs.VisualSurround('*', '*')<cr>
endif
if empty(maparg("<Plug>MarkdownBold"))
  noremap <script> <buffer> <Plug>MarkdownBold <esc><ScriptCmd>funcs.VisualSurround('**', '**')<cr>
endif
if empty(maparg("<Plug>MarkdownStrikethrough"))
  noremap <script> <buffer> <Plug>MarkdownStrikethrough <esc><ScriptCmd>funcs.VisualSurround('~~', '~~')<cr>
endif
if empty(maparg("<Plug>MarkdownCode"))
  noremap <script> <buffer> <Plug>MarkdownCode <esc><ScriptCmd>funcs.VisualSurround('`', '`')<cr>
endif
if empty(maparg("<Plug>MarkdownToggleCheck"))
  noremap <script> <buffer> <Plug>MarkdownToggleCheck <ScriptCmd>funcs.MDToggleMark()<cr>
endif
if empty(maparg("<Plug>MarkdownAddLink"))
  noremap <script> <buffer> <Plug>MarkdownAddLink <ScriptCmd>funcs.MDHandleLink()<cr>
endif
if empty(maparg("<Plug>MarkdownRemoveLink"))
  noremap <script> <buffer> <Plug>MarkdownRemoveLink <ScriptCmd>funcs.MDRemoveLink()<cr>
endif
if empty(maparg("<Plug>MarkdownToggleCodeBock"))
  noremap <script> <buffer> <Plug>MarkdownToggleCodeBlock <ScriptCmd>funcs.ToggleBlock('```')<cr>
endif
if empty(maparg("<Plug>MarkdownToggleCodeBockVisual"))
  noremap <script> <buffer> <Plug>MarkdownToggleCodeBlockVisual <esc><ScriptCmd>funcs.ToggleBlock('```', line("'<") - 1, line("'>") + 1)<cr>
endif


# use_default_mappings
if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_default_mappings')
      && g:markdown_extras_config['use_default_mappings']


# Bold, italic, strike-through, code
  if !hasmapto('<Plug>MarkdownItalic')
    xnoremap <buffer> <silent> <leader>i <Plug>MarkdownItalic
  endif
  if !hasmapto('<Plug>MarkdownBold')
    xnoremap <buffer> <silent> <leader>b <Plug>MarkdownBold
  endif
  if !hasmapto('<Plug>MarkdownStrikethrough')
    xnoremap <buffer> <silent> <leader>s <Plug>MarkdownStrikethrough
  endif
  if !hasmapto('<Plug>MarkdownCode')
    xnoremap <buffer> <silent> <leader>c <Plug>MarkdownCode
  endif
# Toggle checkboxes
  if !hasmapto('<Plug>MarkdownToggleCheck')
    nnoremap <buffer> <silent> <leader>x <Plug>MarkdownToggleCheck
  endif
# Handle links
  if !hasmapto('<Plug>MarkdownAddLink')
    nnoremap <buffer> <silent> <enter> <Plug>MarkdownAddLink
  endif
  if !hasmapto('<Plug>MarkdownRemoveLink')
    nnoremap <buffer> <silent> <backspace> <Plug>MarkdownRemoveLink
  endif
  if !hasmapto('<Plug>MarkdownToggleCodeBlock')
    nnoremap <buffer> <silent> <leader>cc <Plug>MarkdownToggleCodeBlock
  endif
  if !hasmapto('<Plug>MarkdownToggleCodeBlockVisual')
    xnoremap <buffer> <silent> <leader>cc <Plug>MarkdownToggleCodeBlockVisual
  endif
endif
