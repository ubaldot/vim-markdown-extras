vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
import "./../after/ftplugin/markdown.vim"
import "./../lib/utils.vim"

var WaitForAssert = common.WaitForAssert
var text_style_dict = markdown.text_style_dict


var src_name = 'testfile.md'

def Generate_markdown_testfile()
  var lines =<< trim END
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
        blanditiis praesentium voluptatum deleniti atque corrupti, quos
        dolores et quas molestias excepturi sint, obcaecati cupiditate non
        provident, similique sunt in culpa, qui officia deserunt mollitia
        animi, id est laborum et dolorum fuga. Et harum quidem reru[d]um
        facilis est e[r]t expedita distinctio.

        Nam libero tempore, cum soluta nobis est eligendi optio, cumque nihil
        impedit, quo minus id, quod
        maxime placeat facere possimus, omnis voluptas assumenda est, omnis
        dolor repellend[a]us. Temporibus autem quibusdam et aut officiis
        debitis aut rerum necessitatibus saepe eveniet, ut et voluptates
        repudiandae sint et molestiae non recusandae.

        Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis
        voluptatibus maiores
        alias consequatur aut perferendis doloribus asperiores repellat.
  END
   writefile(lines, src_name)
enddef

def Cleanup_markdown_testfile()
   delete(src_name)
enddef

# Tests start here
def g:Test_markdown_lists()
  Generate_markdown_testfile()

  exe $"edit {src_name}"
  exe "set filetype=md"

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

  # redraw!
  # sleep 3
  :%bw!
  Cleanup_markdown_testfile()
enddef


def g:Test_check_uncheck_todo_keybinding()
  Generate_markdown_testfile()

  exe $"edit {src_name}"
  exe "set filetype=md"

  execute "silent norm! Go\<cr>-\<space>[\<space>]\<space>foo"
  echom assert_true(getline(line('.')) =~ '^- \[ \] ')
  execute $"silent norm! \<Plug>MarkdownToggleCheck"
  echom assert_true(getline('.') =~ '- \[x\] ')
  execute $"silent norm! \<Plug>MarkdownToggleCheck"
  echom assert_true(getline('.') =~ '- \[ \] ')

  :%bw!
  Cleanup_markdown_testfile()

enddef

def g:Test_Surround_one_line()
  vnew
  Generate_markdown_testfile()
  exe $"edit {src_name}"

  # Simple test, add code delimiters to 'architecto beatae vitae'
  var expected_value = [
      'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae',
      'ab illo inventore veritatis et quasi `architecto beatae vitae` dicta',
      'sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit'
    ]
  cursor(3, 38)
  exe "norm! veee\<esc>"
  utils.Surround('`', '`', text_style_dict, text_style_dict)
  var actual_value = getline(2, 4)
  assert_equal(expected_value, actual_value)

  # Bold: simple text-object around '(molestias excepturi sint)'
  expected_value = [
    'Quis autem vel eum iure reprehenderit qui in ea **voluptate velit esse**',
    'quam nihil **(molestiae consequatur)**, vel illum qui dolorem eum fugiat quo',
    'voluptas nulla pariatur?',
    ]
  cursor(15, 13)
  utils.Surround('**', '**', text_style_dict, text_style_dict, 'a(')
  actual_value = getline(14, 16)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_markdown_testfile()
enddef

def g:Test_Surround_one_line_smart_delimiters()
  vnew
  Generate_markdown_testfile()
  exe $"edit {src_name}"

  # Smart delimiters
  var expected_value = [
      'incidunt ut (labore et ~~dolore magnam) aliquam quaerat~~ voluptatem. Ut',
      'enim ad `minima` *[veniam, quis nostrum]* ~~exercitationem~~ ullam corporis',
      'suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur?'
    ]
  cursor(11, 29)
  exe "norm! va[\<esc>"
  utils.Surround('*', '*', text_style_dict, text_style_dict)
  var actual_value = getline(10, 12)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_markdown_testfile()
enddef
