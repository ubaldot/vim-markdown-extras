vim9script noclear

# Editing markdown files has never been so pleasant.
# Maintainer:	Ubaldo Tiberi
# License: BSD-3

import autoload './../autoload/utils.vim'
import autoload './../autoload/mde_funcs.vim'

if has('win32') && !has("patch-9.1.1270")
  # Needs Vim version 9.0 and above
  echoerr "[markdown-extras] You need at least Vim 9.1.1270"
  finish
elseif !has('patch-9.1.1071')
  echoerr "[markdown-extras] You need at least Vim 9.1.1071"
  finish
endif

if !executable('prettier') && !exists('g:markdown_extras_loaded')
    utils.Echowarn("'prettier' not installed!'")
endif
if !executable('pandoc') && !exists('g:markdown_extras_loaded')
    utils.Echowarn("'pandoc' not installed!'")
endif

if exists('g:markdown_extras_loaded')
  finish
endif
g:markdown_extras_loaded = true

augroup MARKDOWN_EXTRAS_VISITED_BUFFERS
    autocmd!
    autocmd BufEnter *.md mde_funcs.AddVisitedBuffer()
    autocmd BufDelete *.md mde_funcs.RemoveVisitedBuffer(bufnr())
augroup END
