vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
import "./../after/ftplugin/markdown.vim"
import "./../lib/utils.vim"
import "./../lib/constants.vim"

var WaitForAssert = common.WaitForAssert
var TEXT_STYLES_DICT = constants.TEXT_STYLES_DICT
var CODE_OPEN_DICT = constants.CODE_OPEN_DICT
var ITALIC_OPEN_DICT = constants.ITALIC_OPEN_DICT
var BOLD_OPEN_DICT = constants.BOLD_OPEN_DICT
var STRIKE_OPEN_DICT = constants.STRIKE_OPEN_DICT

# Test file 1
var src_name_1 = 'testfile.md'
var lines_1 =<< trim END
      Sed ut perspiciatis unde omnis iste natus error sit voluptatem
      accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae
      ab illo inventore veritatis et quasi architecto beatae vitae dicta
      sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit
      aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos
      qui ratione voluptatem sequi nesciunt.

      Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet,
      consectetur, adipisci velit, sed quia non numquam eius modi tempora
      incidunt ut (labore et ~~dolore magnam) aliquam quaerat~~ voluptatem. Ut
      enim ad `minima [veniam`, quis no~~strum] exercitationem~~ ullam corporis
      suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur?

      Quis autem vel eum iure reprehenderit qui in ea **voluptate velit esse**
      quam nihil (molestiae consequatur), vel illum qui dolorem eum fugiat quo
      voluptas nulla pariatur?

      At vero eos et accusamus et iusto odio dignissimos ducimus, qui
      blandit*iis pra(esent*ium `voluptatum` del*eniti atque) corrupti*, quos
      dolores et quas molestias excepturi sint, obcaecati cupiditate non
      pro**vident, (sim**ilique sunt *in* culpa, `qui` officia *deserunt*)
      mollitia) animi, id est laborum et dolorum fuga.
      Et harum quidem reru[d]um facilis est e[r]t expedita distinctio.

      Nam libero tempore, cum soluta nobis est eligendi optio, cumque nihil
      impedit, quo minus id, quod
      maxime placeat facere possimus, omnis voluptas assumenda est, omnis
      dolor repellend[a]us. `Temporibus autem quibusdam et aut officiis
      debitis aut rerum necessitatibus saepe eveniet, ut et voluptates
      repudiandae sint et molestiae non recusandae.`

      Itaque earum rerum hic *tenetur a sapiente `delectus`, ut aut reiciendis
      voluptatibus maiores*
      alias consequatur aut perferendis doloribus asperiores repellat.
END

def Generate_testfile(lines: list<string>, src_name: string)
   writefile(lines, src_name)
enddef

def Cleanup_testfile(src_name: string)
   delete(src_name)
enddef


