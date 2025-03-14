vim9script

import autoload "../../lib/funcs.vim"
import autoload "../../lib/preview.vim"
import autoload "../../lib/links.vim"
import autoload '../../lib/utils.vim'
import autoload '../../lib/highlight.vim'
import autoload '../../lib/constants.vim'

# TODO put this in an autocmd?
links.GenerateLinksDict()

# -------------- prettier ------------------------
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
endif
# --------------End prettier ------------------------

# -------------------- pandoc -----------------------
var use_pandoc = true
if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_pandoc')
    && g:markdown_extras_config['use_pandoc']
  use_pandoc = g:markdown_extras_config['use_pandoc']
endif

if use_pandoc && executable('pandoc')
  # All the coreography happening inside here relies on the compiler
  # pandoc.

  # b:pandoc_compiler_args is used in the bundled compiler-pandoc
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'pandoc_args')
    b:pandoc_compiler_args = join(g:markdown_extras_config['pandoc_args'])
  endif

  compiler pandoc

  # TODO: make it to take additional arguments
  def Make(format: string = 'html')

    var output_file = $'{expand('%:p:r')}.{format}'
    var cmd = execute($'make {format}')
    # TIP: use g< to show all the echoed messages since now
    # TIP2: redraw! is used to avoid the "PRESS ENTER" thing
    echo cmd->matchstr('.*\ze2>&1') | redraw!

    if exists(':Open') != 0
      exe $'Open {output_file}'
    endif
  enddef

  # Command definition
  def MakeCompleteList(A: any, L: any, P: any): list<string>
    return systemlist('pandoc --list-output-formats')
      ->filter($'v:val =~ "^{A}"')
      # Get rid off the ^M in Windows
      ->map((_, val) => substitute(val, '\r', '', 'g'))
  enddef

  # Usage :Make, :Make pdf, :Make docx, etc
  command! -nargs=? -buffer -complete=customlist,MakeCompleteList
        \ Make Make(<f-args>)
endif
# ------------------- End pandoc ------------------------------------


# -------- Mappings ------------
# This is very ugly: you add a - [ ] by pasting the content of register 'o'
setreg("o", "- [ ] ")

# Redefinition of <cr>
inoremap <buffer> <silent> <CR> <ScriptCmd>funcs.ContinueList()<CR>

