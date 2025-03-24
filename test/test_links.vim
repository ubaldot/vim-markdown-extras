vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
import "../lib/constants.vim"
import "../lib/utils.vim"
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
  assert_equal(1, 1)
enddef

def g:Test_IsLink()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  assert_equal(1, 1)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_ConvertLinks()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  assert_equal(1, 1)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_GenerateLinksDict()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  assert_equal(1, 1)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef

def g:Test_RemoveLink()
  vnew
  Generate_testfile(lines_1, src_name_1)
  exe $"edit {src_name_1}"
  assert_equal(1, 1)

  :%bw!
  Cleanup_testfile(src_name_1)
enddef
