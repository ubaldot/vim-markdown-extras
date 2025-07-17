vim9script noclear

# Editing markdown files has never been so pleasant.
# Maintainer:	Ubaldo Tiberi
# License: BSD-3

import autoload './../autoload/mde_utils.vim' as utils
import autoload './../autoload/mde_funcs.vim' as funcs

if has('win32') && !has("patch-9.1.1270")
  # Needs Vim version 9.0 and above
  echoerr "[markdown-extras] You need at least Vim 9.1.1270"
  finish
elseif !has('patch-9.1.1071')
  echoerr "[markdown-extras] You need at least Vim 9.1.1071"
  finish
endif


if exists('g:markdown_extras_loaded')
  finish
endif
g:markdown_extras_loaded = true

augroup MARKDOWN_EXTRAS_VISITED_BUFFERS
    autocmd!
    autocmd BufEnter *.md,*.markdown,*.mdown,*.mkd funcs.AddVisitedBuffer()
    autocmd BufDelete *.md,*.markdown,*.mdown,*.mkd
          \ funcs.RemoveVisitedBuffer(bufnr())
augroup END

# Check if prettier can/shall be used or not
export var use_prettier = true

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_prettier')
  use_prettier = g:markdown_extras_config['use_prettier']
endif

if use_prettier
  def PrettierInstalledCheck()
    if !executable('prettier')
      utils.Echowarn("'prettier' not installed!'")
      use_prettier = false
    endif
  enddef

  if &filetype == "markdown"
    PrettierInstalledCheck()
  else
    augroup MARKDOWN_EXTRAS_PRETTIER_CHECK
      autocmd!
      # TODO: Changing BufReadPre with FileType markdown won't work because
      # FileType markdown autocmd is executed after ftplugin/markdown.vim is sourced,
      # and therefore ftplugin/markdown.vim would see use_prettier = true all
      # the time. Hence, the hack is to use BufReadPre and to specify all the
      # possible file extensions.
      autocmd BufReadPre *.md,*.markdown,*.mdown,*.mkd ++once
            \ PrettierInstalledCheck()
    augroup END
  endif
endif

# Check if pandoc can/shall be used or not
export var use_pandoc = true

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_pandoc')
  use_pandoc = g:markdown_extras_config['use_pandoc']
endif

if use_pandoc
  def PandocInstalledCheck()
    if !executable('pandoc')
      utils.Echowarn("'pandoc' not installed!'")
      use_pandoc = false
    endif
  enddef

  if &filetype == "markdown"
    PandocInstalledCheck()
  else
    augroup MARKDOWN_EXTRAS_PANDOC_CHECK
      autocmd!
      autocmd BufReadPre *.md,*.markdown,*.mdown,*.mkd ++once
            \ PandocInstalledCheck()
    augroup END
  endif
endif
