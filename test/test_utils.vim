vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
import "../lib/utils.vim"
var WaitForAssert = common.WaitForAssert


var src_name = 'testfile.md'

def Generate_markdown_testfile()
  var lines =<< trim END
        Sed ut perspiciatis **unde omnis iste** natus error sit voluptatem
        accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae
        ab illo inventore *veritatis* et quasi architecto beatae vitae dicta
        sunt explicabo. *Nemo enim ipsam voluptatem quia voluptas sit
        aspernatur aut odit aut fugit*, sed quia consequuntur magni dolores eos
        qui ratione voluptatem sequi nesciunt.

        Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet,
        consectetur, adipisci velit, `sed quia non numquam eius modi tempora
        incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut
        enim ad minima veniam, quis nostrum exercitationem ullam corporis
        suscipit laboriosam`, nisi ut aliquid ex ea commodi consequatur?

        Quis autem vel eum **iure reprehenderit qui in ea voluptate velit esse
        quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo
        voluptas nulla** pariatur?
  END
   writefile(lines, src_name)
enddef

def Cleanup_markdown_testfile()
   delete(src_name)
enddef

# Tests start here
def g:Test_GetTextBetweenMarks()
  Generate_markdown_testfile()

  exe $"edit {src_name}"

  var A = setcharpos("'A", [0, 4, 32, 0])
  var B = setcharpos("'B", [0, 10, 1, 0])
  var expected_text = ['m voluptatem quia voluptas sit',
    'aspernatur aut odit aut fugit*, sed quia consequuntur magni dolores eos',
    'qui ratione voluptatem sequi nesciunt.', '',
    'Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet,',
    'consectetur, adipisci velit, `sed quia non numquam eius modi tempora', 'i']

  var actual_text = utils.GetTextBetweenMarks("'A", "'B")
  assert_true(expected_text == actual_text)

  :%bw!
  Cleanup_markdown_testfile()
enddef

def g:Test_GetDelimitersRanges()
  Generate_markdown_testfile()

  exe $"edit {src_name}"

  var code_regex = '\(^\|[^`]\)\zs`\ze\([^`]\|$\)'
  var expected_ranges = [[[0, 9, 31, 0], [0, 12, 19, 0]]]
  var actual_ranges = utils.GetDelimitersRanges(code_regex, code_regex)
  assert_true(expected_ranges == actual_ranges)

  var italic_regex = '\(^\|[^\*]\)\zs\*\ze\([^\*]\|$\)'
  expected_ranges = [[[0, 3, 20, 0], [0, 3, 28, 0]],
    [[0, 4, 18, 0], [0, 5, 29, 0]]]
  actual_ranges = utils.GetDelimitersRanges(italic_regex, italic_regex)
  assert_true(expected_ranges == actual_ranges)

  var bold_regex = '\(^\|[^\*]\)\zs\*\*\ze\([^\*]\|$\)'
  expected_ranges = [[[0, 1, 23, 0], [0, 1, 37, 0]],
    [[0, 14, 22, 0], [0, 16, 14, 0]]]
  actual_ranges = utils.GetDelimitersRanges(bold_regex, bold_regex)
  assert_true(expected_ranges == actual_ranges)

  :%bw!
  Cleanup_markdown_testfile()
enddef
