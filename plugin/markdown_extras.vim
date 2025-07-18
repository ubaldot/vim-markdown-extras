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

augroup MARKDOWN_EXTRAS_VISITED_BUFFERS
    autocmd!
    autocmd BufEnter *  {
      if &filetype ==# 'markdown'
        funcs.AddVisitedBuffer()
      endif
    }
    autocmd BufDelete * {
      if getbufvar(expand('%'), '&filetype') ==# 'markdown'
        funcs.RemoveVisitedBuffer(bufnr())
      endif
    }
augroup END

# Check prettier executable
export var use_prettier = true

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_prettier')
  use_prettier = g:markdown_extras_config['use_prettier']
endif

# If user wants to use prettier but it is not available...
if use_prettier && !executable('prettier')
  use_prettier = false
  # If vim is called with args, like vim README.md
  if &filetype == 'markdown'
    utils.Echowarn("'prettier' not installed!'")
  else
    # As soon as we open a markdown file, the error is displayed
    augroup MARKDOWN_EXTRAS_PRETTIER_ERROR
      autocmd!
      autocmd FileType markdown ++once {
          utils.Echowarn("'prettier' not installed!'")
      }
    augroup END
  endif
endif

# Check pandoc executable
export var use_pandoc = true

if exists('g:markdown_extras_config') != 0
    && has_key(g:markdown_extras_config, 'use_pandoc')
  use_pandoc = g:markdown_extras_config['use_pandoc']
endif

# If user wants to use pandoc but it is not available...
if use_pandoc && !executable('pandoc')
  use_pandoc = false
  if &filetype == 'markdown'
    utils.Echowarn("'pandoc' not installed!'")
  else
    augroup MARKDOWN_EXTRAS_PANDOC_ERROR
      autocmd!
      autocmd FileType markdown ++once {
          utils.Echowarn("'pandoc' not installed!'")
      }
    augroup END
  endif
endif

g:markdown_extras_loaded = true
