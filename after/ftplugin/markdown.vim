vim9script

import autoload "../../lib/funcs.vim"
import autoload "../../lib/preview.vim"
import autoload "../../lib/links.vim"
import autoload '../../lib/utils.vim'

const CODE_REGEX = '\v(\\|`)@<!``@!'
# var italic_regex = '\v(\\|\*)@<!\*\*@!'
# The following picks standalone * and the last * of \**
# It excludes escaped * (i.e. \*\*\*, and sequences like ****)
const ITALIC_REGEX = '\v((\\|\*)@<!|(\\\*))@<=\*\*@!'
const ITALIC_REGEX_U = '\v((\\|_)@<!|(\\_))@<=_(_)@!'
const BOLD_REGEX = '\v(\\|\*)@<!\*\*\*@!'
const BOLD_REGEX_U = '\v(\\|_)@<!___@!'
const STRIKETHROUGH_REGEX = '\v(\\|\~)@<!\~\~\~@!'
# TODO: CODEBLOCK REGEX COULD BE IMPROVED
const CODEBLOCK_REGEX = '```'

# Of the form '[bla bla](https://example.com)' or '[bla bla][12]'
# TODO: if you only want numbers as reference, line [my page][11], then you
# have to replace the last part '\[[^]]+\]' with '\[\d+\]'
# const LINK_OPEN_REGEX = '\v(\\|])@<!\zs\[\ze[^]]+\](\((http|https):[^)]+\)|\[[^]]+\])'
# const LINK_CLOSE_REGEX = '\v(\\|])@<!\[[^]]+\zs\]\ze(\((http|https):[^)]+\)|\[[^]]+\])'
#
# TODO: I had to remove the :// at the end of each prefix because otherwise
# the regex won't work.
const URL_PREFIXES = utils.URL_PREFIXES
  ->mapnew((_, val) => substitute(val, '\v(\w+):.*', '\1', ''))
  ->join("\|")
const LINK_OPEN_REGEX = '\v(\\|])@<!\zs\[\ze[^]]+\]'
  .. $'(\(({URL_PREFIXES}):[^)]+\)|\[[^]]+\])'
const LINK_CLOSE_REGEX = '\v(\\|])@<!\[[^]]+\zs\]\ze'
  .. $'(\(({URL_PREFIXES}):[^)]+\)|\[[^]]+\])'
export const TEXT_STYLE_DICT = {'`': CODE_REGEX,
  '*': ITALIC_REGEX,
  '**': BOLD_REGEX,
  '_': ITALIC_REGEX_U,
  '__': BOLD_REGEX_U,
  '~~': STRIKETHROUGH_REGEX}

export const LINK_OPEN_DICT = {'[': LINK_OPEN_REGEX}
export const LINK_CLOSE_DICT = {']': LINK_CLOSE_REGEX}
export const CODE_DICT = {'`': CODE_REGEX}
export const CODEBLOCK_DICT = {'```': CODEBLOCK_REGEX}
export const ITALIC_DICT = {'*': ITALIC_REGEX}
export const BOLD_DICT = {'**': BOLD_REGEX}
export const ITALIC_DICT_U = {'_': ITALIC_REGEX_U}
export const BOLD_DICT_U = {'__': BOLD_REGEX_U}
export const STRIKETHROUGH_DICT = {'~~': STRIKETHROUGH_REGEX}

links.GenerateLinksDict()

var Surround = utils.SurroundSmart
if exists('g:markdown_extras_config')
    && has_key(g:markdown_extras_config, 'smart_textstyle')
    && g:markdown_extras_config['smart_textstyle']
  Surround = utils.SurroundSimple
endif

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'leader')
    b:mapleader = g:markdown_extras_config['leader']
endif

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

# -------- Mappings ------------
# This is very ugly: you add a - [ ] by pasting the content of register 'o'
setreg("o", "- [ ] ")

if exists(':OutlineToggle') != 0
  nnoremap <buffer> <silent> <leader>o <Cmd>OutlineToggle ^- [ <cr>
endif

# Redefinition of <cr>
inoremap <buffer> <silent> <CR> <ScriptCmd>funcs.ContinueList()<CR>

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
var use_default_mappings = true
if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_default_mappings')
      && g:markdown_extras_config['use_default_mappings']
  use_default_mappings = g:markdown_extras_config['use_default_mappings']
endif

if use_default_mappings
  # ------------ Text style mappings ------------------
  #
  # TEXT-OBJECTS text-style mappings
  # Text-obects i` and a` are removed since they refer to code
  # 'aw', 'aW', 'as, 'is' are removed as it generate a non-valid markdown
  var all_Vim_text_objects = ['aw', 'iw', 'iW', 'as', 'is', 'ap', 'ip',
    'a]', 'a[', 'i]', 'i[', 'a)', 'a(', 'ab', 'i)', 'i(', 'ib', 'a>', 'a<',
    'i>', 'i<', 'at', 'it', 'a}', 'a{', 'aB', 'i}', 'i{', 'iB', 'a\"', 'a''',
    'i\"', 'i''']

  for text_object in all_Vim_text_objects
    # Italic
    if maparg($"<leader>i{text_object}", "n") == ""
      exe $'nnoremap <buffer> <leader>i{text_object} '
      .. $'<ScriptCmd>utils.SurroundNew("*", "{text_object}")<cr>'
    endif

    # Bold
    if maparg($"<leader>b{text_object}", "n") == ""
      exe $'nnoremap <buffer> <leader>b{text_object} '
      .. $'<ScriptCmd>utils.SurroundNew("\*\*", "{text_object}")<cr>'
    endif

    # Strikethrough
    if maparg($"<leader>s{text_object}", "n") == ""
      exe $'nnoremap <buffer> <leader>s{text_object} '
      .. $'<ScriptCmd>utils.SurroundNew("~~", "{text_object}")<cr>'
    endif

    # Code
    if maparg($"<leader>c{text_object}", "n") == ""
      exe $'nnoremap <buffer> <leader>c{text_object} '
      .. $'<ScriptCmd>utils.SurroundNew("`", "{text_object}")<cr>'
    endif
  endfor

  # VISUAL text-style mapping
  # Italic
  if maparg($"<leader>i", "x") == ""
     xnoremap <buffer> <leader>i
          \ <esc><ScriptCmd>utils.SurroundNew('*')<cr>
  endif

  # Bold
  if maparg($"<leader>b", "x") == ""
     xnoremap <buffer> <leader>b
          \ <esc><ScriptCmd>utils.SurroundNew('**')<cr>
  endif

  # Strikethrough
  if maparg($"<leader>s", "x") == ""
     xnoremap <buffer> <leader>s
          \ <esc><ScriptCmd>utils.SurroundNew('~~')<cr>
  endif

  # Code
  if maparg($"<leader>c", "x") == ""
     xnoremap <buffer> <leader>c
          \ <esc><ScriptCmd>utils.SurroundNew('`')<cr>
  endif

  # ----------------- Other mappings ------------------------
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
