vim9script noclear

import "../after/ftplugin/markdown.vim"

var code_regex = markdown.code_dict['`']
var italic_regex = markdown.italic_dict['*']
var bold_regex = markdown.bold_dict['**']
var italic_regex_u = markdown.italic_dict_u['_']
var bold_regex_u = markdown.bold_dict_u['__']
var strikethrough_regex = markdown.strikethrough_dict['~~']

var src_name = 'testfile.md'

def Generate_markdown_testfile()
  var lines =<< trim END
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
   writefile(lines, src_name)
enddef

def Cleanup_markdown_testfile()
   delete(src_name)
enddef

# Tests start here
def g:Test_regex()
  vnew
  Generate_markdown_testfile()

  exe $"edit {src_name}"
  setlocal conceallevel=0

  # Italic
  var expected_pos = [[2, 26], [3, 29], [4, 26], [4, 48],
    [8, 24], [8, 28], [10, 30], [10, 41], [0, 0]]
  var actual_pos = []
  var tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(italic_regex, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  # Bold
  expected_pos = [[1, 37], [2, 12], [5, 12], [5, 33], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(bold_regex, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  # Code
  expected_pos = [[15, 40], [15, 65], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(code_regex, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  # Strkethrough
  expected_pos = [[6, 5], [6, 41], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(strikethrough_regex, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  # italic underscore
  expected_pos = [[18, 16], [19, 32], [20, 26],
    [20, 37], [21, 20], [21, 35], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(italic_regex_u, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  # bold underscore
  expected_pos = [[24, 21], [26, 23], [0, 0]]
  actual_pos = []
  tmp = []
  cursor(1, 1)
  while tmp != [0, 0]
    tmp = searchpos(bold_regex_u, 'W')
    add(actual_pos, tmp)
  endwhile
  assert_equal(expected_pos, actual_pos)

  # redraw!
  # sleep 3
  :%bw!
  Cleanup_markdown_testfile()
enddef
