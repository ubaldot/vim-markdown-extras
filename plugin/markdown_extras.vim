vim9script

# Editing markdown files has never been so pleasant.
# Maintainer:	Ubaldo Tiberi
# License: BSD-3

import autoload './../lib/mde_utils.vim' as utils
import autoload './../lib/mde_funcs.vim' as funcs
import autoload './../lib/mde_indices.vim' as indices

if has('win32') && !has("patch-9.1.1270")
  # Needs Vim version 9.0 and above
  echoerr "[markdown-extras] You need at least Vim 9.1.1270"
  finish
elseif !has('patch-9.1.1071')
  echoerr "[markdown-extras] You need at least Vim 9.1.1071"
  finish
endif

g:loaded_markdown_extras = true

const release_notes =<< END

- Removed rendering based on builtin compiler pandoc
- Cleaned up documentation

Press <Esc> or 'q' to close this popup.
END


def PopupFilter(id: number, key: string): bool
  # To handle the keys when release notes popup is visible
  # Close
  if key ==# 'q' || key ==# "\<esc>"
    popup_close(id)
  # Move down
  elseif ["\<tab>", "\<C-n>", "\<Down>", "\<ScrollWheelDown>"]->index(key) != -1
    win_execute(id, "normal! \<c-e>")
  # Move up
  elseif ["\<S-Tab>", "\<C-p>", "\<Up>", "\<ScrollWheelUp>"]->index(key) != -1
    win_execute(id, "normal! \<c-y>")
  # Jump down
  elseif key == "\<C-f>"
    win_execute(id, "normal! \<c-f>")
  # Jump up
  elseif key == "\<C-b>"
    win_execute(id, "normal! \<c-b>")
  else
    return false
  endif
  return true
enddef

def ShowReleaseNotes()
  const title = ' vim-markdown-extras: release notes '
  const popup_options = {
    border: [1, 1, 1, 1],
    borderchars:  ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    scrollbar: false,
    title: title,
    filter: PopupFilter
  }

  const popup_id = popup_create(release_notes, popup_options)
  win_execute(popup_id, 'set filetype=markdown')
  win_execute(popup_id, 'set conceallevel=2')
enddef

def ShowDefaultMappings()

const default_mappings =<< END

<BS> - go to previous visited markdown buffer
K - markdown link preview
<enter> - create/open link
<s-enter> - open link in a split window

The following mappings start with <localleader>:

Text styles
  b{text-object} - bold
  i{text-object} - italic
  s{text-object} - strikethrough
  u{text-object} - underline
  h{text-object} - highlight
  c{text-object} - code
  f{text-object} - fenced code-block

Miscellanea
  q - quote block
  x - Toggle checkbox
  o - Show empty checkbox items in a window (require vim-outline)

Links
  l{text-object} - create link
  n - jump to next link
  N - jump to previous link

Tables (no text-object needed)
  S - sum block (only in visual mode)
  F - format table (normal mode)
  | - format table (insert mode)
  _ - insert row delimiter
  C - change text in a cell
  A - append text in a cell

Remove all
  r - remove text styles, highlight, links, etc.

Press <Esc> or 'q' to close this popup.
END

  const title = ' vim-markdown-extras: default mappings'
  const popup_options = {
    border: [1, 1, 1, 1],
    borderchars:  ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    scrollbar: false,
    title: title,
    filter: PopupFilter
  }

  const popup_id = popup_create(default_mappings, popup_options)
  win_execute(popup_id, 'set filetype=text')
enddef

# Error/Warnings triggered with new releases
if exists('g:markdown_extras_indices') != 0
  utils.Echowarn("'g:markdown_extras_indices' has been renamed. "
        \ .. "See `:MDEReleaseNotes`")
endif

augroup MARKDOWN_EXTRAS_OBSOLETE_COMMAND
  autocmd!
  autocmd CmdUndefined MDEIndices utils.Echowarn("Command `:MDEIndices` "
        \ .. "has been renamed. See `:MDEReleaseNotes`")
augroup END


# --------------------------------

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
if empty(exepath('pandoc'))
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

# PathToURL
# TODO: there is a new function in new Vim releases
def PathToURLReg(path: string)
  var path_to_url_register = 'p'
  if exists('g:markdown_extras_config') != 0
      && has_key(g:markdown_extras_config, 'path_to_url_register')
    path_to_url_register = g:markdown_extras_config['path_to_url_register']
  endif

  setreg(path_to_url_register, indices.PathToURL(fnamemodify(path, ':p')))
  echo $"URL stored in register '{path_to_url_register}'"
enddef

command! -nargs=1 -complete=file MDEPathToURL PathToURLReg(<f-args>)
command! -nargs=0 MDEReleaseNotes ShowReleaseNotes()
command! -nargs=0 MDEDefaultMappings ShowDefaultMappings()
command! -nargs=? MDEIndex indices.ShowIndex(<f-args>)