if exists(':OutlineToggle') != 0
  nnoremap <buffer> <silent> <localleader>o <Cmd>OutlineToggle ^- [ <cr>
endif

if empty(maparg('<Plug>MarkdownToggleCheck'))
  noremap <script> <buffer> <Plug>MarkdownToggleCheck
        \ <ScriptCmd>funcs.ToggleMark()<cr>
endif
#
# TODO: to be reviewed
if empty(maparg('<Plug>MarkdownAddLink'))
  noremap <script> <buffer> <Plug>MarkdownAddLink
        \ <ScriptCmd>links.HandleLink()<cr>
endif
if empty(maparg('<Plug>MarkdownRemoveLink'))
  noremap <script> <buffer> <Plug>MarkdownRemoveLink
        \ <ScriptCmd>links.RemoveLink()<cr>
endif
# -------------------------------------------

if empty(maparg('<Plug>MarkdownReferencePreview'))
  noremap <script> <buffer> <Plug>MarkdownReferencePreview
        \  <ScriptCmd>preview.PreviewPopup()<cr>
endif

# Text styles
var Surround = utils.SurroundSmart
if exists('g:markdown_extras_config')
    && has_key(g:markdown_extras_config, 'smart_textstyle')
    && !g:markdown_extras_config['smart_textstyle']
  Surround = utils.SurroundSimple
endif

def SetSurroundOpFunc(style: string)

  &l:opfunc = function(
    Surround, [style]
  )
enddef

if empty(maparg('<Plug>MarkdownBold'))
  noremap <script> <buffer> <Plug>MarkdownBold
        \ <ScriptCmd>SetSurroundOpFunc('markdownBold')<cr>g@
endif

if empty(maparg('<Plug>MarkdownItalic'))
  noremap <script> <buffer> <Plug>MarkdownItalic
        \ <ScriptCmd>SetSurroundOpFunc('markdownItalic')<cr>g@
endif

if empty(maparg('<Plug>MarkdownBoldUnderscore'))
  noremap <script> <buffer> <Plug>MarkdownBoldUnderscore
        \ <ScriptCmd>SetSurroundOpFunc('markdownBoldU')<cr>g@
endif

if empty(maparg('<Plug>MarkdownItalicUnderscore'))
  noremap <script> <buffer> <Plug>MarkdownItalicUnderscore
        \ <ScriptCmd>SetSurroundOpFunc('markdownItalicU')<cr>g@
endif

if empty(maparg('<Plug>MarkdownStrike'))
  noremap <script> <buffer> <Plug>MarkdownStrike
        \ <ScriptCmd>SetSurroundOpFunc('markdownStrike')<cr>g@
endif

if empty(maparg('<Plug>MarkdownCode'))
  noremap <script> <buffer> <Plug>MarkdownCode
        \ <ScriptCmd>SetSurroundOpFunc('MarkdownCode')<cr>g@
endif

if empty(maparg('<Plug>MarkdownAddHighlight'))
  noremap <script> <buffer> <Plug>MarkdownAddHighlight
        \ <esc><ScriptCmd>highlight.AddProp()<cr>
endif

if empty(maparg('<Plug>MarkdownClearHighlight'))
  noremap <script> <buffer> <Plug>MarkdownClearHighlight
        \ <esc><ScriptCmd>highlight.ClearProp()<cr>
endif
# ----------- TODO:TO BE REVIEWED ----------------------

def SetCodeBlock(open_block: dict<string>,
    close_block: dict<string>)

  &l:opfunc = function(
    utils.SetBlock, [open_block, close_block]
  )
enddef

if empty(maparg('<Plug>MarkdownCodeBlock'))
  noremap <script> <buffer> <Plug>MarkdownCodeBlock
        \ <ScriptCmd>SetCodeBlock(CODEBLOCK_DICT, CODEBLOCK_DICT)<cr>g@
endif
# ------------------------------------------------------------

# use_default_mappings
var use_default_mappings = true
if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_default_mappings')
      && g:markdown_extras_config['use_default_mappings']
  use_default_mappings = g:markdown_extras_config['use_default_mappings']
endif
# -----------------------------------------------------------------

if use_default_mappings
  # ------------ Text style mappings ------------------
  if !hasmapto('<Plug>MarkdownBold')
    nnoremap <buffer> <localleader>b <Plug>MarkdownBold
    xnoremap <buffer> <localleader>b <Plug>MarkdownBold
  endif

  # if !hasmapto('<Plug>MarkdownBoldUnderscore')
  #   nnoremap <buffer> <localleader>b <Plug>MarkdownBoldUnderscore
  #   xnoremap <buffer> <localleader>b <Plug>MarkdownBoldUnderscore
  # endif

  if !hasmapto('<Plug>MarkdownItalic')
    nnoremap <buffer> <localleader>i <Plug>MarkdownItalic
    xnoremap <buffer> <localleader>i <Plug>MarkdownItalic
  endif

  # if !hasmapto('<Plug>MarkdownItalic')
  #   nnoremap <buffer> <localleader>i_ <Plug>MarkdownItalicUnderscore
  #   xnoremap <buffer> <localleader>i_ <Plug>MarkdownItalicUnderscore
  # endif

  if !hasmapto('<Plug>MarkdownStrike')
    nnoremap <buffer> <localleader>s <Plug>MarkdownStrike
    xnoremap <buffer> <localleader>s <Plug>MarkdownStrike
  endif

  if !hasmapto('<Plug>MarkdownCode')
    nnoremap <buffer> <localleader>c <Plug>MarkdownCode
    xnoremap <buffer> <localleader>c <Plug>MarkdownCode
  endif

  if !hasmapto('<Plug>MarkdownCodeBlock')
    nnoremap <buffer> <localleader>f <Plug>MarkdownCodeBlock
    xnoremap <buffer> <localleader>f <Plug>MarkdownCodeBlock
  endif

  # Toggle checkboxes
  if !hasmapto('<Plug>MarkdownToggleCheck')
    nnoremap <buffer> <silent> <localleader>x <Plug>MarkdownToggleCheck
  endif
  # ---------- TODO: to be reviewed ------------------
  if !hasmapto('<Plug>MarkdownAddLink')
    nnoremap <buffer> <silent> <enter> <Plug>MarkdownAddLink
  endif
  if !hasmapto('<Plug>MarkdownRemoveLink')
    nnoremap <buffer> <silent> <backspace> <Plug>MarkdownRemoveLink
  endif
  # ------------------------------------------------------
  if !hasmapto('<Plug>MarkdownReferencePreview')
    nnoremap <buffer> <silent> K <Plug>MarkdownReferencePreview
  endif

  # ---------- Highlight --------------------------
  if !hasmapto('<Plug>MarkdownAddHighlight')
    xnoremap <leader>ha <Plug>MarkdownAddHighlight
  endif
  if !hasmapto('<Plug>MarkdownClearHighlight')
    xnoremap <leader>hd <Plug>MarkdownClearHighlight
  endif
endif
