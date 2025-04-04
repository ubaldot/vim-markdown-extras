vim9script noclear

# Editing markdown files has never been so pleasant.
# Maintainer:	Ubaldo Tiberi
# License: BSD-3

import autoload './../lib/utils.vim'
import autoload './../lib/funcs.vim'


if !has("patch-9.1.1270")
  # Needs Vim version 9.0 and above
  echoerr "[markdown-extras] You need at least Vim 9.1.1270"
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
    autocmd BufEnter *.md funcs.AddVisitedBuffer()
augroup END
