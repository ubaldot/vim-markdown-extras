# vim-markdown-extras
[WIP] [Editing][3] [markdowns][1] has never been so pleasant.

if index(['file', 'file_in_path', 'recent_files', 'buffer'],
\ search_type) != -1
PopupCallback = (id, idx) => PopupCallbackFileBuffer(id, preview_id, idx)
elseif search_type == 'dir'
PopupCallback = PopupCallbackDir

## References

[1]: /Users/ubaldot/.vim/plugins/vim-markdown-extras/LICENSE
[2]: https://google.com
[3]: /Users/ubaldot/.vim/plugins/vim-markdown-extras/ll
[5]: /Users/ubaldot/.vim/plugins/vim-markdown-extras/doc/markdown_extras.txt
