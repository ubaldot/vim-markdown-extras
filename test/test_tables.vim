vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "../plugin/markdown_extras.vim"
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

| ciao  | notte          | quanto ti |
|-------|----------------|-----------|
| ciao  | super          | quanto ti |
| sono  |                |           |
|       |                |           |
|       | come no mingle |           |
|       | notte          |           |
|       | banana         |           |
| si si | apple          |           |
|       | mango          |           |
|-------|----------------|-----------|
END

  vnew
  Generate_testfile(lines, src_name)
  exe $"edit {src_name}"

  cursor(6, 3)
  execute $"silent norm! \<Plug>MarkdownAlign"

  var actual_lines = getline(1, '$')
  assert_equal(expected_lines, actual_lines)

  # ------ test MDETableRowDelimiter ----
  expected_lines =<< trim END
# Test table alignment

| ciao  | notte          | quanto ti |
|-------|----------------|-----------|
| ciao  | super          | quanto ti |
| sono  |                |           |
|-------|----------------|-----------|
|       |                |           |
|       | come no mingle |           |
|       | notte          |           |
|       | banana         |           |
| si si | apple          |           |
|       | mango          |           |
|-------|----------------|-----------|
END

  execute "MDETableRowDelimiter"

  actual_lines = getline(1, '$')
  assert_equal(expected_lines, actual_lines)

  # ------ test insert ----
  expected_lines =<< trim END
# Test table alignment

| ciao    | notte          | quanto ti |
|---------|----------------|-----------|
| ciao    | super          | quanto ti |
| sono    |                |           |
|---------|----------------|-----------|
|         |                |           |
|         | come no mingle |           |
|         | notte          |           |
|         | banana         |           |
| si si   | apple          |           |
|         | mango          |           |
|---------|----------------|-----------|
| foo bar | ciao           |           |
END

  const key_sequence = "Go\<bar> foo bar \<bar> ciao \<bar>\<esc>,a"
  redraw
  execute $"silent norm {key_sequence}"


  actual_lines = getline(1, '$')
  assert_equal(expected_lines, actual_lines)

  # ---- teardown tests ----
  if !empty(v:errors) || !empty(v:errmsg)
    echoerr "Test failed!"
  else
    echom "Test passed!"
  endif

  # :%bw!
  # Cleanup_testfile(src_name)
enddef
