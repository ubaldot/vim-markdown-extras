vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
import "../lib/utils.vim"
import "../after/ftplugin/markdown.vim"
var WaitForAssert = common.WaitForAssert

var code_dict = markdown.code_dict
var italic_dict = markdown.italic_dict
var bold_dict = markdown.bold_dict
var strikethrough_dict = markdown.strikethrough_dict

# see :help /\@<! and :help /\@!
var code_regex = values(code_dict)
var italic_regex = values(italic_dict)
var bold_regex = values(bold_dict)
var strikethrough_regex = values(strikethrough_dict)

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
  var actual_ranges = utils.GetDelimitersRanges(code_dict, code_dict)
  assert_equal(expected_ranges, actual_ranges)

  expected_ranges = [[[0, 3, 20, 0], [0, 3, 28, 0]],
    [[0, 4, 18, 0], [0, 5, 29, 0]]]
  actual_ranges = utils.GetDelimitersRanges(italic_dict, italic_dict)
  assert_equal(expected_ranges, actual_ranges)

  expected_ranges = [[[0, 1, 23, 0], [0, 1, 37, 0]],
    [[0, 14, 22, 0], [0, 16, 14, 0]]]
  actual_ranges = utils.GetDelimitersRanges(bold_dict, bold_dict)
  assert_equal(expected_ranges, actual_ranges)

  expected_ranges = [[[0, 12, 33, 0], [0, 12, 66, 0]],
  [[0, 20, 1, 0], [0, 20, 32, 0]],
  [[0, 21, 39, 0], [0, 21, 69, 0]]]
  actual_ranges = utils.GetDelimitersRanges(strikethrough_dict, strikethrough_dict)
  assert_equal(expected_ranges, actual_ranges)

  :%bw!
  Cleanup_markdown_testfile()
enddef

def g:Test_ListComparison()
  var A = [5, 19, 22]
  var B = [3, 43]
  assert_true(utils.IsGreater(A, B))
  assert_false(utils.IsLess(A, B))
  assert_false(utils.IsEqual(A, B))

  A = [3, 48]
  B = [3, 21, 33]
  assert_true(utils.IsGreater(A, B))
  assert_false(utils.IsLess(A, B))
  assert_false(utils.IsEqual(A, B))

  # Equality
  A = [3, 48, 29]
  B = [3, 48]
  assert_false(utils.IsGreater(A, B))
  assert_false(utils.IsLess(A, B))
  assert_true(utils.IsEqual(A, B))

enddef

def g:Test_IsBetweenMarks()
  Generate_markdown_testfile()
  exe $"edit {src_name}"

  setcharpos("'p", [0, 4, 23, 0])
  setcharpos("'q", [0, 9, 11, 0])

  # Test 1
  cursor(2, 15)
  echom assert_false(utils.IsBetweenMarks("'p", "'q"))
  cursor(8, 3)
  echom assert_true(utils.IsBetweenMarks("'p", "'q"))

  # Test 2
  cursor(8, 3)
  setcharpos("'p", [0, 3, 20, 0])
  setcharpos("'q", [0, 3, 28, 0])
  echom assert_false(utils.IsBetweenMarks("'p", "'q"))

  setcharpos("'p", [0, 4, 18, 0])
  setcharpos("'q", [0, 5, 29, 0])
  echom assert_false(utils.IsBetweenMarks("'p", "'q"))

  :%bw!
  Cleanup_markdown_testfile()
enddef

def g:Test_IsInRange()
  Generate_markdown_testfile()
  exe $"edit {src_name}"

  cursor(5, 18)
  var expected_value = [[0, 4, 18, 0], [0, 5, 29, 0]]
  var range = utils.IsInRange(italic_dict, italic_dict)
  assert_equal(expected_value, range)

  range = utils.IsInRange(bold_dict, bold_dict)
  assert_true(empty(range))

  range = utils.IsInRange(code_dict, code_dict)
  assert_true(empty(range))

  range = utils.IsInRange(strikethrough_dict, strikethrough_dict)
  assert_true(empty(range))

  # Test singularity: cursor on a delimiter
  cursor(14, 21)
  range = utils.IsInRange(italic_dict, italic_dict)
  assert_true(empty(range))

  range = utils.IsInRange(bold_dict, bold_dict)
  assert_true(empty(range))

  range = utils.IsInRange(code_dict, code_dict)
  assert_true(empty(range))

  range = utils.IsInRange(strikethrough_dict, strikethrough_dict)
  assert_true(empty(range))

  cursor(21, 43)
  expected_value = [[0, 21, 39, 0], [0, 21, 69, 0]]
  range = utils.IsInRange(strikethrough_dict, strikethrough_dict)
  assert_equal(expected_value, range)

  :%bw!
  Cleanup_markdown_testfile()
