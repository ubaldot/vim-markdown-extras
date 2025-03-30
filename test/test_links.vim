vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
import "../lib/constants.vim"
import "../lib/utils.vim"
import "../lib/links.vim"
const WaitForAssert = common.WaitForAssert

# Test file 1
const src_name_1 = 'testfile_1.md'
const lines_1 =<< trim END
    # Example Markdown with Mixed References

    This is a test of different types of references in Markdown.

    Here is a reference-style link: [foo][1].
    And here [is](foo_foo) an inline link: [bar] (ciao_ciao).
    Another reference-style link: [baz][2].

    More text to demonstrate mixed links. Here is another inline link: [example](https://example.com).
    And here’s another reference-style link: [test][3].

    ## Additional Section

    Some text with more links:

    - Click [here][4] for more info.
    - Visit [this site](https://somewhere.com) for details.

    ## References

    [1]: https://example.com/foo
    [2]: https://example.com/baz
    [3]: https://example.com/test
    [4]: https://example.com/more
END


def Generate_testfile(lines: list<string>, src_name: string)
   writefile(lines, src_name)
enddef

def Cleanup_testfile(src_name: string)
   delete(src_name)
enddef

# Tests start here
def g:Test_SearchLink()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  assert_equal(1, 1)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_IsURL()
  const url = 'https://example.com'
  assert_true(links.IsURL(url))

  const no_url = 'foo'
  assert_false(links.IsURL(no_url))
enddef

def g:Test_IsLink()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  cursor(5, 2)
  echom assert_true(empty(links.IsLink()))

  cursor(7, 33)
  const expected_value = {'markdownLinkText': [[7, 32], [7, 34]]}
  echom assert_equal(expected_value, links.IsLink())

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_ConvertLinks()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"

  exe "MDEConvertLinks"

  const expected_line_6 = 'And here [is][5] an inline link: [bar] [6].'
  const expected_lines_9_10 = [
  'More text to demonstrate mixed links. Here is another inline link: ',
  '[example][7].'
  ]
  const expected_line_18 = '- Visit [this site][8] for details.'
  const expected_lines_26_29 = [
            '[5]: foo_foo',
            '[6]: ciao_ciao',
            '[7]: https://example.com',
            '[8]: https://somewhere.com'
          ]

  echom assert_equal(expected_line_6, getline(6))
  echom assert_equal(expected_lines_9_10, getline(9, 10))
  echom assert_equal(expected_line_18, getline(18))
  echom assert_equal(expected_lines_26_29, getline(26, 29))

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_RefreshLinksDict()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"

  const expected_value = {'1': 'https://example.com/foo',
    '2': 'https://example.com/baz',
    '3': 'https://example.com/test',
    '4': 'https://example.com/more'}

  echom assert_equal(expected_value, links.RefreshLinksDict())

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_RemoveLink()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"

  cursor(6, 12)
  const expected_value_line_6 = 'And here is an inline link: [bar] (ciao_ciao).'
  links.RemoveLink()
  echom assert_equal(expected_value_line_6, getline(6))

  cursor(7, 33)
  links.RemoveLink()
  const expected_value_line_7 = 'Another reference-style link: baz.'
  echom assert_equal(expected_value_line_7, getline(7))

  cursor(16, 10)
  links.RemoveLink()
  const expected_value_line_16 = '- Click here for more info.'
  echom assert_equal(expected_value_line_16, getline(16))

  cursor(17, 12)
  links.RemoveLink()
  const expected_value_line_17 = '- Visit this site for details.'
  echom assert_equal(expected_value_line_17, getline(17))

  :%bw!
  Cleanup_testfile(src_name_1)
enddef
