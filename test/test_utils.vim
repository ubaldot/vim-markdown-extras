vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
import "../autoload/mde_constants.vim" as constants
import "../autoload/mde_utils.vim" as utils
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
      Sed ut perspiciatis **unde omnis iste**,natus error sit voluptatem
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
      voluptas nulla__,pariatur?

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

        > Itaque earum rerum hic *tenetur a sapiente `delectus`, ut aut reiciendis
            > voluptatibus maiores*
       > alias consequatur aut perferendis doloribus asperiores repellat.
END

const src_name_multibyte = 'multibyte_test.md'
const lines_multibyte =<< trim END
当然，这里有一段简短的中文文本：

学习 Vim 是一项非常有趣的挑战。虽然一开始可能感觉有些困难，但只要坚持练习，
就能够逐渐掌握它强大的功能，并大幅提高编辑效率。

需要**某种特定风格或主题**（比如技术、文学、对话等）吗？

学习 Vim 是一项_非常有趣的挑战。虽然一开始可能感觉有些困难，但只要坚持练习，
就能够逐渐掌握它强大_的功能，并大幅提高编辑效率。

学习 Vim 是一项非常~~有趣的挑战。虽然一开始可能感觉有些困难，但只要坚持练习，
就能够逐渐掌握它强大的功能，并大幅提高编辑效率。

学习 Vim 是一项非常有趣的挑战。虽然一开始可能感觉有些困难，但只要坚持练习，
就能够逐渐掌握它强大的功能，并大幅提高编辑效率。
END

def Generate_testfile(lines: list<string>, src_name: string)
   writefile(lines, src_name)
enddef

def Cleanup_testfile(src_name: string)
   delete(src_name)
enddef

# Tests start here
def g:Test_list_comparison()
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

