vim9script

# --------- Constants ---------------------------------
const CODE_OPEN_REGEX = '\v((\\|\`)@<!|(\\\`))@<=\`(\`)@!\S'
const CODE_CLOSE_REGEX = '\v\S((\\|\`)@<!|(\\\`))@<=\`(\`)@!|^$'

# TODO It correctly pick \**, and it excludes ** and \*. It cannot distinguish
# is the pattern *\* is opening or closing, because you can easily have
# \S*\*\S, like foo*\*bar.
# You cannot distinguish if the first * is an opening or closing pattern
# without any additional information (read: internal state)
# regex cannot be used when internal states are involved.
# However, by using the information: A) The cursor is currently on a
# highlighted region B) The search direction, you should reliably (always?)
# hit the correct delimiter. Perhaps that could be mathematically proven.
const ITALIC_OPEN_REGEX = '\v((\\|\*)@<!|(\\\*))@<=\*(\*)@!\S'
const ITALIC_CLOSE_REGEX = '\v\S((\\|\*)@<!|(\\\*))@<=\*(\*)@!|^$'

const ITALIC_U_OPEN_REGEX = '\v((\\|_)@<!|(\\_))@<=_(_)@!\S'
const ITALIC_U_CLOSE_REGEX = '\v\S((\\|_)@<!|(\\_))@<=_(_)@!|^$'

const BOLD_OPEN_REGEX = '\v((\\|\*)@<!|(\\\*))@<=\*\*(\*)@!\S'
const BOLD_CLOSE_REGEX = '\v\S((\\|\*)@<!|(\\\*))@<=\*\*(\*)@!|^$'

const BOLD_U_OPEN_REGEX = '\v((\\|_)@<!|(\\_))@<=__(_)@!\S'
const BOLD_U_CLOSE_REGEX = '\v\S((\\|_)@<!|(\\_))@<=__(_)@!|^$'

const STRIKE_OPEN_REGEX = '\v((\\|\~)@<!|(\\\~))@<=\~\~(\~)@!\S'
const STRIKE_CLOSE_REGEX = '\v\S((\\|\~)@<!|(\\\~))@<=\~\~(\~)@!|^$'
# TODO: CODEBLOCK REGEX COULD BE IMPROVED
const CODEBLOCK_OPEN_REGEX = '^```'
const CODEBLOCK_CLOSE_REGEX = '^```$'
# TODO: QUOTEBLOCK REGEX COULD BE IMPROVED
const QUOTEBLOCK_OPEN_REGEX = '^\s*>\s\+'
const QUOTEBLOCK_CLOSE_REGEX = $'^\.*\({QUOTEBLOCK_OPEN_REGEX}\)\@!'

# TODO: investigate and match with syntax
const UNDERLINE_OPEN_REGEX = "<u\>"
const UNDERLINE_CLOSE_REGEX = "\\(</u\\_s*>\\|^$\\)"
# Of the form '[bla bla](https://example.com)' or '[bla bla][12]'
# TODO: if you only want numbers as reference, line [my page][11], then you
# have to replace the last part '\[[^]]+\]' with '\[\d+\]'
# TODO: I had to remove the :// at the end of each prefix because otherwise
# the regex won't work.

export const URL_PREFIXES = [ 'https://', 'http://', 'ftp://', 'ftps://',
    'sftp://', 'telnet://', 'file://']

const URL_PREFIXES_REGEX = URL_PREFIXES
  ->mapnew((_, val) => substitute(val, '\v(\w+):.*', '\1', ''))
  ->join("\|")

const LINK_OPEN_REGEX = '\v\zs\[\ze[^]]+\]'
  .. $'(\(({URL_PREFIXES_REGEX}):[^)]+\)|\[[^]]+\])'
# TODO Differently of the other CLOSE regexes, the link CLOSE regex end up ON
# the last ] and not just before the match
const LINK_CLOSE_REGEX = '\v\[[^]]+\zs\]\ze'
  .. $'(\(({URL_PREFIXES_REGEX}):[^)]+\)|\[[^]]+\])'

export const TEXT_STYLES_DICT = {
  markdownCode: {open_delim: '`', close_delim: '`',
  open_regex: CODE_OPEN_REGEX, close_regex: CODE_CLOSE_REGEX },

  # TODO on the delimiter synIDattr(synID(line("."), col("."), 1), "name")
  # return markdownCodeDelimiter instead of
  # markdownCodeBlockDelimiter. Perhaps it is a bug in vim-markdown. Hence, we
  # cannot include it here.
  # markdownCodeBlock: {open_delim: '```', close_delim: '```',
  # open_regex: CODEBLOCK_OPEN_REGEX, close_regex: CODEBLOCK_CLOSE_REGEX },

  markdownItalic: { open_delim: '*', close_delim: '*',
  open_regex: ITALIC_OPEN_REGEX, close_regex: ITALIC_CLOSE_REGEX },

  markdownItalicU: { open_delim: '_', close_delim: '_',
  open_regex: ITALIC_U_OPEN_REGEX, close_regex: ITALIC_U_CLOSE_REGEX },

  markdownBold: { open_delim: '**', close_delim: '**',
  open_regex: BOLD_OPEN_REGEX, close_regex: BOLD_CLOSE_REGEX },

  markdownBoldU: { open_delim: '__', close_delim: '__',
  open_regex: BOLD_U_OPEN_REGEX, close_regex: BOLD_U_CLOSE_REGEX },

  markdownStrike: { open_delim: '~~', close_delim: '~~',
  open_regex: STRIKE_OPEN_REGEX, close_regex: STRIKE_CLOSE_REGEX },

  markdownLinkText: { open_delim: '[', close_delim: ']',
  open_regex: LINK_OPEN_REGEX, close_regex: LINK_CLOSE_REGEX },

  markdownUnderline: { open_delim: '<u>', close_delim: '</u>',
  open_regex: UNDERLINE_OPEN_REGEX, close_regex: UNDERLINE_CLOSE_REGEX },
}

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
export const LINK_OPEN_DICT = {[TEXT_STYLES_DICT.markdownLinkText.open_delim]:
  TEXT_STYLES_DICT.markdownLinkText.open_regex}
export const LINK_CLOSE_DICT = {[TEXT_STYLES_DICT.markdownLinkText.close_delim]:
  TEXT_STYLES_DICT.markdownLinkText.close_regex}
export const UNDERLINE_OPEN_DICT = {[TEXT_STYLES_DICT.markdownUnderline.open_delim]:
  TEXT_STYLES_DICT.markdownUnderline.open_regex}
export const UNDERLINE_CLOSE_DICT = {[TEXT_STYLES_DICT.markdownUnderline.close_delim]:
  TEXT_STYLES_DICT.markdownUnderline.close_regex}

# TODO on the delimiter synIDattr(synID(line("."), col("."), 1), "name")
# return markdownCodeDelimiter instead of
# markdownCodeBlockDelimiter. Perhaps it is a bug in vim-markdown. Hence, we
  # cannot include it here.
export const CODEBLOCK_OPEN_DICT = {'```': CODEBLOCK_OPEN_REGEX}
export const CODEBLOCK_CLOSE_DICT = {'```': CODEBLOCK_CLOSE_REGEX}

export const QUOTEBLOCK_OPEN_DICT = {'> ': QUOTEBLOCK_OPEN_REGEX}
export const QUOTEBLOCK_CLOSE_DICT = {'> ': QUOTEBLOCK_CLOSE_REGEX}
# --------- End Constants ---------------------------------
