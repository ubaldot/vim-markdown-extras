vim9script

import autoload "../../lib/funcs.vim"
import autoload "../../lib/preview.vim"
import autoload "../../lib/links.vim"
import autoload '../../lib/utils.vim'
&l:tabstop = 2

links.GenerateLinksDict()

var use_prettier = true
if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_prettier')
    && g:markdown_extras_config['use_prettier']
  use_prettier = g:markdown_extras_config['use_prettier']
endif

if use_prettier && executable('prettier')
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'formatprg')
    &l:formatprg = g:markdown_extras_config['formatprg']
  else
    &l:formatprg = $"prettier --prose-wrap always --print-width {&l:textwidth} "
      .. $"--stdin-filepath {shellescape(expand('%'))}"
  endif

  # Autocmd to format with prettier on save
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'format_on_save')
      && g:markdown_extras_config['format_on_save']
    augroup MARKDOWN_FORMAT_ON_SAVE
      autocmd! * <buffer>
      autocmd BufWritePre <buffer> utils.FormatWithoutMoving()
    augroup END
  endif
else
  utils.Echowarn("'prettier' not installed!'")
endif

# pandoc
var use_pandoc = true
if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_pandoc')
    && g:markdown_extras_config['use_pandoc']
  use_pandoc = g:markdown_extras_config['use_pandoc']
endif

if use_pandoc && executable('pandoc')
  # All the coreography happening inside here relies on the compiler
  # pandoc.

  compiler pandoc
  def Make(format: string = 'html')
    #
    # b:pandoc_compiler_args is used in the bundled compiler-pandoc
    if exists('g:markdown_extras_config') != 0
        && has_key(g:markdown_extras_config, 'pandoc_args')
      b:pandoc_compiler_args = join(g:markdown_extras_config['pandoc_args'])
    endif

    var output_file = $'{expand('%:p:h')}.{format}'
    var cmd = execute($'make {format}')

    if exists(':Open') != 0
      exe $'Open {output_file}'
    endif
  enddef

  # Command definition
  def MakeCompleteList(A: any, L: any, P: any): list<string>
    return systemlist('pandoc --list-output-formats')
      ->filter($'v:val =~ "^{A}"')
  enddef

  # Usage :Make, :Make pdf, :Make docx, etc
  command! -nargs=* -buffer -complete=customlist,MakeCompleteList
        \ Make Make(<f-args>)
else
  utils.Echowarn("'pandoc' is not installed.")
endif

# -------- Mappings ------------
# This is very ugly: you add a - [ ] by pasting the content of register 'o'
setreg("o", "- [ ] ")

if exists(':OutlineToggle') != 0
  nnoremap <buffer> <silent> <leader>o <Cmd>OutlineToggle ^- [ <cr>
endif

# Redefinition of <cr>
inoremap <buffer> <silent> <CR> <ScriptCmd>funcs.ContinueList()<CR>

if empty(maparg('<Plug>MarkdownItalic'))
  noremap <script> <buffer> <Plug>MarkdownItalic
        \ <esc><ScriptCmd>utils.VisualSurround('*', '*')<cr>
endif
if empty(maparg('<Plug>MarkdownBold'))
  noremap <script> <buffer> <Plug>MarkdownBold
        \ <esc><ScriptCmd>utils.VisualSurround('**', '**')<cr>
endif
if empty(maparg('<Plug>MarkdownStrikethrough'))
  noremap <script> <buffer> <Plug>MarkdownStrikethrough
        \ <esc><ScriptCmd>utils.VisualSurround('~~', '~~')<cr>
endif
if empty(maparg('<Plug>MarkdownCode'))
  noremap <script> <buffer> <Plug>MarkdownCode
        \ <esc><ScriptCmd>utils.VisualSurround('`', '`')<cr>
endif
if empty(maparg('<Plug>MarkdownToggleCheck'))
  noremap <script> <buffer> <Plug>MarkdownToggleCheck
        \ <ScriptCmd>funcs.ToggleMark()<cr>
endif
if empty(maparg('<Plug>MarkdownAddLink'))
  noremap <script> <buffer> <Plug>MarkdownAddLink
        \ <ScriptCmd>links.HandleLink()<cr>
endif
if empty(maparg('<Plug>MarkdownRemoveLink'))
  noremap <script> <buffer> <Plug>MarkdownRemoveLink
        \ <ScriptCmd>links.RemoveLink()<cr>
endif
if empty(maparg('<Plug>MarkdownToggleCodeBock'))
  noremap <script> <buffer> <Plug>MarkdownToggleCodeBlock
        \  <ScriptCmd>funcs.ToggleBlock('```')<cr>
endif
if empty(maparg('<Plug>MarkdownToggleCodeBockVisual'))
  noremap <script> <buffer> <Plug>MarkdownToggleCodeBlockVisual
  \ <esc><ScriptCmd>funcs.ToggleBlock('```', line("'<") - 1, line("'>") + 1)<cr>
endif
if empty(maparg('<Plug>MarkdownReferencePreview'))
  noremap <script> <buffer> <Plug>MarkdownReferencePreview
        \  <ScriptCmd>preview.PreviewPopup()<cr>
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
  if !hasmapto('<Plug>MarkdownReferencePreview')
    nnoremap <buffer> <silent> K <Plug>MarkdownReferencePreview
  endif
endif