def g:Test_IsInRange()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  setlocal conceallevel=0
  setlocal spell spelllang=la

  cursor(1, 27)
  var expected_value = {'markdownBold': [[1, 23], [1, 37]]}
  var range = utils.IsInRange()
  assert_equal(expected_value, range)

  # On the border
  cursor(1, 37)
  range = utils.IsInRange()
  assert_equal(expected_value, range)

  # # On the delimiter
  cursor(1, 38)
  expected_value = {}
  range = utils.IsInRange()
  assert_equal(expected_value, range)

  cursor(5, 18)
  expected_value = {'markdownItalic': [[4, 18], [5, 29]]}
  range = utils.IsInRange()
  assert_equal(expected_value, range)

  # # Test singularity: cursor on a delimiter
  cursor(14, 21)
  range = utils.IsInRange()
  assert_true(empty(range))

  # # Normal Test
  cursor(14, 25)
  expected_value = {'markdownBoldU': [[14, 22], [16, 14]]}
  range = utils.IsInRange()
  assert_equal(expected_value, range)

  # # End of paragraph with no delimiter
  cursor(21, 43)
  expected_value = {'markdownStrike': [[21, 39], [22, 26]]}
  range = utils.IsInRange()
  assert_equal(expected_value, range)

  cursor(24, 10)
  expected_value = {}
  range = utils.IsInRange()
  assert_equal(expected_value, range)

  cursor(31, 18)
  expected_value = {'markdownLinkText': [[31, 16], [31, 26]]}
  range = utils.IsInRange()
  assert_equal(expected_value, range)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_surround_simple_one_line()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal conceallevel=0
  setlocal spell spelllang=la

  var expected_value = [
      'incidunt ut (labore et ~~dolore magnam) aliquam quaerat~~ voluptatem. Ut',
      'enim ad `minima *[veniam`, quis no~~strum]* exercitationem~~ ullam corporis',
      'suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur?'
    ]
  cursor(11, 29)
  # The following mimic opfunc when setting "'[" and "']" marks
  setcharpos("'[", [0, 11, 17, 0])
  setcharpos("']", [0, 11, 41, 0])
  utils.SurroundSimple('markdownItalic')
  var actual_value = getline(10, 12)
  assert_equal(expected_value, actual_value)

  cursor(21, 41)
  setcharpos("'[", [0, 21, 14, 0])
  setcharpos("']", [0, 21, 68, 0])
  expected_value = [
    'dolores et quas molestias excepturi sint, obcaecati cupiditate non',
    'pro**vident, **(sim**ilique sunt *in* culpa, `qui` officia *deserunt*)**',
    'mollitia) animi, id est laborum et dolorum fuga.'
  ]
  utils.SurroundSimple('markdownBold')
  actual_value = getline(20, 22)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_surround_simple_multi_line()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal conceallevel=0
  setlocal spell spelllang=la

  # Simple delimiters
  var expected_value = [
    'Nam libero _tempore, cum soluta nobis est eligendi optio, cumque nihil',
    'impedit, quo minus id, quod',
    'maxime placeat facere possimus, omnis voluptas assumenda est, omnis_'
    ]
  cursor(25, 12)
  setcharpos("'[", [0, 25, 12, 0])
  setcharpos("']", [0, 27, 68, 0])
  utils.SurroundSimple('markdownItalicU')
  var actual_value = getline(25, 27)
  assert_equal(expected_value, actual_value)

  expected_value = [
    '__Itaque earum rerum hic *tenetur a sapiente `delectus`, ut aut reiciendis',
    'voluptatibus maiores*',
    'alias consequatur aut perferendis doloribus asperiores repellat.__',
    ]
  cursor(32, 12)
  setcharpos("'[", [0, 32, 1, 0])
  setcharpos("']", [0, 34, 65, 0])
  utils.SurroundSimple('markdownBoldU')
  actual_value = getline(32, 34)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_surround_smart_one_line()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal spell spelllang=la

  # Simple test, add code delimiters to 'architecto beatae vitae'
  var expected_value = [
      'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae',
      'ab illo inventore veritatis et quasi `architecto beatae vitae` dicta',
      'sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit'
    ]
  cursor(3, 38)
  setcharpos("'[", [0, 3, 38, 0])
  setcharpos("']", [0, 3, 60, 0])
  utils.SurroundSmart('markdownCode')
  var actual_value = getline(2, 4)
  assert_equal(expected_value, actual_value)

  # Bold: simple text-object around '(molestias excepturi sint)'
  expected_value = [
    'Quis autem vel eum iure reprehenderit qui in ea **voluptate velit esse**',
    'quam nihil **(molestiae consequatur)**, vel illum qui dolorem eum fugiat quo',
    'voluptas nulla pariatur?',
    ]
  cursor(15, 13)
  setcharpos("'[", [0, 15, 12, 0])
  setcharpos("']", [0, 15, 34, 0])
  utils.SurroundSmart('markdownBold')
  # Do the same operation, nothing should change
  utils.SurroundSmart('markdownBold')
  utils.SurroundSmart('markdownBold')
  actual_value = getline(14, 16)
  assert_equal(expected_value, actual_value)

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
  utils.SurroundSmart('markdownBold')
  actual_value = getline(14, 16)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_surround_smart_one_line_1()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal conceallevel=0
  setlocal spell spelllang=la

  # Smart delimiters
  var expected_value = [
      'incidunt ut (labore et ~~dolore magnam) aliquam quaerat~~ voluptatem. Ut',
      'enim ad `minima` *[veniam, quis nostrum]* ~~exercitationem~~ ullam corporis',
      'suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur?'
    ]
  cursor(11, 29)
  setcharpos("'[", [0, 11, 17, 0])
  setcharpos("']", [0, 11, 41, 0])
  utils.SurroundSmart('markdownItalic')
  var actual_value = getline(10, 12)
  assert_equal(expected_value, actual_value)

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
  utils.SurroundSmart('markdownBold')
  actual_value = getline(20, 22)
  assert_equal(expected_value, actual_value)

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
  utils.SurroundSmart('markdownItalic')
  actual_value = getline(18, 20)
  assert_equal(expected_value, actual_value)

  # Test underline, quick and dirty
  expected_value = [
    'alias consequatur aut <u>perferendis</u> doloribus asperiores repellat.'
  ]
  cursor(34, 26)
  setcharpos("'[", [0, 34, 23, 0])
  setcharpos("']", [0, 34, 33, 0])
  utils.SurroundSmart('markdownUnderline')
  actual_value = [getline(34)]
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_remove_surrounding_one_line()
  Generate_testfile(lines_2, src_name_2)
  vnew
  exe $"edit {src_name_2}"
  setlocal spell spelllang=la

  cursor(10, 30)
  var expected_value =
    'incidunt ut (labore et dolore magnam) aliquam quaerat voluptatem. Ut'
  utils.RemoveSurrounding()
  var actual_value = getline(10)
  assert_equal(expected_value, actual_value)

  cursor(11, 40)
  expected_value =
    'enim ad `minima [veniam`, quis nostrum] exercitationem ullam corporis'
  utils.RemoveSurrounding()
  actual_value = getline(11)
  assert_equal(expected_value, actual_value)

  cursor(14, 60)
  expected_value =
    'Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse'
  utils.RemoveSurrounding()
  actual_value = getline(14)
  assert_equal(expected_value, actual_value)

  cursor(19, 18)
  utils.RemoveSurrounding()
  cursor(19, 30)
  utils.RemoveSurrounding()
  cursor(19, 47)
  utils.RemoveSurrounding()
  expected_value =
    'blanditiis pra(esentium voluptatum deleniti atque) corrupti, quos'
  actual_value = getline(19)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_surround_smart_multi_line()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal conceallevel=0
  setlocal spell spelllang=la

  # Smart delimiters
  var expected_value = [
    'Nam libero tempore, _cum soluta nobis est eligendi optio, cumque nihil',
    'impedit, quo minus id, quod',
    'maxime placeat facere possimus_, omnis voluptas assumenda est, omnis',
    ]
  cursor(25, 21)
  setcharpos("'[", [0, 25, 21, 0])
  setcharpos("']", [0, 27, 30, 0])
  utils.SurroundSmart('markdownItalicU')
  var actual_value = getline(25, 27)
  assert_equal(expected_value, actual_value)

  # Smart delimiters
  expected_value = [
    '~~At vero eos et accusamus et iusto odio dignissimos ducimus, qui',
    'blanditiis pra(esentium voluptatum deleniti atque) corrupti, quos~~',
    ]
  cursor(18, 1)
  setcharpos("'[", [0, 18, 1, 0])
  setcharpos("']", [0, 19, 71, 0])
  utils.SurroundSmart('markdownStrike')
  actual_value = getline(18, 19)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_remove_surrounding_multi_line()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  set conceallevel=0
  setlocal spell spelllang=la

  # Test 1
  var expected_value = [
    'dolor repellend[a]us. Temporibus autem quibusdam et aut officiis',
    'debitis aut rerum necessitatibus saepe eveniet, ut et voluptates',
    'repudiandae sint et molestiae non recusandae.',
    ]
  cursor(28, 25)
  utils.RemoveSurrounding()
  var actual_value = getline(28, 30)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_remove_surrounding_multi_line2()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  set conceallevel=0
  setlocal spell spelllang=la
  # # Test 2: preserve inner surrounding
  var expected_value = [
    'Itaque earum rerum hic tenetur a sapiente `delectus`, ut aut reiciendis',
    'voluptatibus maiores',
    ]
  cursor(32, 28)
  # with passed argument
  const range_info = utils.IsInRange()
  utils.RemoveSurrounding(range_info)
  var actual_value = getline(32, 33)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef


