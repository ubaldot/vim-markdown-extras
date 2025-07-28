vim9script

import autoload "../autoload/mde_funcs.vim" as funcs
import autoload "../autoload/mde_links.vim" as links
import autoload '../autoload/mde_utils.vim' as utils
import autoload '../autoload/mde_highlight.vim' as highlights
import autoload '../autoload/mde_constants.vim' as constants
import autoload '../autoload/mde_indices.vim' as indices
import autoload '../plugin/markdown_extras.vim' as markdown_extras

b:markdown_extras_links = links.RefreshLinksDict()

# UBA: check that the values of the dict are valid URL
for link in values(b:markdown_extras_links)
  if !links.IsURL(link)
    utils.Echowarn($'"{link}" is not a valid URL.'
                .. ' Run :MDEReleaseNotes to read more')
    sleep 200m
    break
  endif
endfor

# Convert links inline links [mylink](blabla) to referenced links [mylink][3]
command! -buffer -nargs=0 MDEConvertLinks links.ConvertLinks()
command! -buffer -nargs=0 MDEIndices indices.ShowIndices()

# Jump back to the previous file
nnoremap <buffer> <backspace> <ScriptCmd>funcs.GoToPrevVisitedBuffer()<cr>


# -------------- prettier ------------------------
#
if markdown_extras.use_prettier
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
if markdown_extras.use_pandoc
  # All the coreography happening inside here relies on the compiler
  # pandoc.

  # b:pandoc_compiler_args is used in the bundled compiler-pandoc
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'pandoc_args')
    b:pandoc_compiler_args = join(g:markdown_extras_config['pandoc_args'])
  endif

  compiler pandoc

  def Make(format: string = 'html')

    var output_file = $'{expand('%:p:r')}.{format}'
    var cmd = execute($'make {format}')
    # TIP: use g< to show all the echoed messages since now
    # TIP2: redraw! is used to avoid the "PRESS ENTER" thing
    echo cmd->matchstr('.*\ze2>&1') | redraw!

    # TODO: pandoc compiler returns v:shell_error = 0 even if there are
    # errors. Add a condition on v:shell_error once pandoc compiler is fixed.
    if exists(':Open') != 0
      exe $'Open {fnameescape(output_file)}'
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
        \ MDEMake Make(<f-args>)
endif
# ------------------- End pandoc ------------------------------------

# -------- Mappings ------------
# Redefinition of <cr>. Unmap if user does not want it.
inoremap <buffer> <silent> <CR> <ScriptCmd>funcs.CR_Hacked()<CR>
if exists('g:markdown_extras_config')
    && has_key(g:markdown_extras_config, 'hack_CR')
    && !g:markdown_extras_config['hack_CR']
  iunmap <buffer> <cr>
endif

nnoremap <buffer> <expr> <CR> empty(links.IsLink())
      \ ? '<ScriptCmd>SetLinkOpFunc()<CR>g@iw'
      \ : '<ScriptCmd>links.OpenLink()<CR>'

nnoremap <buffer> <expr> <s-CR> empty(links.IsLink())
      \ ? '<s-CR>'
      \ : '<ScriptCmd>links.OpenLink(true)<CR>'

