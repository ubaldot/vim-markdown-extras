vim9script

import autoload "../../lib/funcs.vim"
import autoload "../../lib/preview.vim"
import autoload "../../lib/links.vim"
import autoload '../../lib/utils.vim'

# ------ Attempt for better regex -----------
# The following regex reads (opening italics delimiter, pre and post):
#  1. * must be preceded by a \W character with the exclusion of '*' and '\'
#     OR it must be at the beginning of line,
#  2. * must NOT be followed by '\'s or by another '*'.
# const ITALIC_OPEN_REGEX = '\v((\W|^|\\\*_)@<=(\*|\\)@<!)\*(\s|\*)@!'
# USE THIS if you use bundled markdown:
# searchpos('\v((\W|^)@<=(\\)@<!)\*(\s|\*)@!', 'b')
#
# The following regex reads (closing italics delimiter, pre and post):
#    1. * cannot be preceded by a '\s' character or by a '\' or by a '*'.
#    2. * cannot be followed by another '*'.
#  TODO: It won't catch closing delimiters when '\**' (the second asterisk is
#  supposed to be the closing delimiter) because a preceding '*' is
#  is already excluded.
# const ITALIC_CLOSE_REGEX = '\v(\s|\\|\*)@<!\*\*@!' # ALMOST GOOD
# ------ End attempt for better regex -----------

# --------- Constants ---------------------------------
const CODE_OPEN_REGEX = '\v(\\|`)@<!``@!\S'
const CODE_CLOSE_REGEX = '\v\S(\\|`)@<!``@!'

const ITALIC_OPEN_REGEX = '\v((\\|\*)@<!|(\\\*))@<=\*\*@!\S'
const ITALIC_CLOSE_REGEX = '\v\S((\\|\*)@<!|(\\\*))@<=\*\*@!'

const ITALIC_U_OPEN_REGEX = '\v((\\|_)@<!|(\\_))@<=_(_)@\S!'
const ITALIC_U_CLOSE_REGEX = '\v\S((\\|_)@<!|(\\_))@<=_(_)@!'

const BOLD_OPEN_REGEX = '\v((\\|\*)@<!|(\\\*))@<=\*\*(\*)@!\S'
const BOLD_CLOSE_REGEX = '\v\S((\\|\*)@<!|(\\\*))@<=\*\*(\*)@!'

const BOLD_U_OPEN_REGEX = '\v((\\|_)@<!|(\\_))@<=__(_)@\S!'
const BOLD_U_CLOSE_REGEX = '\v\S((\\|_)@<!|(\\_))@<=__(_)@!'

const STRIKE_OPEN_REGEX = '\v(\\|\~)@<!\~\~\~@!\S'
const STRIKE_CLOSE_REGEX = '\v\S(\\|\~)@<!\~\~\~@!\S'
# TODO: CODEBLOCK REGEX COULD BE IMPROVED
const CODEBLOCK_REGEX = '```'

# Of the form '[bla bla](https://example.com)' or '[bla bla][12]'
# TODO: if you only want numbers as reference, line [my page][11], then you
# have to replace the last part '\[[^]]+\]' with '\[\d+\]'
# TODO: I had to remove the :// at the end of each prefix because otherwise
# the regex won't work.
const URL_PREFIXES = links.URL_PREFIXES
  ->mapnew((_, val) => substitute(val, '\v(\w+):.*', '\1', ''))
  ->join("\|")

const LINK_OPEN_REGEX = '\v\zs\[\ze[^]]+\]'
  .. $'(\(({URL_PREFIXES}):[^)]+\)|\[[^]]+\])'
const LINK_CLOSE_REGEX = '\v\[[^]]+\zs\]\ze'
  .. $'(\(({URL_PREFIXES}):[^)]+\)|\[[^]]+\])'

export const TEXT_STYLES_DICT = {
  markdownCode: {open_delim: '`', close_delim: '`',
  open_regex: CODE_OPEN_REGEX, close_regex: CODE_CLOSE_REGEX },

  markdownItalic: { open_delim: '*', close_delim: '*',
  open_regex: ITALIC_OPEN_REGEX, close_regex: ITALIC_CLOSE_REGEX },

  markdownItalicU: { open_delim: '_', close_delim: '_',
  open_regex: ITALIC_U_OPEN_REGEX, close_regex: ITALIC_U_CLOSE_REGEX },

  markdownBold: { open_delim: '**', close_delim: '**',
  open_regex: BOLD_OPEN_REGEX, close_regex: BOLD_CLOSE_REGEX },

  markdownBoldU: { open_delim: '__', close_delim: '__',
  open_regex: BOLD_U_OPEN_REGEX, close_regex: BOLD_U_CLOSE_REGEX },

  markdownStrike: { open_delim: '~~', close_delim: '~~',
  open_regex: STRIKE_OPEN_REGEX, close_regex: STRIKE_OPEN_REGEX },
}

export const LINK_OPEN_DICT = {'[': LINK_OPEN_REGEX}
export const LINK_CLOSE_DICT = {']': LINK_CLOSE_REGEX}

export const CODE_OPEN_DICT = {[TEXT_STYLES_DICT.markdownCode.open_delim]:
  TEXT_STYLES_DICT.markdownCode.open_regex}
export const CODE_CLOSE_DICT = {[TEXT_STYLES_DICT.markdownCode.close_delim]:
  TEXT_STYLES_DICT.markdownCode.close_regex}
