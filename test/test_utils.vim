vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
import "../lib/constants.vim"
import "../lib/utils.vim"
const WaitForAssert = common.WaitForAssert

const TEXT_STYLES_DICT = constants.TEXT_STYLES_DICT

const CODE_OPEN_DICT = constants.CODE_OPEN_DICT
const CODE_CLOSE_DICT = constants.CODE_CLOSE_DICT
const CODEBLOCK_OPEN_DICT = constants.CODEBLOCK_OPEN_DICT
const CODEBLOCK_CLOSE_DICT = constants.CODEBLOCK_CLOSE_DICT
const ITALIC_OPEN_DICT = constants.ITALIC_OPEN_DICT
const ITALIC_CLOSE_DICT = constants.ITALIC_CLOSE_DICT
const BOLD_OPEN_DICT = constants.BOLD_OPEN_DICT
const BOLD_CLOSE_DICT = constants.BOLD_CLOSE_DICT
const ITALIC_U_OPEN_DICT = constants.ITALIC_U_OPEN_DICT
const ITALIC_U_CLOSE_DICT = constants.ITALIC_U_CLOSE_DICT
const BOLD_U_OPEN_DICT = constants.BOLD_U_OPEN_DICT
const BOLD_U_CLOSE_DICT = constants.BOLD_U_CLOSE_DICT
const STRIKE_OPEN_DICT = constants.STRIKE_OPEN_DICT
const STRIKE_CLOSE_DICT = constants.STRIKE_CLOSE_DICT
const LINK_OPEN_DICT = constants.LINK_OPEN_DICT
const LINK_CLOSE_DICT = constants.LINK_CLOSE_DICT

# SEE :HELP /\@<! AND :HELP /\@!
const CODE_OPEN_REGEX = values(CODE_OPEN_DICT)
const CODE_CLOSE_REGEX = values(CODE_CLOSE_DICT)
const CODEBLOCK_OPEN_REGEX = values(CODEBLOCK_OPEN_DICT)
const CODEBLOCK_CLOSE_REGEX = values(CODEBLOCK_CLOSE_DICT)
const ITALIC_OPEN_REGEX = values(ITALIC_OPEN_DICT)
const ITALIC_CLOSE_REGEX = values(ITALIC_CLOSE_DICT)
const BOLD_OPEN_REGEX = values(BOLD_OPEN_DICT)
const BOLD_CLOSE_REGEX = values(BOLD_CLOSE_DICT)
const ITALIC_U_OPEN_REGEX = values(ITALIC_U_OPEN_DICT)
const ITALIC_U_CLOSE_REGEX = values(ITALIC_U_CLOSE_DICT)
const BOLD_U_OPEN_REGEX = values(BOLD_U_OPEN_DICT)
const BOLD_U_CLOSE_REGEX = values(BOLD_U_CLOSE_DICT)
const STRIKE_OPEN_REGEX = values(STRIKE_OPEN_DICT)
const STRIKE_CLOSE_REGEX = values(STRIKE_CLOSE_DICT)
const LINK_OPEN_REGEX = values(LINK_OPEN_DICT)
const LINK_CLOSE_REGEX = values(LINK_CLOSE_DICT)


# Test file 1
const src_name_1 = 'testfile_1.md'
const lines_1 =<< trim END
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

      Quis autem vel eum __iure reprehenderit qui in ea voluptate velit esse
      quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo
      voluptas nulla__ pariatur?

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
      maiores alias [consequatur][33] aut perferendis doloribus asperiores
      repellat.

      ```
        Itaque earum
        rerum hic tenetur 'a sapiente' delectus, ut aut reiciendis voluptatibus
        maiores alias consequatur aut perferendis doloribus asperiores
        repellat.
      ```
END

