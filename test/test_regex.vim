vim9script

import "../lib/constants.vim"

const CODE_OPEN_REGEX = constants.CODE_OPEN_DICT['`']
const CODE_CLOSE_REGEX = constants.CODE_CLOSE_DICT['`']
const ITALIC_OPEN_REGEX = constants.ITALIC_OPEN_DICT['*']
const ITALIC_CLOSE_REGEX = constants.ITALIC_CLOSE_DICT['*']
const BOLD_OPEN_REGEX = constants.BOLD_OPEN_DICT['**']
const BOLD_CLOSE_REGEX = constants.BOLD_CLOSE_DICT['**']
const ITALIC_U_OPEN_REGEX = constants.ITALIC_U_OPEN_DICT['_']
const ITALIC_U_CLOSE_REGEX = constants.ITALIC_U_CLOSE_DICT['_']
const BOLD_U_OPEN_REGEX = constants.BOLD_U_OPEN_DICT['__']
const BOLD_U_CLOSE_REGEX = constants.BOLD_U_CLOSE_DICT['__']
const STRIKE_OPEN_REGEX = constants.STRIKE_OPEN_DICT['~~']
const STRIKE_CLOSE_REGEX = constants.STRIKE_CLOSE_DICT['~~']
const LINK_OPEN_REGEX = constants.LINK_OPEN_DICT['[']
const LINK_CLOSE_REGEX = constants.LINK_CLOSE_DICT[']']