export const ITALIC_OPEN_DICT = {[TEXT_STYLES_DICT.markdownItalic.open_delim]:
  TEXT_STYLES_DICT.markdownItalic.open_regex}
export const ITALIC_CLOSE_DICT = {[TEXT_STYLES_DICT.markdownItalic.close_delim]:
  TEXT_STYLES_DICT.markdownItalic.close_regex}
export const ITALIC_U_OPEN_DICT =
  {[TEXT_STYLES_DICT.markdownItalicU.open_delim]:
  TEXT_STYLES_DICT.markdownItalicU.open_regex}
export const ITALIC_U_CLOSE_DICT =
  {[TEXT_STYLES_DICT.markdownItalicU.close_delim]:
  TEXT_STYLES_DICT.markdownItalicU.close_regex}
export const BOLD_OPEN_DICT = {[TEXT_STYLES_DICT.markdownBold.open_delim]:
  TEXT_STYLES_DICT.markdownBold.open_regex}
export const BOLD_CLOSE_DICT = {[TEXT_STYLES_DICT.markdownBold.close_delim]:
  TEXT_STYLES_DICT.markdownBold.close_regex}
export const BOLD_U_OPEN_DICT = {[TEXT_STYLES_DICT.markdownBoldU.open_delim]:
  TEXT_STYLES_DICT.markdownBoldU.open_regex}
export const BOLD_U_CLOSE_DICT = {[TEXT_STYLES_DICT.markdownBoldU.close_delim]:
  TEXT_STYLES_DICT.markdownBoldU.close_regex}
export const STRIKE_OPEN_DICT = {[TEXT_STYLES_DICT.markdownStrike.open_delim]:
  TEXT_STYLES_DICT.markdownStrike.open_regex}
export const STRIKE_CLOSE_DICT = {[TEXT_STYLES_DICT.markdownStrike.close_delim]:
  TEXT_STYLES_DICT.markdownStrike.close_regex}

export const CODEBLOCK_DICT = {'```': CODEBLOCK_REGEX}
# --------- End Constants ---------------------------------

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
else
  utils.Echowarn("'prettier' not installed!'")
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
    #

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
else
  utils.Echowarn("'pandoc' is not installed.")
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

def SetSurroundOpFunc(open_string: string,
    close_string: string,
    all_open_styles: dict<string>,
    all_close_styles: dict<string>)

  &l:opfunc = function(
    Surround, [open_string, close_string, all_open_styles, all_close_styles]
  )
enddef

if empty(maparg('<Plug>MarkdownBold'))
  noremap <script> <buffer> <Plug>MarkdownBold
        \ <ScriptCmd>SetSurroundOpFunc('**', '**',
        \ TEXT_STYLES_DICT, TEXT_STYLES_DICT)<cr>g@
endif

if empty(maparg('<Plug>MarkdownItalic'))
  noremap <script> <buffer> <Plug>MarkdownItalic
        \ <ScriptCmd>SetSurroundOpFunc(' *', '* ',
        \ TEXT_STYLES_DICT, TEXT_STYLES_DICT)<cr>g@
endif

if empty(maparg('<Plug>MarkdownBoldUnderscore'))
  noremap <script> <buffer> <Plug>MarkdownBoldUnderscore
        \ <ScriptCmd>SetSurroundOpFunc('__', '__',
        \ TEXT_STYLES_DICT, TEXT_STYLES_DICT)<cr>g@
endif

if empty(maparg('<Plug>MarkdownItalicUnderscore'))
  noremap <script> <buffer> <Plug>MarkdownItalicUnderscore
        \ <ScriptCmd>SetSurroundOpFunc('_', '_',
        \ TEXT_STYLES_DICT, TEXT_STYLES_DICT)<cr>g@
endif

if empty(maparg('<Plug>MarkdownStrikethrough'))
  noremap <script> <buffer> <Plug>MarkdownStrikethrough
        \ <ScriptCmd>SetSurroundOpFunc('~~', '~~',
        \ TEXT_STYLES_DICT, TEXT_STYLES_DICT)<cr>g@
endif

if empty(maparg('<Plug>MarkdownCode'))
  noremap <script> <buffer> <Plug>MarkdownCode
        \ <ScriptCmd>SetSurroundOpFunc('`', '`',
        \ TEXT_STYLES_DICT, TEXT_STYLES_DICT)<cr>g@
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

  if !hasmapto('<Plug>MarkdownBoldUnderscore')
    nnoremap <buffer> <localleader>b <Plug>MarkdownBoldUnderscore
    xnoremap <buffer> <localleader>b <Plug>MarkdownBoldUnderscore
  endif

  if !hasmapto('<Plug>MarkdownItalic')
    nnoremap <buffer> <localleader>i <Plug>MarkdownItalic
    xnoremap <buffer> <localleader>i <Plug>MarkdownItalic
  endif

  if !hasmapto('<Plug>MarkdownItalic')
    nnoremap <buffer> <localleader>i_ <Plug>MarkdownItalicUnderscore
    xnoremap <buffer> <localleader>i_ <Plug>MarkdownItalicUnderscore
  endif

  if !hasmapto('<Plug>MarkdownStrikethrough')
    nnoremap <buffer> <localleader>s <Plug>MarkdownStrikethrough
    xnoremap <buffer> <localleader>s <Plug>MarkdownStrikethrough
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
endif
