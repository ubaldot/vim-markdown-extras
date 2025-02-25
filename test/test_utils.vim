vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
import "../lib/utils.vim"
import "../after/ftplugin/markdown.vim"
var WaitForAssert = common.WaitForAssert

var text_style_dict = markdown.text_style_dict

var code_dict = markdown.code_dict
var codeblock_dict = markdown.codeblock_dict
var italic_dict = markdown.italic_dict
var bold_dict = markdown.bold_dict
var italic_dict_u = markdown.italic_dict_u
var bold_dict_u = markdown.bold_dict_u
var strikethrough_dict = markdown.strikethrough_dict

# see :help /\@<! and :help /\@!
var code_regex = values(code_dict)
var codeblock_regex = values(codeblock_dict)
var italic_regex = values(italic_dict)
var bold_regex = values(bold_dict)
var italic_regex_u = values(italic_dict_u)
var bold_regex_u = values(bold_dict_u)
var strikethrough_regex = values(strikethrough_dict)


# Test file 1
var src_name_1 = 'testfile_1.md'
var lines_1 =<< trim END
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

      ```
        Itaque earum
        rerum hic tenetur 'a sapiente' delectus, ut aut reiciendis voluptatibus
        maiores alias consequatur aut perferendis doloribus asperiores
        repellat.
      ```
END

# Test file 2
var src_name_2 = 'testfile_2.md'
var lines_2 =<< trim END
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
  Cleanup_testfile(src_name_1)
enddef

def g:Test_GetDelimitersRanges()
  Generate_testfile(lines_1, src_name_1)

  exe $"edit {src_name_1}"

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
  Cleanup_testfile(src_name_1)
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
  Cleanup_testfile(src_name_1)
enddef

