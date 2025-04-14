vim9script

import autoload "../../lib/funcs.vim"
import autoload "../../lib/links.vim"
import autoload '../../lib/utils.vim'
import autoload '../../lib/highlight.vim'
import autoload '../../lib/constants.vim'
import autoload '../../lib/indices.vim'

b:markdown_extras_links = links.RefreshLinksDict()

# Convert links inline links [mylink](blabla) to referenced links [mylink][3]
command! -buffer -nargs=0 MDEConvertLinks links.ConvertLinks()
command! -buffer -nargs=0 MDEIndices indices.ShowIndices()

# Jump back to the previous file
nnoremap <buffer> <backspace> <ScriptCmd>funcs.GoToPrevVisitedBuffer()<cr>

# ---- auto-completion --------------
def MyOmniFunc(findstart: number, base: string): any
    # Define the dictionary
    b:markdown_extras_links = links.RefreshLinksDict()

    if findstart == 1
        # Find the start of the word
        var line = getline('.')
        var start = col('.')
        while start > 1 && getline('.')[start - 1] =~ '\d'
            start -= 1
        endwhile
        return start
    else
        var matches = []
        for key in keys(b:markdown_extras_links)
            add(matches, {word: key, menu: b:markdown_extras_links[key]})
        endfor
        return {words: matches}
    endif
enddef

# Set the custom omnifunction
var use_omnifunc = true

if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'omnifunc')
      use_omnifunc = g:markdown_extras_config['omnifunc']
endif

if use_omnifunc
    echom use_omnifunc
    setlocal completeopt=menu,menuone,noselect
    setlocal omnifunc=MyOmniFunc
    inoremap <buffer> [ [<C-x><C-o>
endif


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
        \ <ScriptCmd>SetSurroundOpFunc('MarkdownCode')<cr>g@
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
  &l:opfunc = function(highlight.AddProp)
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

  if !hasmapto('<Plug>MarkdownQuoteBlock')
    nnoremap <buffer> <localleader>q <Plug>MarkdownQuoteBlock
    xnoremap <buffer> <localleader>q <Plug>MarkdownQuoteBlock
  endif

  # Toggle checkboxes
  if !hasmapto('<Plug>MarkdownToggleCheck')
    nnoremap <buffer> <silent> <localleader>x <Plug>MarkdownToggleCheck
  endif

  # ---------- Remove all --------------------------
  if !hasmapto('<Plug>MarkdownRemove')
    nnoremap <localleader>d <Plug>MarkdownRemove
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
  if !hasmapto('<Plug>MarkdownHighlight')
    nnoremap <localleader>h <Plug>MarkdownHighlight
    xnoremap <localleader>h <Plug>MarkdownHighlight
  endif

  # ------------------------------------------------------
  if !hasmapto('<Plug>MarkdownLinkPreview')
    nnoremap <buffer> <silent> K <Plug>MarkdownLinkPreview
  endif
endif
