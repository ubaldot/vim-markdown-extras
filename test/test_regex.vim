vim9script

import "../after/ftplugin/markdown.vim"

const CODE_OPEN_REGEX = markdown.CODE_OPEN_DICT['`']
const CODE_CLOSE_REGEX = markdown.CODE_CLOSE_DICT['`']
const ITALIC_OPEN_REGEX = markdown.ITALIC_OPEN_DICT['*']
const ITALIC_CLOSE_REGEX = markdown.ITALIC_CLOSE_DICT['*']
const BOLD_OPEN_REGEX = markdown.BOLD_OPEN_DICT['**']
const BOLD_CLOSE_REGEX = markdown.BOLD_CLOSE_DICT['**']
const ITALIC_U_OPEN_REGEX = markdown.ITALIC_U_OPEN_DICT['_']
const ITALIC_U_CLOSE_REGEX = markdown.ITALIC_U_OPEN_DICT['_']
const BOLD_U_OPEN_REGEX = markdown.BOLD_U_OPEN_DICT['__']
const BOLD_U_CLOSE_REGEX = markdown.BOLD_U_CLOSE_DICT['__']
const STRIKE_OPEN_REGEX = markdown.STRIKE_OPEN_DICT['~~']
const STRIKE_CLOSE_REGEX = markdown.STRIKE_CLOSE_DICT['~~']
const LINK_OPEN_REGEX = markdown.LINK_OPEN_DICT['[']
const LINK_CLOSE_REGEX = markdown.LINK_CLOSE_DICT[']']

