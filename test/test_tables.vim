vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
const WaitForAssert = common.WaitForAssert

def Generate_testfile(lines: list<string>, src_name: string)
   writefile(lines, src_name)
enddef

def Cleanup_testfile(src_name: string)
   delete(src_name)
enddef

# Tests start here
def g:Test_align_table_basic()

  v:errors = []
  v:errmsg = ''
  messages clear

  const src_name = 'testfile.md'
  const lines =<< trim END
# Test table alignment

| ciao       |   notte      | quanto ti       |
|------------|----------------------|-----------------|
| ciao | super                | quanto ti       |
| sono      |          |           |
|            |                      |         |
|     | come no mingle          |                 |
|            | notte                |                 |
|            | banana                |           |
| si si      |     apple             |            |
|            | mango          |         |
|------------|----------------------|-----------------|
END

  var expected_lines =<< END
# Test table alignment

| ciao       | notte                | quanto ti       |
|------------|----------------------|-----------------|
| ciao       | super                | quanto ti       |
| sono       |                      |                 |
|            |                      |                 |
|            | come no mingle       |                 |
|            | notte                |                 |
|            | banana               |                 |
| si si      | apple                |                 |
|            | mango                |                 |
|------------|----------------------|-----------------|
END

  vnew
  Generate_testfile(lines, src_name)
  exe $"edit {src_name}"

  # cursor(6, 3)
  # execute $"silent norm! \<Plug>MarkdownAlign"

  # var actual_lines = getline(1, '$')
  # assert_equal(expected_lines, actual_lines)

  # ------ test MDETableDelimiter ----
#   expected_lines =<< trim END
# # Test table alignment

# | ciao         | notte                  | quanto ti         |
# | ------------ | ---------------------- | ----------------- |
# | ciao         | super                  | quanto ti         |
# | sono         |                        |                   |
# |--------------|------------------------|-------------------|
# |              |                        |                   |
# |              | come no mingle         |                   |
# |              | notte                  |                   |
# |              | banana                 |                   |
# | si si        | apple                  |                   |
# |              | mango                  |                   |
# | ------------ | ---------------------- | ----------------- |
# END

#   execute "MDETableDelimiter"

#   actual_lines = getline(1, '$')
  # assert_equal(expected_lines, actual_lines)

  if !empty(v:errors) || !empty(v:errmsg)
    echoerr "Test failed!"
  else
    echo "Test passed!"
  endif

  # :%bw!
  # Cleanup_testfile(src_name_1)
enddef