def g:Test_set_code_block()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal spell spelllang=la

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
  utils.SetBlock()
  var actual_value = getline(3, 10)
  assert_equal(expected_value, actual_value)

  # Check that it won't undo anything when inside a code block
  cursor(6, 10)
  setcharpos("'[", [0, 5, 21, 0])
  setcharpos("']", [0, 8, 10, 0])
  utils.SetBlock()
  assert_equal(expected_value, actual_value)

  # Check that it won't undo when on the border
  cursor(4, 2)
  setcharpos("'[", [0, 4, 2, 0])
  setcharpos("']", [0, 5, 10, 0])
  utils.SetBlock()
  assert_equal(expected_value, actual_value)

  unlet g:markdown_extras_config

  :%bw!
  Cleanup_testfile(src_name_2)
enddef

def g:Test_unset_code_block()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  setlocal spell spelllang=la

  var expected_value = [
    'Itaque earum',
    'rerum hic tenetur ''a sapiente'' delectus, ut aut reiciendis voluptatibus',
    'maiores alias consequatur aut perferendis doloribus asperiores',
    'repellat.'
  ]
  cursor(35, 1)
  utils.UnsetBlock()
  var actual_value = getline(33, 36)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_set_quote_block()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal spell spelllang=la

  var expected_value = [
    '> ab illo inventore veritatis et quasi architecto beatae vitae dicta',
    '> sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit',
    '> aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos',
    '> qui ratione voluptatem sequi nesciunt.',
    ]
  cursor(3, 29)
  setcharpos("'[", [0, 3, 10, 0])
  setcharpos("']", [0, 6, 10, 0])
  utils.SetQuoteBlock()
  var actual_value = getline(3, 6)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_unset_quote_block()
  vnew
  Generate_testfile(lines_2, src_name_2)
  exe $"edit {src_name_2}"
  setlocal spell spelllang=la

  var expected_value = [
  '  Itaque earum rerum hic *tenetur a sapiente `delectus`, ut aut reiciendis',
  '      voluptatibus maiores*',
  ' alias consequatur aut perferendis doloribus asperiores repellat.'
    ]
  cursor(37, 20)
  utils.UnsetQuoteBlock()
  var actual_value = getline(36, 38)
  assert_equal(expected_value, actual_value)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_multibyte_isInRange()
  vnew
  Generate_testfile(lines_multibyte, src_name_multibyte)
  exe $"edit {src_name_multibyte}"
  setlocal conceallevel=0

  setcursorcharpos(6, 6)
  var expected_value = {'markdownBold': [[6, 5], [6, 13]]}
  var range = utils.IsInRange()
  assert_equal(expected_value, range)

  setcursorcharpos(8, 28)
  expected_value = {'markdownItalicU': [[8, 12], [9, 10]]}
  range = utils.IsInRange()
  assert_equal(expected_value, range)

  # Range with blank line as end delimiter
  setcursorcharpos(11, 28)
  expected_value = {'markdownStrike': [[11, 15], [12, 24]]}
  range = utils.IsInRange()
  assert_equal(expected_value, range)

  :%bw!
  Cleanup_testfile(src_name_multibyte)