const src_name_1 = 'testfile.md'
const lines_1 =<< trim END
      Sed ut perspiciatis unde omnis iste\***natus * error sit voluptatem
      accusantium**\* doloremque *laudantium, totam rem aperiam, eaque ipsa quae
      ab illo inventore veritatis *et quasi architecto beatae vitae dicta
      sunt \*\*explicabo. Nemo *enim ipsam voluptatem* quia voluptas sit
      aspernatur **aut odit aut fugit,** sed quia consequuntur magni dolores eos
      qui ~~ratione *voluptatem \~ sequi nesciunt.~~ bla bla

      Neque porro quisquam\**est*\*, qui dolorem ipsum quia dolor sit amet,
      consectetur, adipisci velit, sed quia non numquam eius modi tempora
      incidunt ut labore et dolore *\*magnam\** aliquam quaerat voluptatem. Ut
      enim ad \~ minima veniam, quis nostrum exercitationem ullam corporis
      suscipit laboriosam, nisi \*ut aliquid ex ea \~~commodi consequatur?

      Quis autem ~vel eum iure reprehenderit qui in ea voluptate velit esse
      quam nihil molestiae consequatur,~ vel `illum * qui ~  dolorem eum`\` fugiat quo
      voluptas nulla pariatur?

      At vero eos et _accusamus et iusto odio dignissimos ducimus qui blanditiis
      praesentium voluptatum deleniti_ atque corrupti \_quos dolores et quas molestias
      excepturi sint occaecati _cupiditate_\_ non \_provident, similique sunt in culpa qui
      officia deserunt \__mollitia animi_, id est laborum et dolorum fuga. Et harum
      quidem rerum facilis est et expedita distinctio.

      Nam libero tempore, __cum soluta nobis est eligendi optio cumque nihil
      impedit quo minus id quod maxime placeat facere possimus, omnis
      voluptas assumenda est__, omnis dolor repellendus. Temporibus autem
      quibusdam et aut officiis debitis aut rerum necessitatibus saepe
      eveniet ut et voluptates repudiandae sint et ~~molestiae non recusandae.

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
  setlocal spell spelllang=la

  # Setup
  const curpos = [[2, 33], [8, 25], [10, 36]]
  const expected_pos_open = [[2, 28], [8, 23], [10, 30]]
  const expected_pos_close = [[4, 47], [8, 26], [10, 40]]
  var actual_pos = []

  # Test
  for ii in range(len(curpos))
    cursor(curpos[ii])
    actual_pos = searchpos(ITALIC_OPEN_REGEX, 'bW')
    echom assert_equal(expected_pos_open[ii], actual_pos)

    # Close
    cursor(curpos[ii])
    actual_pos = searchpos(ITALIC_CLOSE_REGEX, 'cW')
    echom assert_equal(expected_pos_close[ii], actual_pos)
  endfor

  # redraw!
  # sleep 3
  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_textstyle_bold_regex()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  setlocal conceallevel=0
  setlocal spell spelllang=la

  # Setup
  const curpos = [[1, 53], [5, 21]]
  const expected_pos_open = [[1, 38], [5, 12]]
  const expected_pos_close = [[2, 11], [5, 32]]
  var actual_pos = []

  # Test
  for ii in range(len(curpos))
    cursor(curpos[ii])
    actual_pos = searchpos(BOLD_OPEN_REGEX, 'bW')
    echom assert_equal(expected_pos_open[ii], actual_pos)

    # Close
    cursor(curpos[ii])
    actual_pos = searchpos(BOLD_CLOSE_REGEX, 'cW')
    echom assert_equal(expected_pos_close[ii], actual_pos)
  endfor

  # redraw!
  # sleep 3
  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_textstyle_code_regex()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  setlocal conceallevel=0
  setlocal spell spelllang=la

  # Setup
  const curpos = [[15, 49]]
  const expected_pos_open = [[15, 40]]
  const expected_pos_close = [[15, 66]]
  var actual_pos = []

  # Test
  for ii in range(len(curpos))
    cursor(curpos[ii])
    actual_pos = searchpos(CODE_OPEN_REGEX, 'bW')
    echom assert_equal(expected_pos_open[ii], actual_pos)

    # Close
    cursor(curpos[ii])
    actual_pos = searchpos(CODE_CLOSE_REGEX, 'cW')
    echom assert_equal(expected_pos_close[ii], actual_pos)
  endfor

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
  setlocal spell spelllang=la

  # Setup
  const curpos = [[6, 41], [28, 52]]
  const expected_pos_open = [[6, 5], [28, 46]]
  const expected_pos_close = [[6, 44], [29, 1]]
  var actual_pos = []

  # Test
  for ii in range(len(curpos))
    cursor(curpos[ii])
    actual_pos = searchpos(STRIKE_OPEN_REGEX, 'bW')
    echom assert_equal(expected_pos_open[ii], actual_pos)

    # Close
    cursor(curpos[ii])
    actual_pos = searchpos(STRIKE_CLOSE_REGEX, 'cW')
    echom assert_equal(expected_pos_close[ii], actual_pos)
  endfor

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
  setlocal spell spelllang=la

  # Setup
  const curpos = [[19, 21], [20, 31]]
  const expected_pos_open = [[18, 16], [20, 26]]
  const expected_pos_close = [[19, 31], [20, 36] ]
  var actual_pos = []

  # Test
  for ii in range(len(curpos))
    cursor(curpos[ii])
    actual_pos = searchpos(ITALIC_U_OPEN_REGEX, 'bW')
    echom assert_equal(expected_pos_open[ii], actual_pos)

    # Close
    cursor(curpos[ii])
    actual_pos = searchpos(ITALIC_U_CLOSE_REGEX, 'cW')
    echom assert_equal(expected_pos_close[ii], actual_pos)
  endfor

  # redraw!
  # sleep 3
  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_textstyle_bold_u_regex()
  vnew
  Generate_testfile(lines_1, src_name_1)

  exe $"edit {src_name_1}"
  setlocal conceallevel=0
  setlocal spell spelllang=la

  # Setup
  const curpos = [[26, 22]]
  const expected_pos_open = [[24, 21]]
  const expected_pos_close = [[26, 22]]
  var actual_pos = []

  # Test
  for ii in range(len(curpos))
    cursor(curpos[ii])
    actual_pos = searchpos(BOLD_U_OPEN_REGEX, 'bW')
    echom actual_pos
    echom assert_equal(expected_pos_open[ii], actual_pos)

    # Close
    cursor(curpos[ii])
    actual_pos = searchpos(BOLD_U_CLOSE_REGEX, 'cW')
    echom assert_equal(expected_pos_close[ii], actual_pos)
  endfor

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
  setlocal spell spelllang=la

  # Setup
  const curpos = [[6, 7], [10, 6], [12, 46]]
  const expected_pos_open = [[6, 3], [10, 3], [12, 40]]
  const expected_pos_close = [[6, 16], [10, 8], [12, 47]]
  var actual_pos = []

  # Test
  for ii in range(len(curpos))
    cursor(curpos[ii])
    actual_pos = searchpos(LINK_OPEN_REGEX, 'bW')
    echom assert_equal(expected_pos_open[ii], actual_pos)

    # Close
    cursor(curpos[ii])
    actual_pos = searchpos(LINK_CLOSE_REGEX, 'cW')
    echom LINK_CLOSE_REGEX
    echom actual_pos
    echom assert_equal(expected_pos_close[ii], actual_pos)
  endfor

  # :%bw!
  # Cleanup_testfile(src_name_2)
enddef