# Test file 2
const src_name_2 = 'testfile_2.md'
const lines_2 =<< trim END
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
def g:Test_GetTextBetweenMarks()
  Generate_testfile(lines_1, src_name_1)

  exe $"edit {src_name_1}"

  const A = setcharpos("'A", [0, 4, 32, 0])
  const B = setcharpos("'B", [0, 10, 1, 0])
  const expected_text = ['m voluptatem quia voluptas sit',
    'aspernatur aut odit aut fugit*, sed quia consequuntur magni dolores eos',
    'qui ratione voluptatem sequi nesciunt.', '',
    'Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet,',
    'consectetur, adipisci velit, `sed quia non numquam eius modi tempora', 'i']

  const actual_text = utils.GetTextBetweenMarks("'A", "'B")
  assert_true(expected_text == actual_text)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_GetDelimitersRanges()
  vnew
  Generate_testfile(lines_1, src_name_1)

  exe $"edit {src_name_1}"

  var expected_ranges = [[[0, 9, 31, 0], [0, 12, 19, 0]]]
  var actual_ranges = utils.GetDelimitersRanges(CODE_DICT, CODE_DICT)
  assert_equal(expected_ranges, actual_ranges)

  expected_ranges = [[[0, 3, 20, 0], [0, 3, 28, 0]],
    [[0, 4, 18, 0], [0, 5, 29, 0]]]
  actual_ranges = utils.GetDelimitersRanges(ITALIC_DICT, ITALIC_DICT)
  assert_equal(expected_ranges, actual_ranges)

  expected_ranges = [[[0, 1, 23, 0], [0, 1, 37, 0]],
    [[0, 14, 22, 0], [0, 16, 14, 0]]]
  actual_ranges = utils.GetDelimitersRanges(BOLD_DICT, BOLD_DICT)
  assert_equal(expected_ranges, actual_ranges)

  expected_ranges = [[[0, 12, 33, 0], [0, 12, 66, 0]],
  [[0, 20, 1, 0], [0, 20, 32, 0]],
  [[0, 21, 39, 0], [0, 21, 69, 0]]]
  actual_ranges = utils.GetDelimitersRanges(STRIKETHROUGH_DICT, STRIKETHROUGH_DICT)
  assert_equal(expected_ranges, actual_ranges)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_KeysFromValue()
  const dict = {a: 'foo', b: 'bar', c: 'foo'}
  const expected_value = ['a', 'c']
  const target_value = 'foo'
  const actual_value = utils.KeysFromValue(dict, target_value)
  assert_equal(expected_value, actual_value)
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
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"

  setcharpos("'p", [0, 4, 23, 0])
  setcharpos("'q", [0, 9, 11, 0])

  # Test 1
  cursor(2, 15)
  assert_false(utils.IsBetweenMarks("'p", "'q"))
  cursor(8, 3)
  assert_true(utils.IsBetweenMarks("'p", "'q"))

  # Test 2
  cursor(8, 3)
  setcharpos("'p", [0, 3, 20, 0])
  setcharpos("'q", [0, 3, 28, 0])
  assert_false(utils.IsBetweenMarks("'p", "'q"))

  setcharpos("'p", [0, 4, 18, 0])
  setcharpos("'q", [0, 5, 29, 0])
  assert_false(utils.IsBetweenMarks("'p", "'q"))

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_IsInRange()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  set ft=markdown
  set conceallevel=0

  cursor(1, 27)
  var expected_value = {'markdownBold': [[1, 23], [1, 37]]}
  var range = utils.IsInRange()
  echom assert_equal(expected_value, range)

  cursor(5, 18)
  expected_value = {'markdownItalic': [[4, 18], [5, 29]]}
  range = utils.IsInRange()
  echom assert_equal(expected_value, range)

  # Test singularity: cursor on a delimiter
  cursor(14, 21)
  range = utils.IsInRange()
  echom assert_true(empty(range))

  # Normal Test
  cursor(14, 25)
  expected_value = {'markdownBoldU': [[14, 22], [16, 14]]}
  range = utils.IsInRange()
  echom assert_equal(expected_value, range)

  # End of paragraph with no delimiter
  cursor(21, 43)
  expected_value = {'markdownStrike': [[21, 39], [23, 1]]}
  range = utils.IsInRange()
  echom assert_equal(expected_value, range)

  cursor(24, 10)
  expected_value = {}
  range = utils.IsInRange()
  echom assert_equal(expected_value, range)

  cursor(31, 18)
  expected_value = {'markdownLinkText': [[31, 16], [31, 26]]}
  range = utils.IsInRange()
  echom assert_equal(expected_value, range)

  # :%bw!
  # Cleanup_testfile(src_name_1)