if exists(':OutlineToggle') != 0
  nnoremap <buffer> <silent> <localleader>o <Cmd>OutlineToggle ^- [ <cr>
endif

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

if empty(maparg('<Plug>MarkdownLinkPreview'))
  noremap <script> <buffer> <Plug>MarkdownLinkPreview
        \  <ScriptCmd>links.PreviewPopup()<cr>
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
        \ <ScriptCmd>SetSurroundOpFunc('markdownCode')<cr>g@
endif

if empty(maparg('<Plug>MarkdownUnderline'))
  noremap <script> <buffer> <Plug>MarkdownUnderline
        \ <ScriptCmd>SetSurroundOpFunc('markdownUnderline')<cr>g@
endif

if empty(maparg('<Plug>MarkdownRemove'))
  noremap <script> <buffer> <Plug>MarkdownRemove
        \ <ScriptCmd>funcs.RemoveAll()<cr>
endif

def SetHighlightOpFunc()
  &l:opfunc = function(highlights.AddProp)
enddef

if empty(maparg('<Plug>MarkdownHighlight'))
  noremap <script> <buffer> <Plug>MarkdownHighlight
        \ <ScriptCmd>SetHighlightOpFunc()<cr>g@
endif

def SetCodeBlock()
  &l:opfunc = function(utils.SetBlock)
enddef

if empty(maparg('<Plug>MarkdownCodeBlock'))
  noremap <script> <buffer> <Plug>MarkdownCodeBlock
        \ <ScriptCmd>SetCodeBlock()<cr>g@
endif


def SetQuoteBlockOpFunc()
  &l:opfunc = function(utils.SetQuoteBlock)
enddef

if empty(maparg('<Plug>MarkdownQuoteBlock'))
  noremap <script> <buffer> <Plug>MarkdownQuoteBlock
        \ <ScriptCmd>SetQuoteBlockOpFunc()<cr>g@
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
   if empty(mapcheck('<localleader>b', 'n', 1))
    nnoremap <buffer> <localleader>b <Plug>MarkdownBold
   endif
   if empty(mapcheck('<localleader>b', 'x', 1))
    xnoremap <buffer> <localleader>b <Plug>MarkdownBold
   endif
  endif

  if !hasmapto('<Plug>MarkdownItalic')
   if empty(mapcheck('<localleader>i', 'n', 1))
    nnoremap <buffer> <localleader>i <Plug>MarkdownItalic
   endif
   if empty(mapcheck('<localleader>i', 'x', 1))
    xnoremap <buffer> <localleader>i <Plug>MarkdownItalic
   endif
  endif

  if !hasmapto('<Plug>MarkdownStrike')
   if empty(mapcheck('<localleader>s', 'n', 1))
    nnoremap <buffer> <localleader>s <Plug>MarkdownStrike
   endif
   if empty(mapcheck('<localleader>s', 'x', 1))
    xnoremap <buffer> <localleader>s <Plug>MarkdownStrike
   endif
  endif

  if !hasmapto('<Plug>MarkdownCode')
   if empty(mapcheck('<localleader>c', 'n', 1))
    nnoremap <buffer> <localleader>c <Plug>MarkdownCode
   endif
   if empty(mapcheck('<localleader>c', 'x', 1))
    xnoremap <buffer> <localleader>c <Plug>MarkdownCode
   endif
  endif

  if !hasmapto('<Plug>MarkdownUnderline')
   if empty(mapcheck('<localleader>u', 'n', 1))
    nnoremap <buffer> <localleader>u <Plug>MarkdownUnderline
   endif
   if empty(mapcheck('<localleader>u', 'x', 1))
    xnoremap <buffer> <localleader>u <Plug>MarkdownUnderline
   endif
  endif

  if !hasmapto('<Plug>MarkdownCodeBlock')
   if empty(mapcheck('<localleader>f', 'n', 1))
    nnoremap <buffer> <localleader>f <Plug>MarkdownCodeBlock
   endif
   if empty(mapcheck('<localleader>f', 'x', 1))
    xnoremap <buffer> <localleader>f <Plug>MarkdownCodeBlock
   endif
  endif

  if !hasmapto('<Plug>MarkdownQuoteBlock')
   if empty(mapcheck('<localleader>q', 'n', 1))
    nnoremap <buffer> <localleader>q <Plug>MarkdownQuoteBlock
   endif
   if empty(mapcheck('<localleader>q', 'x', 1))
    xnoremap <buffer> <localleader>q <Plug>MarkdownQuoteBlock
   endif
  endif

  # Toggle checkboxes
  if !hasmapto('<Plug>MarkdownToggleCheck')
   if empty(mapcheck('<localleader>x', 'n', 1))
    nnoremap <buffer> <silent> <localleader>x <Plug>MarkdownToggleCheck
   endif
  endif

  # ---------- Remove all --------------------------
  if !hasmapto('<Plug>MarkdownRemove')
   if empty(mapcheck('<localleader>d', 'n', 1))
    nnoremap <localleader>d <Plug>MarkdownRemove
   endif
  endif
  # ---------- Links --------------------------
  if !hasmapto('<Plug>MarkdownAddLink')
   if empty(mapcheck('<localleader>l', 'n', 1))
    nnoremap <buffer> <localleader>l <Plug>MarkdownAddLink
   endif
   if empty(mapcheck('<localleader>l', 'x', 1))
    xnoremap <buffer> <localleader>l <Plug>MarkdownAddLink
   endif
  endif

  if !hasmapto('<Plug>MarkdownGotoLinkForward')
   if empty(mapcheck('<localleader>n', 'n', 1))
    nnoremap <buffer> <silent> <localleader>n <Plug>MarkdownGotoLinkForward
   endif
  endif

  if !hasmapto('<Plug>MarkdownGotoLinkBackwards')
   if empty(mapcheck('<localleader>N', 'n', 1))
    nnoremap <buffer> <silent> <localleader>N <Plug>MarkdownGotoLinkBackwards
   endif
  endif

  # ---------- Highlight --------------------------
  if !hasmapto('<Plug>MarkdownHighlight')
   if empty(mapcheck('<localleader>h', 'n', 1))
    nnoremap <localleader>h <Plug>MarkdownHighlight
   endif
   if empty(mapcheck('<localleader>h', 'x', 1))
    xnoremap <localleader>h <Plug>MarkdownHighlight
   endif
  endif

  # ------------------------------------------------------
  if !hasmapto('<Plug>MarkdownLinkPreview')
   if empty(mapcheck('K', 'n', 1))
    nnoremap <buffer> <silent> K <Plug>MarkdownLinkPreview
   endif
  endif
endif
