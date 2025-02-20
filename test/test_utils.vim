vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
import "../lib/utils.vim"
var WaitForAssert = common.WaitForAssert

# var code_regex = '\(^\|[^`]\)\zs`\ze\([^`]\|$\)'
# var italic_regex = '\(^\|[^\*]\)\zs\*\ze\([^\*]\|$\)'
# var bold_regex = '\(^\|[^\*]\)\zs\*\*\ze\([^\*]\|$\)'
# var strikethrough_regex = '\(^\|[^\~]\)\zs\~\~\ze\([^\~]\|$\)'

# see :help /\@<! and :help /\@!
var code_regex = '\v`@<!``@!'
var italic_regex = '\v\*@<!\*\*@!'
var bold_regex = '\v\*@<!\*\*\*@!'
var strikethrough_regex = '\v\~@<!\~\~\~@!'

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
        suscipit laboriosam`, nisi ut ~~aliquid ex ea commodi consequatur?~~

        Quis autem vel eum **iure reprehenderit qui in ea voluptate velit esse
        quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo
        voluptas nulla** pariatur?

        At vero eos et accusamus et iusto odio dignissimos ducimus qui
        blanditiis praesentium voluptatum deleniti atque corrupti quos dolores~~
        et quas molestias excepturi sint~~ occaecati cupiditate non provident,
        similique sunt in culpa qui officia ~~deserunt mollitia animi, id est
        ~~laborum et dolorum fuga.

        Et harum quidem rerum facilis est et expedita distinctio. Nam libero
        tempore, cum soluta nobis est (eligendi optio cumque nihil) impedit quo
        minus id quod maxime [placeat facere possimus, omnis] voluptas assumenda
        est, omnis "dolor repellendus". Temporibus autem quibusdam et aut
        officiis debitis aut {rerum necessitatibus} saepe eveniet ut et
        voluptates repudiandae sint et molestiae non recusandae. Itaque earum
        rerum hic tenetur 'a sapiente' delectus, ut aut reiciendis voluptatibus
        maiores alias consequatur aut perferendis doloribus asperiores
        repellat.
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

  var expected_ranges = [[[0, 9, 31, 0], [0, 12, 19, 0]]]
  var actual_ranges = utils.GetDelimitersRanges(code_regex, code_regex)
  assert_equal(expected_ranges, actual_ranges)

  expected_ranges = [[[0, 3, 20, 0], [0, 3, 28, 0]],
    [[0, 4, 18, 0], [0, 5, 29, 0]]]
  actual_ranges = utils.GetDelimitersRanges(italic_regex, italic_regex)
  assert_equal(expected_ranges, actual_ranges)

  expected_ranges = [[[0, 1, 23, 0], [0, 1, 37, 0]],
    [[0, 14, 22, 0], [0, 16, 14, 0]]]
  actual_ranges = utils.GetDelimitersRanges(bold_regex, bold_regex)
  assert_equal(expected_ranges, actual_ranges)

  expected_ranges = [[[0, 12, 33, 0], [0, 12, 66, 0]],
  [[0, 20, 1, 0], [0, 20, 32, 0]],
  [[0, 21, 39, 0], [0, 21, 69, 0]]]
  actual_ranges = utils.GetDelimitersRanges(strikethrough_regex, strikethrough_regex)
  assert_equal(expected_ranges, actual_ranges)

  :%bw!
  Cleanup_markdown_testfile()
enddef

def g:Test_IsBetweenMarks()
  Generate_markdown_testfile()
  exe $"edit {src_name}"

  setpos("'A", [4, 23])
  setpos("'B", [9, 11])

  cursor(2, 15)
  assert_false(utils.IsBetweenMarks("'A", "'B"))

  cursor(8, 3)
  assert_true(utils.IsBetweenMarks("'A", "'B"))

  :%bw!
  Cleanup_markdown_testfile()
enddef

def g:Test_IsInRange()
  Generate_markdown_testfile()
  exe $"edit {src_name}"

  cursor(5, 18)
  var expected_value = [[0, 4, 18, 0], [0, 5, 29, 0]]
  var range = utils.IsInRange(italic_regex, italic_regex)
  assert_equal(expected_value, range)

  range = utils.IsInRange(bold_regex, bold_regex)
  assert_true(empty(range))

  range = utils.IsInRange(code_regex, code_regex)
  assert_true(empty(range))

  range = utils.IsInRange(strikethrough_regex, strikethrough_regex)
  assert_true(empty(range))

  # Test singularity: cursor on a delimiter
  cursor(14, 21)
  range = utils.IsInRange(italic_regex, italic_regex)
  assert_true(empty(range))

  range = utils.IsInRange(bold_regex, bold_regex)
  assert_true(empty(range))

  range = utils.IsInRange(code_regex, code_regex)
  assert_true(empty(range))

  range = utils.IsInRange(strikethrough_regex, strikethrough_regex)
  assert_true(empty(range))

  cursor(21, 43)
  expected_value = [[0, 21, 39, 0], [0, 21, 69, 0]]
  range = utils.IsInRange(strikethrough_regex, strikethrough_regex)
  assert_equal(expected_value, range)

  :%bw!
  Cleanup_markdown_testfile()
enddef

def g:Test_GetTextObject()
  Generate_markdown_testfile()
  exe $"edit {src_name}"

  # test 'iw'
  cursor(1, 8)
  var expected_value = 'perspiciatis'
  var actual_value = utils.GetTextObject('iw')
  assert_equal(expected_value, actual_value)

  # test 'iW'
  actual_value = utils.GetTextObject('iW')
  assert_equal(expected_value, actual_value)

  # test 'aw'
  expected_value = 'perspiciatis '
  actual_value = utils.GetTextObject('aw')
  assert_equal(expected_value, actual_value)

  # test 'aW'
  actual_value = utils.GetTextObject('aW')
  assert_equal(expected_value, actual_value)

  # Test 'i('
  cursor(25, 33)
  expected_value = 'eligendi optio cumque nihil'
  actual_value = utils.GetTextObject('i(')
  assert_equal(expected_value, actual_value)

  # Test 'yib'
  actual_value = utils.GetTextObject('ib')
  assert_equal(expected_value, actual_value)

  # Test 'a('
  expected_value = '(eligendi optio cumque nihil)'
  actual_value = utils.GetTextObject('a(')
  assert_equal(expected_value, actual_value)

  # Test 'ab'
  actual_value = utils.GetTextObject('ab')
  assert_equal(expected_value, actual_value)

  # Test 'i{'
  cursor(28, 25)
  expected_value = 'rerum necessitatibus'
  actual_value = utils.GetTextObject('i{')
  assert_equal(expected_value, actual_value)

  # Test 'a{'
  expected_value = '{rerum necessitatibus}'
  actual_value = utils.GetTextObject('a{')
  assert_equal(expected_value, actual_value)

  # Test quoted text
  # TODO: it does not work due to a bug in vim, see:
  # https://github.com/vim/vim/issues/16679
  # cursor(27, 22)
  # expected_value = {text: 'dolor repellendus',
  #   start_pos: [0, 27, 13, 0],
  #   end_pos: [0, 27, 29, 0]}
  # actual_value = utils.GetTextObject('i"')
  # AssertGetTextObject(expected_value, actual_value)

  :%bw!
  Cleanup_markdown_testfile()
enddef


def g:Test_DeleteTextBetweenMarks()
  Generate_markdown_testfile()
  exe $"edit {src_name}"

  setcharpos("'A", [0, 9, 23, 0])
  setcharpos("'B", [0, 18, 39, 0])

  var expected_value =
    ['Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet,',
      'consectetur, adipisci dignissimos ducimus qui',
    'blanditiis praesentium voluptatum deleniti atque corrupti quos dolores~~']

  utils.DeleteTextBetweenMarks("'A", "'B")
  var actual_value = getline(8, 10)

  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_markdown_testfile()
enddef

def g:Test_ZipList()

  var list_a = [1, 2, 3, 4]
  var list_b = [4, 3, 2, 1]
  var expected_value = [[1, 4], [2, 3], [3, 2], [4, 1]]
  var actual_value = utils.ZipLists(list_a, list_b)
  assert_equal(expected_value, actual_value)

  # Test with different lengths
  add(list_b, 0)
  actual_value = utils.ZipLists(list_a, list_b)
  assert_equal(expected_value, actual_value)

enddef
