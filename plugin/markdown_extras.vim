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

# Check prettier executable
export var use_prettier = true
var prettier_installed = true

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_prettier')
  use_prettier = g:markdown_extras_config['use_prettier']
endif

def PrettierInstalledCheck()
  if !executable('prettier')
    prettier_installed = false
    use_prettier = false
  endif

  # If you run Vim with an argument, e.g. vim testfile.md
  if &filetype == "markdown" && !prettier_installed
    utils.Echowarn("'prettier' not installed!'")
  endif
enddef

augroup MARKDOWN_EXTRAS_PRETTIER_CHECK
  autocmd!
  autocmd BufReadPre * ++once PrettierInstalledCheck()
augroup END

augroup MARKDOWN_EXTRAS_PRETTIER_ERROR
  autocmd!
  autocmd FileType markdown ++once {
    if !prettier_installed
      utils.Echowarn("'prettier' not installed!'")
    endif
  }
augroup END

# Check pandoc executable
export var use_pandoc = true
var pandoc_installed = true

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_pandoc')
  use_pandoc = g:markdown_extras_config['use_pandoc']
endif

def PandocInstalledCheck()
  if !executable('pandoc')
    pandoc_installed = false
    use_pandoc = false
  endif

  # If you run Vim with an argument, e.g. vim testfile.md
  if &filetype == "markdown" && !pandoc_installed
    utils.Echowarn("'pandoc' not installed!'")
  endif
enddef

augroup MARKDOWN_EXTRAS_PANDOC_CHECK
  autocmd!
  autocmd BufReadPre * ++once PandocInstalledCheck()
augroup END

augroup MARKDOWN_EXTRAS_PANDOC_ERROR
  autocmd!
  autocmd FileType markdown ++once {
    if !pandoc_installed
      utils.Echowarn("'pandoc' not installed!'")
    endif
  }
augroup END