enddef

def g:Test_multibyte_surrounding()
  vnew
  Generate_testfile(lines_multibyte, src_name_multibyte)
  exe $"edit {src_name_multibyte}"
  setlocal conceallevel=0

  setcursorcharpos(1, 5)
  setcharpos("'[", [0, 1, 4, 0])
  setcharpos("']", [0, 1, 15, 0])
  utils.SurroundSmart('markdownItalicU')
  var expected_value = '当然，_这里有一段简短的中文文本_：'
  assert_equal(expected_value, getline(1))

  setcursorcharpos(3, 11)
  setcharpos("'[", [0, 3, 11, 0])
  setcharpos("']", [0, 4, 8, 0])
  utils.SurroundSmart('markdownStrike')
  var expected_value_3_4 = [
  "学习 Vim 是一项~~非常有趣的挑战。"
      .. "虽然一开始可能感觉有些困难，但只要坚持练习，",
  "就能够逐渐掌握它~~强大的功能，并大幅提高编辑效率。"
  ]
  assert_equal(expected_value_3_4, getline(3, 4))

  :%bw!
  Cleanup_testfile(src_name_multibyte)
enddef

def g:Test_multibyte_remove_surrounding()
  vnew
  Generate_testfile(lines_multibyte, src_name_multibyte)
  exe $"edit {src_name_multibyte}"
  setlocal conceallevel=0

  setcursorcharpos(6, 9)
  var expected_value = '需要某种特定风格或主题（比如技术、文学、对话等）吗？'
  utils.RemoveSurrounding()
  assert_equal(expected_value, getline(6))

  setcursorcharpos(8, 14)
  var expected_value_8_9 = [
    "学习 Vim 是一项非常有趣的挑战。"
        .. "虽然一开始可能感觉有些困难，但只要坚持练习，",
    "就能够逐渐掌握它强大的功能，并大幅提高编辑效率。"
  ]
  utils.RemoveSurrounding()
  assert_equal(expected_value_8_9, getline(8, 9))

  setcursorcharpos(12, 10)
  var expected_value_11_12 = [
    "学习 Vim 是一项非常有趣的挑战。"
        .. "虽然一开始可能感觉有些困难，但只要坚持练习，",
    "就能够逐渐掌握它强大的功能，并大幅提高编辑效率。"
  ]
  utils.RemoveSurrounding()
  assert_equal(expected_value_11_12, getline(11, 12))

  :%bw!
  Cleanup_testfile(src_name_multibyte)
enddef