const src_name_1 = 'testfile.md'
const lines_1 =<< trim END
      Sed ut perspiciatis unde omnis iste **natus error sit voluptatem
      accusantium** doloremque *laudantium, totam rem aperiam, eaque ipsa quae
      ab illo inventore veritatis *et quasi architecto beatae vitae dicta
      sunt \*\*explicabo. Nemo *enim ipsam voluptatem* quia voluptas sit
      aspernatur **aut odit aut fugit,** sed quia consequuntur magni dolores eos
      qui ~~ratione voluptatem sequi nesciunt.~~

      Neque porro quisquam \**est*\*, qui dolorem ipsum quia dolor sit amet,
      consectetur, adipisci velit, sed quia non numquam eius modi tempora
      incidunt ut labore et dolore *\*magnam\** aliquam quaerat voluptatem. Ut
      enim ad \~ minima veniam, quis nostrum exercitationem ullam corporis
      suscipit laboriosam, nisi \*ut aliquid ex ea \~~commodi consequatur?

      Quis autem ~vel eum iure reprehenderit qui in ea voluptate velit esse
      quam nihil molestiae consequatur,~ vel `illum qui \~ dolorem eum` fugiat quo
      voluptas nulla \` pariatur``?

      At vero eos et _accusamus et iusto odio dignissimos ducimus qui blanditiis
      praesentium voluptatum deleniti_ atque corrupti \_quos dolores et quas molestias
      excepturi sint occaecati _cupiditate_ non \_provident, similique sunt in culpa qui
      officia deserunt \__mollitia animi_, id est laborum et dolorum fuga. Et harum
      quidem rerum facilis est et expedita distinctio.

      Nam libero tempore, __cum soluta nobis est eligendi optio cumque nihil
      impedit quo minus id quod maxime placeat facere possimus, omnis
      voluptas assumenda est__, omnis dolor repellendus. Temporibus autem
      quibusdam et aut officiis debitis aut rerum necessitatibus saepe
      eveniet ut et voluptates repudiandae sint et molestiae non recusandae.

      Itaque earum rerum hic tenetur a sapiente delectus, ut aut
      reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus
      asperiores repellat
END

const src_name_2 = "testfile_links.md"
const lines_2 =<< trim END
  This is a Markdown document used to test the provided regex for links.

  Some text here, but let's jump into the links:

    (Not a Link) this part is not a link but looks like one.
    [Valid Link 1](https://www.google.com) — This is a valid external link to
    Google.
    Here's some random text, and then [Link with Invalid
    Target](#missing-target) — This link points nowhere.
    [ciao][sisi] — This is a valid reference-style link that points to a section
    below.
    [Google](https://www.google.com) and [GitHub](https://github.com) are
    popular websites.
    [This looks like a link](#) but doesn't really go anywhere.
    And then some ]more random text, followed by another [Valid Link
    2](https://www.wikipedia.org).
    (Just Text) <- This is not a link.
    [Not a Link] <- This is text formatted like a link but it's not clickable.
    And more text \[ with links: [Valid Internal Link](#valid
    -internal-link) and
    [Random
    The following [Invalid Link Format] <- This part looks like a link, but it
      is just text.
    Then, we have some inline text with [Valid
    Link](https://www.example.com)
    inside.
    No [real link][2] here, just text: [This looks like a link](#).
    Some more [text with no link] just appearing like a link.
    [Another Example](http://www.example.com) is another valid link to a real
    website.
    [blabla] baz [ciao ciao] <- No valid links here, just text.
    [Invalid URL](http://malformedurl) <- This ][ciao](ftp://foo.com)might look like a link but it’s
    malformed.
END


def Generate_testfile(lines: list<string>, src_name: string)
   writefile(lines, src_name)
enddef

def Cleanup_testfile(src_name: string)
   delete(src_name)
enddef

# Tests start here
def g:Test_textstyle_italic_regex()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  setlocal conceallevel=0

  # Italic open
  var expected_pos = [[2, 26], [3, 29], [4, 26], [4, 48],
    [8, 24], [8, 28], [10, 30], [10, 41], [0, 0]]
  var actual_pos = []
  var tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(ITALIC_OPEN_REGEX, 'W')
    add(actual_pos, tmp)
  endwhile
  echo actual_pos
  echom "FOO"
  echom assert_equal(expected_pos, actual_pos)

  # # redraw!
  # # sleep 3
  # :%bw!
  # Cleanup_testfile(src_name_1)
enddef

def g:Test_textstyle_bold_regex()
  vnew
  Generate_testfile(lines_1, src_name_1)

  exe $"edit {src_name_1}"
  setlocal conceallevel=0

  # Bold
  expected_pos = [[1, 37], [2, 12], [5, 12], [5, 33], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(BOLD_REGEX, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)
  #
  # # redraw!
  # # sleep 3
  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_textstyle_code_regex()
  vnew
  Generate_testfile(lines_1, src_name_1)

  exe $"edit {src_name_1}"
  setlocal conceallevel=0

  # # Code
  expected_pos = [[15, 40], [15, 65], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(CODE_REGEX, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  # # redraw!
  # # sleep 3
  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_textstyle_strikethrough_regex()
  vnew
  Generate_testfile(lines_1, src_name_1)

  exe $"edit {src_name_1}"
  setlocal conceallevel=0

  # # Strkethrough
  expected_pos = [[6, 5], [6, 41], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(STRIKETHROUGH_REGEX, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  # # redraw!
  # # sleep 3
  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_textstyle_italic_u_regex()
  vnew
  Generate_testfile(lines_1, src_name_1)

  exe $"edit {src_name_1}"
  setlocal conceallevel=0

  # # italic underscore
  expected_pos = [[18, 16], [19, 32], [20, 26],
    [20, 37], [21, 20], [21, 35], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(ITALIC_REGEX_U, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  # # redraw!
  # # sleep 3
  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_textstyle_bold_u_regex()
  vnew
  Generate_testfile(lines_1, src_name_1)

  exe $"edit {src_name_1}"
  setlocal conceallevel=0

  # # bold underscore
  expected_pos = [[24, 21], [26, 23], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(BOLD_REGEX_U, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  # # redraw!
  # # sleep 3
  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_links_regex()
  vnew
  Generate_testfile(lines_2, src_name_2)

  exe $"edit {src_name_2}"
  setlocal conceallevel=0

  var expected_pos = [[6, 3], [10, 3], [12, 3],
    [12, 40], [27, 6], [29, 3], [32, 3], [32, 47], [0, 0]]
  var actual_pos = []
  var tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(LINK_OPEN_REGEX, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  expected_pos = [[6, 16], [10, 8], [12, 10], [12, 47],
      [27, 16], [29, 19], [32, 15], [32, 52], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(LINK_CLOSE_REGEX, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  :%bw!
  Cleanup_testfile(src_name_2)
enddef
