vim9script

import autoload "../../lib/funcs.vim"
import autoload "../../lib/preview.vim"
import autoload "../../lib/links.vim"
import autoload '../../lib/utils.vim'
import autoload '../../lib/highlight.vim'
import autoload '../../lib/constants.vim'

def RefreshLinksDict()
  b:links_dict = links.GenerateLinksDict()
enddef

RefreshLinksDict()
command! -buffer -nargs=0 MDERefreshLinksDict RefreshLinksDict()
command! -buffer -nargs=0 MDEConvertLinks links.ConvertLinks()

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
inoremap <buffer> <silent> <CR> <ScriptCmd>funcs.CR_Hacked()<CR>
# nnoremap <buffer> <expr> <CR> empty(links.IsLink())
#       \ ? <ScriptCmd>SetLinkOpFunc()<cr>g@iw
#       \ : <ScriptCmd>links.OpenLink()<cr>

nnoremap <buffer> <expr> <CR> empty(links.IsLink())
      \ ? '<ScriptCmd>SetLinkOpFunc()<CR>g@iw'
      \ : '<ScriptCmd>links.OpenLink()<CR>'


if exists(':OutlineToggle') != 0
  nnoremap <buffer> <silent> <localleader>o <Cmd>OutlineToggle ^- [ <cr>
endif

def RemoveAll()
  # TODO could be refactored to increase speed, but it may not be necessary
  const range_info = utils.IsInRange()
  const prop_info = highlight.IsOnProp()
  const syn_info = synIDattr(synID(line("."), col("."), 1), "name")

  # If on plain text, do nothing, just execute a normal! <BS>
  if empty(range_info) && empty(prop_info) && syn_info != 'markdownCodeBlock'
    exe "norm! \<BS>"
    return
  endif

  # Start removing the text props
  if !empty(prop_info)
    prop_remove({'id': prop_info.id, 'all': 0})
    return
  endif

  # Check markdownCodeBlocks
  if syn_info == 'markdownCodeBlock'
    utils.UnsetBlock(syn_info)
    return
  endif

  # Text styles removal setup
  const target = keys(range_info)[0]
  var text_styles = copy(constants.TEXT_STYLES_DICT)
  unlet text_styles['markdownLinkText']

  if index(keys(text_styles), target) != -1
    utils.RemoveSurrounding(range_info)
  elseif target == 'markdownLinkText'
    links.RemoveLink()
  endif
enddef
nnoremap <buffer> <BS> <ScriptCmd>RemoveAll()<cr>

if empty(maparg('<Plug>MarkdownToggleCheck'))
  noremap <script> <buffer> <Plug>MarkdownToggleCheck
        \ <ScriptCmd>funcs.ToggleMark()<cr>
endif

def SetLinkOpFunc()
  &l:opfunc = function(links.CreateLink)
enddef

if empty(maparg('<Plug>MarkdownAddLink'))
  noremap <script> <buffer> <Plug>MarkdownAddLink
        \ <ScriptCmd>SetLinkOpFunc()<cr>g@
endif

if empty(maparg('<Plug>MarkdownGotoLinkForward'))
  noremap <script> <buffer> <Plug>MarkdownGotoLinkForward
        \ <ScriptCmd>links.SearchLink()<cr>
endif

if empty(maparg('<Plug>MarkdownGotoLinkBackwards'))
  noremap <script> <buffer> <Plug>MarkdownGotoLinkBackwards
        \ <ScriptCmd>links.SearchLink(true)<cr>
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
  &l:opfunc = function(Surround, [style])
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

if empty(maparg('<Plug>MarkdownUnderline'))
  noremap <script> <buffer> <Plug>MarkdownUnderline
        \ <ScriptCmd>SetSurroundOpFunc('markdownUnderline')<cr>g@
endif

def SetHighlightOpFunc()
  &l:opfunc = function(highlight.AddProp)
enddef

if empty(maparg('<Plug>MarkdownAddHighlight'))
  noremap <script> <buffer> <Plug>MarkdownAddHighlight
        \ <ScriptCmd>SetHighlightOpFunc()<cr>g@
endif

def SetCodeBlock()
  &l:opfunc = function(utils.SetBlock)
enddef

if empty(maparg('<Plug>MarkdownCodeBlock'))
  noremap <script> <buffer> <Plug>MarkdownCodeBlock
        \ <ScriptCmd>SetCodeBlock()<cr>g@
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

  if !hasmapto('<Plug>MarkdownItalic')
    nnoremap <buffer> <localleader>i <Plug>MarkdownItalic
    xnoremap <buffer> <localleader>i <Plug>MarkdownItalic
  endif

  if !hasmapto('<Plug>MarkdownStrike')
    nnoremap <buffer> <localleader>s <Plug>MarkdownStrike
    xnoremap <buffer> <localleader>s <Plug>MarkdownStrike
  endif

  if !hasmapto('<Plug>MarkdownCode')
    nnoremap <buffer> <localleader>c <Plug>MarkdownCode
    xnoremap <buffer> <localleader>c <Plug>MarkdownCode
  endif

  if !hasmapto('<Plug>MarkdownUnderline')
    nnoremap <buffer> <localleader>u <Plug>MarkdownUnderline
    xnoremap <buffer> <localleader>u <Plug>MarkdownUnderline
  endif

  if !hasmapto('<Plug>MarkdownCodeBlock')
    nnoremap <buffer> <localleader>f <Plug>MarkdownCodeBlock
    xnoremap <buffer> <localleader>f <Plug>MarkdownCodeBlock
  endif

  # Toggle checkboxes
  if !hasmapto('<Plug>MarkdownToggleCheck')
    nnoremap <buffer> <silent> <localleader>x <Plug>MarkdownToggleCheck
  endif

  # ---------- Links --------------------------
  if !hasmapto('<Plug>MarkdownAddLink')
    nnoremap <buffer> <localleader>l <Plug>MarkdownAddLink
    xnoremap <buffer> <localleader>l <Plug>MarkdownAddLink
  endif

  if !hasmapto('<Plug>MarkdownGotoLinkForward')
    nnoremap <buffer> <silent> <localleader>n <Plug>MarkdownGotoLinkForward
  endif

  if !hasmapto('<Plug>MarkdownGotoLinkBackwards')
    nnoremap <buffer> <silent> <localleader>N <Plug>MarkdownGotoLinkBackwards
  endif

  # ---------- Highlight --------------------------
  if !hasmapto('<Plug>MarkdownAddHighlight')
    nnoremap <localleader>h <Plug>MarkdownAddHighlight
    xnoremap <localleader>h <Plug>MarkdownAddHighlight
  endif

  # ------------------------------------------------------
  if !hasmapto('<Plug>MarkdownReferencePreview')
    nnoremap <buffer> <silent> K <Plug>MarkdownReferencePreview
  endif
endif

## References
