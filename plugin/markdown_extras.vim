vim9script noclear

# Editing markdown files has never been so pleasant.
# Maintainer:	Ubaldo Tiberi
# License: BSD-3

import autoload './../autoload/mde_utils.vim' as utils
import autoload './../autoload/mde_funcs.vim' as funcs
import autoload './../autoload/mde_indices.vim' as indices

if has('win32') && !has("patch-9.1.1270")
  # Needs Vim version 9.0 and above
  echoerr "[markdown-extras] You need at least Vim 9.1.1270"
  finish
elseif !has('patch-9.1.1071')
  echoerr "[markdown-extras] You need at least Vim 9.1.1071"
  finish
endif

if exists('g:markdown_extras_loaded') && g:markdown_extras_loaded
  finish
endif

var release_notes =<< FOO
## vim-markdown-extras: release notes

1. Links must have a valid URL format to keep consistency with
the markdown requirements. Hence, the following link:

[1]: C:\User\John\My Documents\foo bar.txt

shall be converted into:

[1]: file:///C:/User/John/My%20Documents/foo%20bar.txt

Please, update the links in your markdown files.

💡 **TIP**:
You can ask any LLM to convert the links for you.
Typically, they are quite accurate.

2. `:MDEIndices` has been renamed to `:MDEIndex` and can take an argument, for
example you can call as `:MDEIndices ['apple', 'banana', 'strawberry']`.
Furthermore, such a command is no longer valid only for markdown files but
it become global.

Press <Esc> to close this popup.
FOO

def ShowReleaseNotes()

  const popup_options = {
      border: [1, 1, 1, 1],
      borderchars:  ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
      filter: 'popup_filter_menu',
    }

  const popup_id = popup_create(release_notes, popup_options)
  win_execute(popup_id, 'set filetype=markdown')
  win_execute(popup_id, 'set conceallevel=2')
enddef

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

command! -nargs=0 MDEReleaseNotes ShowReleaseNotes()
command! -nargs=? MDEIndex indices.ShowIndices(<f-args>)

g:markdown_extras_loaded = false
