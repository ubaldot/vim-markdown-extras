# vim-Markdown-Extras (MDE)


This plugin adds some spice to the built-in [vim-markdown][3] with:

**Core editing:**
- Toggle bold/italic/strike-through with key mappings
- Create, follow, autocomplete and preview links
- Manage tables (align, format, insert/delete rows/columns)

**Block operations:**
- Toggle quoted and code blocks on/off
- Format paragraphs with `gq` or automatically on save

**Organization:**
- Create multiple index files for different subjects or contexts
- Toggle check-boxes in TODO lists with one key-press

**Additional features:**
- Render markdown to different formats with `pandoc`
- Format text with `prettier` or with any formatter you want

Perfect for note-taking!

No special syntax required, just markdown.

## Some videos

[![asciicast_1](https://asciinema.org/a/UbDuIOCSPp1H1F4a7VIcZm5Qj.svg)](https://asciinema.org/a/UbDuIOCSPp1H1F4a7VIcZm5Qj)
[![asciicast_2](https://asciinema.org/a/VTwEYH2aHuAXtEmm.svg)](https://asciinema.org/a/VTwEYH2aHuAXtEmm)

# Requirements

Vim 9.1-1270 is required. You must set a `<localleader>` key and your `.vimrc`
file shall include the following lines:

```
    set nocompatible
    filetype indent plugin on
    syntax on
```

The following is not mandatory, but you want to enable the rendering feature,
you need to install [pandoc][1].

Along the same line, to enable the formatting feature, you need to install
[prettier][2] or any other formatting program of your choice.

# Usage

To best way to explain this plugin is through some examples.

### Text-styles

Open a markdown file and place the cursor on a word.
Hit `<localleader>biw` to change the text-style inside-the-word
to bold. Note that `iw` is a text-object.
Then, while letting the cursor on the bold text, hit `<localleader>r`
to remove it.

Next, visually select some text and hit `<localleader>s`.
To remove the strike-through, stay on the text and hit `<localleader>r`.

See `markdown-extras-mappings` for all the possible text styles.

### Links

Place the cursor on a word and hit `<enter>`.
Select `Create new link` from the popup menu and point to an existing file
or just type a new file name.
If you created a new file, fill it in with some text and save it.
Hit `<backspace>` to go back to the previous file.

Next, place the cursor on the newly created link. Hit `K`.
Then, hit `<enter>` again to open the link.
The link can also be external URL:s, e.g. `https://example.com`.
If the link is a file, then `<S-CR>` open it in a vertical split
window.

Next, create few links and use `<localleader>n` and `<localleader>N` to
locate their position in the current buffer. When on a link, hit
`<localleader>r` to remove it.

You can also dynamically refer to links as you type.
For example, to trigger links auto-completion when you hit `[`, add the
following lines to your `~/.vim/after/ftplugin/markdown.vim` file:

```vim
    setlocal completeopt=menu,menuone,noselect
    import autoload "mde_funcs.vim"
    setlocal omnifunc=mde_funcs.OmniFunc
    inoremap <buffer> ][ ][<C-x><C-o>
```

In your current document, type `[foo][` and a popup menu with all the
available links shall appear.

In case of a markdown file with mixed inline and
reference-style links, you can convert the former to the latter by using
`:MDEConvertLinks` command.

> [!Note]
>
> The links management only applies to links reported after the
> `<!-- DO NOT REMOVE vim-markdown-extras references DO NOT REMOVE-->` comment
> line. Such a line shall be unique in the buffer.

### Lists

You can create lists or enumerations as in any markdown file.
However, the behavior of the `<enter>` key overrides the behavior of the
underlying `vim-markdown` builtin plugin.
If you want the standard [vim-markdown][3] plugin behavior, then set
`g:markdown_extras_config['hack_CR'] = false` in your `.vimrc`.

You can check/uncheck the items in to-do list with `<localleader>x`.
It is possible to change how check-boxes
are rendered by setting the keys `empty_checkbox` and `marked_checkbox` of the
`g:markdown_extras_config` dictionary.
For example you can set `g:markdown_extras_config[marked_checkbox] = 0x2714`.
The value shall be a valid Unicode point value.

If you have `vim-outline` installed, then you can use `<localleader>o` to
display the unchecked items of the to-do list in a scratch buffer.

### Tables

Run `:MDETableInsert 2 3` to insert a 2x3 table placeholder.
Edit any cell. Hit `<localleader>F` to format the table.

Place the cursor on any cell and hit `<localleader>C`. Write some text and
hit `<enter>`.

Finally, put some numbers in some cells. Visually select the table and hit
`<localleader>S`. Look at the command line.

See `:h markdown-extras-mappings` for more functions.

### Formatting

If available, `gq` use `prettier`, but you can use any format program by
setting the key `formatprg` of the `g:markdown_extras_config` dictionary.

However,`formatprg` key may be removed from the configuration dictionary in
future releases as one could directly set `formatprg` option.

### Rendering

If you have `pandoc` installed, then `vim-markdown-extras`
sets `compiler-pandoc`.
You can then use `:make` to render your buffer with `pandoc`.

To render and open the rendered file at once, you can use `:MDEMake` followed
by `<tab>` to select a target.

You can also pass arguments to `pandoc` via the key
`pandoc_args` of the `g:markdown_extras_config` dictionary.
You could for example set the following:

```
  g:markdown_extras_config = {}
  g:markdown_extras_config['pandoc_args'] =
  [$'--css="{$HOME}/dotfiles/my_css_style.css"',
      $'--lua-filter="{$HOME}/dotfiles/emoji-admonitions.lua"']
```

### Indices

In the same spirit of vimwiki, this plugin offer the chance of use different
indices, selectable by a popup. See `:h :MDEIndex` for more info.

### License

BSD-3.

<!-- DO NOT REMOVE vim-markdown-extras references DO NOT REMOVE-->

[1]: https://pandoc.org
[2]: https://prettier.io
[3]: https://github.com/tpope/vim-markdown
[4]: https://github.com/ubaldot/vim-outline
