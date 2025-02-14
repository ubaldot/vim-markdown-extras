vim9script

import autoload "../../lib/funcs.vim"
import autoload "../../lib/preview.vim"
import autoload "../../lib/links.vim"
import autoload '../../lib/utils.vim'
&l:tabstop = 2

links.GenerateLinksDict()

if executable('prettier')
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'formatprg')
    &l:formatprg = g:markdown_extras_config['formatprg']
  else
    &l:formatprg = $"prettier --prose-wrap always --print-width {&l:textwidth} "
      .. $"--stdin-filepath {shellescape(expand('%'))}"
  endif

  # Autocmd to format with prettier
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



if executable('pandoc')
  compiler pandoc

  def OpenRenderedFile(cmd: string)
    # Retrieve filename from the make command
    #
    # Assuming that the output file is generated with '--output' instead of
    # '-o'
    var output_file =
      cmd->matchstr('--output\s\+\zs".*"\ze\.')->substitute('"', '', 'g')
    var output_file_extension =
      cmd->matchstr('--output\s\+".*"\zs\.\w\+\ze\s')
    var output_fullpath =
      fnamemodify($"{output_file}{output_file_extension}", ':p')
    echom output_fullpath

    if exists(':Open') != 0
      exe $'Open {output_fullpath}'
    endif
  enddef

  # All the coreography happening inside here relies on the compiler
  # pandoc. If the maintainer of such a compiler changes something, then this
  # function may not work
  def Make(format: string = 'html')
    var cmd = execute($'make {format}')
    OpenRenderedFile(cmd)
  enddef

  # Command definition
  def MakeCompleteList(A: any, L: any, P: any): list<string>
    return ['html', 'docx', 'pdf', 'jira',
      'csv', 'ipynb', 'latex', 'odt', 'rtf']
  enddef

  # Usage :Make, :Make pdf, :Make docx, etc
  command! -nargs=* -buffer -complete=customlist,MakeCompleteList
        \ Make Make(<f-args>)
else
  utils.Echowarn("'pandoc' is not installed.")
endif

# In case the pandoc compiler change, you can use the following as fallback
# solution
# export def Make(...args: list<string>)
#   var input_file = $'"{expand('%:p')}"'

#   # Set output filename
#   var output_file = expand('%:r')

#   # Check if user passed an output file and quote it
#   var o_idx = index(args, '-o')
#   var output_idx = index(args, '--output')

#   if o_idx != -1
#     output_file = $'{args[o_idx + 1]}'
#     args->remove(o_idx, o_idx + 1)
#   elseif o_idx != -1
#     output_file = $'{args[output_idx + 1]}'
#     args->remove(output_idx, output_idx + 1)
#   else
#     output_file = $'{expand('%:p:r')}'
#   endif

#   # Set output file extension
#   var t_match = copy(args)->filter("v:val =~ '-t=\w*'")
#   var to_match = copy(args)->filter("v:val =~ '-to=\w*'")

#   if !empty(t_match)
#     var t_idx = index(args, t_match[0])
#     output_file = $'"{output_file}.{args[t_idx]->matchstr('=\s*\zs\w\+')}"'
#   elseif !empty(to_match)
#     var to_idx = index(args, to_match[0])
#     output_file = $'"{output_file}.{args[to_idx]->matchstr('=\s*\zs\w\+')}"'
#   else
#     # Default to html
#     output_file = $'"{output_file}.html"'
#   endif

#   &l:makeprg = $'pandoc --standalone --metadata '
#     .. $'--from=markdown --output {output_file} '
#     .. $'{join(args)} '
#     .. $'{input_file}'

#   make

#   if exists(':Open') != 0
#     exe $'Open {output_file->substitute('"', '', 'g')}'
#   endif
# enddef

# export def MakeCompleteList(A: any, L: any, P: any): list<string>
#   return ['--to=html', '--to=docx', '--to=pdf', '--to=jira',
#     '--to=csv', '--to=ipynb', '--to=latex', '--to=odt', '--to=rtf']
# enddef


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