def g:Test_IsInRange()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"

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

  cursor(36, 4)
  expected_value = [[0, 35, 1, 0], [0, 38, 11, 0]]
  range = utils.IsInRange(codeblock_dict, codeblock_dict)
  assert_equal(expected_value, range)

  cursor(24, 10)
  expected_value = []
  range = utils.IsInRange(codeblock_dict, codeblock_dict)
  assert_equal(expected_value, range)

  :%bw!
  Cleanup_testfile(src_name_1)
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
  var my_dict = {a: 'foo', b: 'bar', c: 'baz'}
  var expected_value = [{a: 'foo'}, {b: 'bar'}, {c: 'baz'}]
  var actual_value = utils.DictToListOfDicts(my_dict)
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
  exe "norm! va[\<esc>"
  utils.SurroundSimple('*', '*', text_style_dict, text_style_dict)
  var actual_value = getline(10, 12)
  assert_equal(expected_value, actual_value)

  # # Test with junk between A and B. Overwrite everything and avoid consecutive
  # # delimiters of same type, like ** **
  # exe $"edit! {src_name_2}"
  cursor(21, 41)
  exe "norm! va(\<esc>"
  expected_value = [
    'dolores et quas molestias excepturi sint, obcaecati cupiditate non',
    'pro**vident, **(sim**ilique sunt *in* culpa, `qui` officia *deserunt*)**',
    'mollitia) animi, id est laborum et dolorum fuga.'
  ]
  utils.SurroundSimple('**', '**', text_style_dict, text_style_dict)
  actual_value = getline(20, 22)
  assert_equal(expected_value, actual_value)

  cursor(19, 53)
  utils.SurroundSimple('*', '*', text_style_dict, text_style_dict, 'iw')
  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_SurroundSimple_multi_line()
  # vnew
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
  exe "norm! vjj$\<esc>"
  utils.SurroundSimple('_', '_', text_style_dict, text_style_dict)
  var actual_value = getline(25, 27)
  assert_equal(expected_value, actual_value)

  expected_value = [
    '__Itaque earum rerum hic *tenetur a sapiente `delectus`, ut aut reiciendis',
    'voluptatibus maiores*',
    'alias consequatur aut perferendis doloribus asperiores repellat.__',
    ]
  cursor(32, 12)
  exe "norm! 0vG$\<esc>"
  utils.SurroundSimple('__', '__', text_style_dict, text_style_dict)
  actual_value = getline(32, 34)
  assert_equal(expected_value, actual_value)

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
  exe "norm! veee\<esc>"
  utils.SurroundSmart('`', '`', text_style_dict, text_style_dict)
  var actual_value = getline(2, 4)
  assert_equal(expected_value, actual_value)

  # Bold: simple text-object around '(molestias excepturi sint)'
  expected_value = [
    'Quis autem vel eum iure reprehenderit qui in ea **voluptate velit esse**',
    'quam nihil **(molestiae consequatur)**, vel illum qui dolorem eum fugiat quo',
    'voluptas nulla pariatur?',
    ]
  cursor(15, 13)
  utils.SurroundSmart('**', '**', text_style_dict, text_style_dict, 'a(')
  # Do the same operation, nothing should change
  utils.SurroundSmart('**', '**', text_style_dict, text_style_dict, 'a(')
  actual_value = getline(14, 16)
  assert_equal(expected_value, actual_value)

  # Prolong delimiter
  expected_value = [
    'Quis autem vel eum iure reprehenderit qui in ea **voluptate velit esse**',
    'quam nihil **(molestiae consequatur), vel** illum qui dolorem eum fugiat quo',
    'voluptas nulla pariatur?',
    ]
  cursor(15, 32)
  exe "norm! veee\<esc>"
  utils.SurroundSmart('**', '**', text_style_dict, text_style_dict)
  actual_value = getline(14, 16)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_SurroundSmart_one_line_1()
  # vnew
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
  exe "norm! va[\<esc>"
  utils.SurroundSmart('*', '*', text_style_dict, text_style_dict)
  var actual_value = getline(10, 12)
  assert_equal(expected_value, actual_value)

  # Test with junk between A and B. Overwrite everything and avoid consecutive
  # delimiters of same type, like ** **
  cursor(21, 41)
  exe "norm! va(\<esc>"
  expected_value = [
    'dolores et quas molestias excepturi sint, obcaecati cupiditate non',
    'pro**vident, (similique sunt in culpa, qui officia deserunt)**',
    'mollitia) animi, id est laborum et dolorum fuga.'
  ]
  utils.SurroundSmart('**', '**', text_style_dict, text_style_dict)
  actual_value = getline(20, 22)
  assert_equal(expected_value, actual_value)

  # Test with junk between A and B. Overwrite everything and avoid consecutive
  # delimiters of same type, like ** **
  cursor(19, 20)
  exe "norm! va(\<esc>"
  expected_value = [
    'At vero eos et accusamus et iusto odio dignissimos ducimus, qui',
    'blandit*iis pra(esentium voluptatum deleniti atque) corrupti*, quos',
    'dolores et quas molestias excepturi sint, obcaecati cupiditate non',
  ]
  utils.SurroundSmart('*', '*', text_style_dict, text_style_dict)
  actual_value = getline(18, 20)
  assert_equal(expected_value, actual_value)

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
  utils.RemoveSurrounding(strikethrough_dict, strikethrough_dict)
  var actual_value = getline(10)
  assert_equal(expected_value, actual_value)

  cursor(11, 40)
  expected_value =
    'enim ad `minima [veniam`, quis nostrum] exercitationem ullam corporis'
  utils.RemoveSurrounding(strikethrough_dict, strikethrough_dict)
  actual_value = getline(11)
  assert_equal(expected_value, actual_value)

  cursor(14, 60)
  expected_value =
    'Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse'
  utils.RemoveSurrounding(bold_dict, bold_dict)
  actual_value = getline(14)
  assert_equal(expected_value, actual_value)

  cursor(19, 18)
  utils.RemoveSurrounding(italic_dict, italic_dict)
  cursor(19, 30)
  utils.RemoveSurrounding(code_dict, code_dict)
  cursor(19, 47)
  utils.RemoveSurrounding(italic_dict, italic_dict)
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
    'maxime placeat facere possimu_, omnis voluptas assumenda est, omnis',
    ]
  cursor(25, 21)
  exe "norm! v27ggt,\<esc>"
  utils.SurroundSmart('_', '_', text_style_dict, text_style_dict)
  var actual_value = getline(25, 27)
  assert_equal(expected_value, actual_value)

  # Smart delimiters
  expected_value = [
    '~~At vero eos et accusamus et iusto odio dignissimos ducimus, qui',
    'blanditiis pra(esentium voluptatum deleniti atque) corrupti, quos~~',
    ]
  cursor(18, 1)
  exe "norm! 0vj$\<esc>"
  utils.SurroundSmart('~~', '~~', text_style_dict, text_style_dict)
  actual_value = getline(18, 19)
  assert_equal(expected_value, actual_value)

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
  utils.RemoveSurrounding(code_dict, code_dict)
  var actual_value = getline(28, 30)
  assert_equal(expected_value, actual_value)

  # Test 2: preserve inner surrounding
  expected_value = [
    'Itaque earum rerum hic tenetur a sapiente `delectus`, ut aut reiciendis',
    'voluptatibus maiores',
    ]
  cursor(32, 28)
  utils.RemoveSurrounding(italic_dict, italic_dict)
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
    'ab illo inventore veritatis ',
    '```',
    '  et quasi architecto beatae vitae dicta',
    '  sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit',
    '  aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos',
    '  qui ratione voluptatem sequi ',
    '```',
    'nesciunt.',
    ]
  cursor(3, 29)
  exe "norm! v3j\<esc>"
  utils.SetBlock(codeblock_dict, codeblock_dict)
  var actual_value = getline(3, 10)
  assert_equal(expected_value, actual_value)

  # Check that it won't undo
  cursor(6, 10)
  utils.SetBlock(codeblock_dict, codeblock_dict)
  assert_equal(expected_value, actual_value)

  # Check that it won't undo when on the border
  cursor(4, 2)
  utils.SetBlock(codeblock_dict, codeblock_dict)
  assert_equal(expected_value, actual_value)

  # check with motion
  expected_value = [
    '```',
    '  Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet,',
    '  consectetur, adipisci velit, sed quia non numquam eius modi tempora',
    '  incidunt ut (labore et ~~dolore magnam) aliquam quaerat~~ voluptatem. Ut',
    '  enim ad `minima [veniam`, quis no~~strum] exercitationem~~ ullam corporis',
    '```',
    ]
  cursor(12, 1)
  utils.SetBlock(codeblock_dict, codeblock_dict, '3j')
  actual_value = getline(13, 18)
  assert_equal(expected_value, actual_value)

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
  utils.UnsetBlock(codeblock_dict, codeblock_dict)
  var actual_value = getline(34, 37)
  assert_equal(expected_value, actual_value)

  # :%bw!
  # Cleanup_testfile(src_name_1)
enddef