# Tests start here
def g:Test_CR_hacked()
  Generate_testfile(lines_1, src_name_1)
  vnew
  exe $"edit {src_name_1}"
  setlocal spell spelllang=la

  # Basic "-" item
  var expected_line = '- '
  # Write '- foo' to line 7 and hit <cr>
  # OBS! normal is without ! to prevent bypassing mappings
  execute "normal 7ggi-\<space>foo\<enter>"

  assert_match(expected_line, getline(8))

  # 1. Write 'bar' to line 8 and hit <cr> twice
  silent execute "normal abar\<enter>\<enter>"
  expected_line = '- bar'
  assert_match(expected_line, getline(8))

  expected_line = ''
  assert_match('', getline(9))
  assert_match('', getline(10))

  # 2. Try with the tedious * as item
  # Current line = 10
  silent execute "normal i*\<space>bar\<enter>baz\<enter>\<enter>"
  expected_line = '* bar'
  assert_match('', getline(10))
  expected_line = '* baz'
  assert_match('', getline(11))
  expected_line = ''
  assert_match('', getline(12))
  assert_match('', getline(13))

  # 3. Try with the TODO lists - [ ]
  #
  silent execute "normal i-\<space>[\<space>]\<space>foo\<enter>bar\<enter>\<enter>"
  expected_line = "- [ ] foo"
  assert_true(expected_line ==# getline(13))
  expected_line = "- [ ] bar"
  assert_true(expected_line ==# getline(14))
  expected_line = ''
  assert_match('', getline(15))
  assert_match('', getline(16))


  # Current line = 16
  # Test numbered list
  silent execute "normal i99.\<space>foo\<enter>bar\<enter>\<enter>"
  expected_line = "99. foo"
  assert_true(expected_line ==# getline(16))
  expected_line = "100. bar"
  assert_true(expected_line ==# getline(17))
  expected_line = ''
  assert_match('', getline(18))
  assert_match('', getline(19))

  # Current line = 19
  # Test indentation
  silent execute "normal i-\<space>foo\<enter>bar\<enter>"
  silent execute "normal I\<space>\<space>\<esc>Afoo\<enter>bar\<enter>"
  silent execute "normal I\<space>\<space>\<esc>Afoo\<enter>bar\<enter>\<enter>"
  # silent execute "normal i\<space>\<space>ifoo\<enter>bar\<enter>"
  expected_line = '- foo'
  assert_match(expected_line, getline(19))
  expected_line = '- bar'
  assert_match(expected_line, getline(20))
  expected_line = '  - foo'
  assert_match(expected_line, getline(21))
  expected_line = '  - bar'
  assert_match(expected_line, getline(22))
  expected_line = '    - foo'
  assert_match(expected_line, getline(23))
  expected_line = '    - bar'
  assert_match(expected_line, getline(24))
  expected_line = ''
  assert_match(expected_line, getline(25))
  expected_line = ''
  assert_match(expected_line, getline(26))

  # Test quoted blocks
  cursor(26, 1)
  silent exe "normal i>\<space>hello\<space>world\<CR>"
              .. "today\<space>is\<cr>"
              .. "beautiful\<cr>\<cr>"
  const expected_text_26_29 = ['> hello world', '> today is', '> beautiful', '']
  assert_equal(expected_text_26_29, getline(26, 29))
  # redraw!
  # sleep 3
  :%bw!
  Cleanup_testfile(src_name_1)
enddef


def g:Test_CR_hacked_linebreaks()
  # OBS! normal shall be without ! because we are testing <CR> which is
  # hacked!
  Generate_testfile(lines_1, src_name_1)
  vnew
  exe $"edit {src_name_1}"
  setlocal spell spelllang=la

  # Basic "-" item
  var expected_line_7 = '- foo'
  var expected_line_8 = '- bar'
  # Write '- foo bar' to line 7 and hit <cr> on 'bar'
  # OBS! normal is without ! to prevent bypassing mappings
  execute "normal 7ggi-\<space>foo\<space>bar\<esc>bi\<enter>"

  assert_match(expected_line_7, getline(7))
  assert_match(expected_line_8, getline(8))

  # 2. enter in the lhs of the item symbol
  execute "normal I\<enter>"
  assert_match(expected_line_7, getline(7))
  assert_match('- ', getline(8))
  assert_match(expected_line_8, getline(9))

  # 3. test numbered list
  var text = "    3. ciao sono io, amore mio"
  var expected_line_19 = "    3. ciao sono io, "
  var expected_line_20 = "    4. amore mio"
  append(18, text)
  cursor(19, 22)
  execute "normal i\<cr>"
  assert_match(expected_line_19, getline(19))
  assert_match(expected_line_20, getline(20))

  # 4. Add number above
  execute "normal I\<cr>"
  expected_line_20 = "    4. "
  var expected_line_21 = "    5. amore mio"

  assert_match(expected_line_19, getline(19))
  assert_match(expected_line_20, getline(20))
  assert_match(expected_line_21, getline(21))

  execute "normal wwi\<cr>"
  expected_line_21 = "    5. amore "
  var expected_line_22 = "    6. mio"
  assert_match(expected_line_21, getline(21))
  assert_match(expected_line_22, getline(22))

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_check_uncheck_todo_keybinding()

  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  setlocal spell spelllang=la

  execute "silent norm! Go\<cr>-\<space>[\<space>]\<space>foo"
  assert_true(getline(line('.')) =~ '^- \[ \] ')
  execute $"silent norm! \<Plug>MarkdownToggleCheck"
  assert_true(getline('.') =~ '- \[x\] ')
  execute $"silent norm! \<Plug>MarkdownToggleCheck"
  assert_true(getline('.') =~ '- \[ \] ')

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

## References