enddef

def g:Test_GetTextObject()
  vnew
  Generate_markdown_testfile()
  exe $"edit {src_name}"

  # test 'iw'
  cursor(1, 8)
  var expected_value = {text: 'perspiciatis',
  start: [0, 1, 8, 0],
  end: [0, 1, 19, 0],
  }

  var actual_value = utils.GetTextObject('iw')
  assert_equal(expected_value, actual_value)

  # test 'iW'
  actual_value = utils.GetTextObject('iW')
  assert_equal(expected_value, actual_value)

  # # test 'aw'
  expected_value = {text: 'perspiciatis ',
  start: [0, 1, 8, 0],
  end: [0, 1, 20, 0],
  }
  actual_value = utils.GetTextObject('aw')
  assert_equal(expected_value, actual_value)

  # # test 'aW'
  actual_value = utils.GetTextObject('aW')
  assert_equal(expected_value, actual_value)

  # # Test 'i('
  cursor(25, 33)
  expected_value = {text: 'eligendi optio cumque nihil',
  start: [0, 25, 32, 0],
  end: [0, 25, 58, 0],
  }
  actual_value = utils.GetTextObject('i(')
  assert_equal(expected_value, actual_value)

  # # Test 'yib'
  actual_value = utils.GetTextObject('ib')
  assert_equal(expected_value, actual_value)

  # # Test 'a('
  expected_value = {text: '(eligendi optio cumque nihil)',
  start: [0, 25, 31, 0],
  end: [0, 25, 59, 0],
  }
  actual_value = utils.GetTextObject('a(')
  assert_equal(expected_value, actual_value)

  # # Test 'ab'
  actual_value = utils.GetTextObject('ab')
  assert_equal(expected_value, actual_value)

  # # Test 'i{'
  cursor(28, 25)
  expected_value = {text: 'rerum necessitatibus',
  start: [0, 28, 23, 0],
  end: [0, 28, 42, 0],
  }
  actual_value = utils.GetTextObject('i{')
  assert_equal(expected_value, actual_value)

  # # Test 'a{'
  expected_value = {text: '{rerum necessitatibus}',
  start: [0, 28, 22, 0],
  end: [0, 28, 43, 0],
  }
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

  # :%bw!
  # Cleanup_markdown_testfile()
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

def g:Test_RegexList2RegexOR()
    var A = '\v(\d+|\a)\s'
    var B = '\v^\s*\w\d*\w'
    var C = '\v\w*\d+\w'
    var test_list = [A, B, C]

    var expected_string = '\v((\d+|\a)\s|^\s*\w\d*\w|\w*\d+\w)'
    var actual_string = utils.RegexList2RegexOR(test_list, true)
    assert_equal(expected_string, actual_string)

    A = '\(\d\+\|\a\)\s'
    B = '^\s*\w\d*\w'
    C = '\w*\d\+\w'
    test_list = [A, B, C]

    expected_string = '\(\(\d\+\|\a\)\s\|^\s*\w\d*\w\|\w*\d\+\w\)'
    actual_string = utils.RegexList2RegexOR(test_list)
    assert_equal(expected_string, actual_string)
enddef

def g:Test_Dict2ListOfDicts()

  var my_dict = {a: 'foo', b: 'bar', c: 'baz'}
  var expected_value = [{a: 'foo'}, {b: 'bar'}, {c: 'baz'}]
  var actual_value = utils.DictToListOfDicts(my_dict)
  assert_equal(expected_value, actual_value)

enddef
