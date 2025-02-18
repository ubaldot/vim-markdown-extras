vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
var WaitForAssert = common.WaitForAssert


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
        incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut
        enim ad minima veniam, quis nostrum exercitationem ullam corporis
        suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur?

        Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse
        quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo
        voluptas nulla pariatur?
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

  # quit!
  # edit!


  Cleanup_markdown_testfile()
enddef
