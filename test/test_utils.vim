vim9script

# Test for the vim-markdown plugin
# Copied and adjusted from Vim distribution

import "./common.vim"
var WaitForAssert = common.WaitForAssert


var src_name = 'testfile.md'

def Generate_markdown_testfile()
  var lines =<< trim END
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
        suscipit laboriosam`, nisi ut aliquid ex ea commodi consequatur?

        Quis autem vel eum **iure reprehenderit qui in ea voluptate velit esse
        quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo
        voluptas nulla** pariatur?
  END
   writefile(lines, src_name)
enddef

def Cleanup_markdown_testfile()
   delete(src_name)
enddef

def g:Sto_cazzo()

enddef

# Tests start here
def g:Test_sto_cazzo()
  Generate_markdown_testfile()

  exe $"edit {src_name}"


  # redraw!
  # sleep 3
  :%bw!
  Cleanup_markdown_testfile()
enddef
