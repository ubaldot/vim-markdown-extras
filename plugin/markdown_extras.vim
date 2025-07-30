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

var release_notes =<< END
# vim-markdown-extras: release notes

## Links
Links must have a valid URL format to keep consistency with
the markdown requirements. Hence, the following link:

[1]: C:\User\John\My Documents\foo bar.txt

shall be converted into:

[1]: file:///C:/User/John/My%20Documents/foo%20bar.txt

Please, update the links in your markdown files.

💡 **TIP**:
You can ask any LLM to convert the links for you.
Typically, they are quite accurate.


## g:markdown_extras_indices
The global variable `g:markdown_extras_indices` has been renamed to
`g:markdown_extras_index`.


## :MDEIndices
The command `:MDEIndices` has been renamed to `:MDEIndex` and can take
an optional argument.
For example you can call `:MDEIndices ['apple', 'banana', 'strawberry']`.
If `:MDEIndices` is called without arguments, then the value of
`g:markdown_extras_index` is used.
Finally, such a command is now global.


## :MDEPathToURL
Convert the passed file name to a valid URL and store the result in a register.
The default register is 'p' but that can be changed through the
g:markdown_extras_config dictionary.


Press <Esc> to close this popup.
END

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

# PathToURL
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
command! -nargs=? MDEIndex indices.ShowIndex(<f-args>)

g:markdown_extras_loaded = true