enddef

def g:Test_GetTextObject()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"

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

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_DeleteTextBetweenMarks()
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"

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
  Cleanup_testfile(src_name_1)
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

def g:Test_Dict2ListOfDicts()
  var MY_DICT = {a: 'foo', b: 'bar', c: 'baz'}
  var expected_value = [{a: 'foo'}, {b: 'bar'}, {c: 'baz'}]
  var actual_value = utils.DictToListOfDicts(MY_DICT)
  assert_equal(expected_value, actual_value)
enddef


def g:Test_SurroundSimple_one_line()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal conceallevel=0

  # Smart delimiters
  var expected_value = [
      'incidunt ut (labore et ~~dolore magnam) aliquam quaerat~~ voluptatem. Ut',
      'enim ad `minima *[veniam`, quis no~~strum]* exercitationem~~ ullam corporis',
      'suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur?'
    ]
  cursor(11, 29)
  # The following mimic opfunc when setting "'[" and "']" marks
  setcharpos("'[", [0, 11, 17, 0])
  setcharpos("']", [0, 11, 41, 0])
  utils.SurroundSimple('*', '*', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  var actual_value = getline(10, 12)
  echom assert_equal(expected_value, actual_value)

  cursor(21, 41)
  setcharpos("'[", [0, 21, 14, 0])
  setcharpos("']", [0, 21, 68, 0])
  expected_value = [
    'dolores et quas molestias excepturi sint, obcaecati cupiditate non',
    'pro**vident, **(sim**ilique sunt *in* culpa, `qui` officia *deserunt*)**',
    'mollitia) animi, id est laborum et dolorum fuga.'
  ]
  utils.SurroundSimple('**', '**', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  actual_value = getline(20, 22)
  echom assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_SurroundSimple_multi_line()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal conceallevel=0

  # Simple delimiters
  var expected_value = [
    'Nam libero _tempore, cum soluta nobis est eligendi optio, cumque nihil',
    'impedit, quo minus id, quod',
    'maxime placeat facere possimus, omnis voluptas assumenda est, omnis_'
    ]
  cursor(25, 12)
  setcharpos("'[", [0, 25, 12, 0])
  setcharpos("']", [0, 27, 68, 0])
  utils.SurroundSimple('_', '_', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  var actual_value = getline(25, 27)
  echom assert_equal(expected_value, actual_value)

  expected_value = [
    '__Itaque earum rerum hic *tenetur a sapiente `delectus`, ut aut reiciendis',
    'voluptatibus maiores*',
    'alias consequatur aut perferendis doloribus asperiores repellat.__',
    ]
  cursor(32, 12)
  setcharpos("'[", [0, 32, 1, 0])
  setcharpos("']", [0, 34, 65, 0])
  utils.SurroundSimple('__', '__', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  actual_value = getline(32, 34)
  echom assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_SurroundSmart_one_line()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"

  # Simple test, add code delimiters to 'architecto beatae vitae'
  var expected_value = [
      'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae',
      'ab illo inventore veritatis et quasi `architecto beatae vitae` dicta',
      'sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit'
    ]
  cursor(3, 38)
  setcharpos("'[", [0, 3, 38, 0])
  setcharpos("']", [0, 3, 60, 0])
  utils.SurroundSmart('`', '`', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  var actual_value = getline(2, 4)
  echom assert_equal(expected_value, actual_value)

  # Bold: simple text-object around '(molestias excepturi sint)'
  expected_value = [
    'Quis autem vel eum iure reprehenderit qui in ea **voluptate velit esse**',
    'quam nihil **(molestiae consequatur)**, vel illum qui dolorem eum fugiat quo',
    'voluptas nulla pariatur?',
    ]
  cursor(15, 13)
  setcharpos("'[", [0, 15, 12, 0])
  setcharpos("']", [0, 15, 34, 0])
  utils.SurroundSmart('**', '**', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  # Do the same operation, nothing should change
  utils.SurroundSmart('**', '**', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  actual_value = getline(14, 16)
  echom assert_equal(expected_value, actual_value)

  # Prolong delimiter
  # TODO to check
  expected_value = [
    'Quis autem vel eum iure reprehenderit qui in ea **voluptate velit esse**',
    'quam nihil **(molestiae consequatur), vel** illum qui dolorem eum fugiat quo',
    'voluptas nulla pariatur?',
    ]
  cursor(15, 32)
  setcharpos("'[", [0, 15, 32, 0])
  setcharpos("']", [0, 15, 43, 0])
  utils.SurroundSmart('**', '**', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  actual_value = getline(14, 16)
  echom assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_SurroundSmart_one_line_1()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  # setlocal conceallevel=0

  # Smart delimiters
  var expected_value = [
      'incidunt ut (labore et ~~dolore magnam) aliquam quaerat~~ voluptatem. Ut',
      'enim ad `minima` *[veniam, quis nostrum]* ~~exercitationem~~ ullam corporis',
      'suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur?'
    ]
  cursor(11, 29)
  setcharpos("'[", [0, 11, 17, 0])
  setcharpos("']", [0, 11, 41, 0])
  utils.SurroundSmart('*', '*', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  var actual_value = getline(10, 12)
  echom assert_equal(expected_value, actual_value)

  # Test with junk between A and B. Overwrite everything and avoid consecutive
  # delimiters of same type, like ** **
  cursor(21, 41)
  setcharpos("'[", [0, 21, 14, 0])
  setcharpos("']", [0, 21, 68, 0])
  expected_value = [
    'dolores et quas molestias excepturi sint, obcaecati cupiditate non',
    'pro**vident, (similique sunt in culpa, qui officia deserunt)**',
    'mollitia) animi, id est laborum et dolorum fuga.'
  ]
  utils.SurroundSmart('**', '**', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  actual_value = getline(20, 22)
  echom assert_equal(expected_value, actual_value)

  # Test with junk between A and B. Overwrite everything and avoid consecutive
  # delimiters of same type, like ** **
  cursor(19, 20)
  setcharpos("'[", [0, 19, 16, 0])
  setcharpos("']", [0, 19, 55, 0])
  expected_value = [
    'At vero eos et accusamus et iusto odio dignissimos ducimus, qui',
    'blandit*iis pra(esentium voluptatum deleniti atque) corrupti*, quos',
    'dolores et quas molestias excepturi sint, obcaecati cupiditate non',
  ]
  utils.SurroundSmart('*', '*', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  actual_value = getline(18, 20)
  echom assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_RemoveSurrounding_one_line()

  Generate_testfile(lines_2, src_name_2)
  # vnew
  exe $"edit {src_name_2}"

  cursor(10, 30)
  var expected_value =
    'incidunt ut (labore et dolore magnam) aliquam quaerat voluptatem. Ut'
  utils.RemoveSurrounding(STRIKETHROUGH_DICT, STRIKETHROUGH_DICT)
  var actual_value = getline(10)
  assert_equal(expected_value, actual_value)

  cursor(11, 40)
  expected_value =
    'enim ad `minima [veniam`, quis nostrum] exercitationem ullam corporis'
  utils.RemoveSurrounding(STRIKETHROUGH_DICT, STRIKETHROUGH_DICT)
  actual_value = getline(11)
  assert_equal(expected_value, actual_value)

  cursor(14, 60)
  expected_value =
    'Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse'
  utils.RemoveSurrounding(BOLD_DICT, BOLD_DICT)
  actual_value = getline(14)
  assert_equal(expected_value, actual_value)

  cursor(19, 18)
  utils.RemoveSurrounding(ITALIC_DICT, ITALIC_DICT)
  cursor(19, 30)
  utils.RemoveSurrounding(CODE_DICT, CODE_DICT)
  cursor(19, 47)
  utils.RemoveSurrounding(ITALIC_DICT, ITALIC_DICT)
  expected_value =
    'blanditiis pra(esentium voluptatum deleniti atque) corrupti, quos'
  actual_value = getline(19)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_SurroundSmart_multi_line()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal conceallevel=0

  # Smart delimiters
  var expected_value = [
    'Nam libero tempore, _cum soluta nobis est eligendi optio, cumque nihil',
    'impedit, quo minus id, quod',
    'maxime placeat facere possimus_, omnis voluptas assumenda est, omnis',
    ]
  cursor(25, 21)
  setcharpos("'[", [0, 25, 21, 0])
  setcharpos("']", [0, 27, 30, 0])
  # exe "norm! v27ggt,\<esc>"
  utils.SurroundSmart('_', '_', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  var actual_value = getline(25, 27)
  echom assert_equal(expected_value, actual_value)

  # Smart delimiters
  expected_value = [
    '~~At vero eos et accusamus et iusto odio dignissimos ducimus, qui',
    'blanditiis pra(esentium voluptatum deleniti atque) corrupti, quos~~',
    ]
  cursor(18, 1)
  setcharpos("'[", [0, 18, 1, 0])
  setcharpos("']", [0, 19, 71, 0])
  utils.SurroundSmart('~~', '~~', TEXT_STYLES_DICT, TEXT_STYLES_DICT)
  actual_value = getline(18, 19)
  echom assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_RemoveSurrounding_multi_line()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"

  # Test 1
  var expected_value = [
    'dolor repellend[a]us. Temporibus autem quibusdam et aut officiis',
    'debitis aut rerum necessitatibus saepe eveniet, ut et voluptates',
    'repudiandae sint et molestiae non recusandae.',
    ]
  cursor(28, 25)
  utils.RemoveSurrounding(CODE_DICT, CODE_DICT)
  var actual_value = getline(28, 30)
  assert_equal(expected_value, actual_value)

  # Test 2: preserve inner surrounding
  expected_value = [
    'Itaque earum rerum hic tenetur a sapiente `delectus`, ut aut reiciendis',
    'voluptatibus maiores',
    ]
  cursor(32, 28)
  utils.RemoveSurrounding(ITALIC_DICT, ITALIC_DICT)
  actual_value = getline(32, 33)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef


def g:Test_set_code_block()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"

  g:markdown_extras_config = {}
  g:markdown_extras_config['block_label'] = ''

  var expected_value = [
    '',
    '```',
    '  ab illo inventore veritatis et quasi architecto beatae vitae dicta',
    '  sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit',
    '  aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos',
    '  qui ratione voluptatem sequi nesciunt.',
    '```',
    ''
    ]
  cursor(3, 29)
  setcharpos("'[", [0, 3, 33, 0])
  setcharpos("']", [0, 6, 22, 0])
  utils.SetBlock(CODEBLOCK_DICT, CODEBLOCK_DICT)
  var actual_value = getline(3, 10)
  echom assert_equal(expected_value, actual_value)

  # Check that it won't undo
  cursor(6, 10)
  setcharpos("'[", [0, 5, 21, 0])
  setcharpos("']", [0, 8, 10, 0])
  utils.SetBlock(CODEBLOCK_DICT, CODEBLOCK_DICT)
  echom assert_equal(expected_value, actual_value)

  # Check that it won't undo when on the border
  cursor(4, 2)
  setcharpos("'[", [0, 4, 2, 0])
  setcharpos("']", [0, 5, 10, 0])
  utils.SetBlock(CODEBLOCK_DICT, CODEBLOCK_DICT)
  echom assert_equal(expected_value, actual_value)

  unlet g:markdown_extras_config

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_unset_code_block()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"

  var expected_value = [
    'Itaque earum',
    'rerum hic tenetur ''a sapiente'' delectus, ut aut reiciendis voluptatibus',
    'maiores alias consequatur aut perferendis doloribus asperiores',
    'repellat.'
  ]
  cursor(35, 1)
  utils.UnsetBlock(CODEBLOCK_DICT, CODEBLOCK_DICT)
  var actual_value = getline(34, 37)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef
