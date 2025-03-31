# vim-markdown-extras

This plugin adds some spice to the bundled [vim-markdown][3], such as:

- Easy toggle italic, bold, strike-through, code text-styles,
- Easy to add/jump/remove/preview links,
- Toggle quoted and code blocks,
- Format with `gq` and on save,
- Render with `pandoc`,
- ... and more.

# Requirements

Vim 9.0 is required.
You must set a `<localleader>` key and your `vimrc` shall include the following
lines:

```
    filetype indent plugin on
    syntax on
```

The following is not mandatory, but you want to enable the rendering feature,
you need to install [pandoc][1]. To automatically open the rendered files, Vim
must have the `:Open` command.

Along the same line, to enable the formatting feature, you need to install
[prettier][2] or any other formatting program of your choice.

# Usage

To best way to describe how to operate it, let's go through some examples.

### Text-styles

Open a markdown file and place the cursor on a word.
Hit `<localleader>biw` to change the text-style inside-the-word
to bold (`iw` is a text-objext).
Then, while letting the cursor on the bold text, hit `<localleader>d`
to remove it.

Next, try to do the same with arbitrary text-objects or in Visual mode by
replacing `b` with `i` for italics, `s` for strike-through, `c` for code, etc.

You can also highlight text with `<localleader>h`. However, the highlight is
not persistent. As usual, you can remove the highlight with `<localleader>d`.

See `:h markdown-extras-mappings` for all the possible text styles.

### Links

Now, place the cursor on a word and hit `<enter>`.
Select `Create new link` from the popup menu and point to an existing
file or just type a new file name.
If you created a new file, fill it in with some text and save it.
Hit `<backspace>` to go back to the previous file and place the cursor to the
newly created link. Hit `K`. Then, hit `<enter>` again to open the link.
The link can also be external URL:s, e.g. `https://example.com`.

Next, create some new links and use `<localleader>n` and `<localleader>N` to
locate their position in the current buffer. When on a link text, hit
`<localleader>d` to remove the link.

Although you can hit `<enter>` to link a word, more generlly you can
use `<localleader>l` plus some motion to create links.

You can also dynamically refer to links while typing. Go in insert mode and
type `[` to see a list of all available links.

In case you are working on a markdown file with mixed inline and
reference-style links, you can convert the former to the latter by using
`:MDEConvertLinks` command. All the newly created links will be placed after
the `<!-- DO NOT REMOVE vim-markdown-extras references  DO NOT REMOVE-->`
comment line. The reference identifiers are numbers.

> [!Note]
>
> The links management only applies to links reported after the
> `<!-- DO NOT REMOVE vim-markdown-extras references  DO NOT REMOVE-->`
> comment line. Such a line shall be unique in the buffer.

### Lists

You can create lists or enumerations as usual. However, the behavior of the
`<enter>` key is hacked to mimic the behavior of Microsoft products and
respect possible nesting. Although there are many reasons to stick with the
bundled [vim-markdown][3] behavior when it comes to lists,
my use-cases and preferences require a different behavior. At the end Vim is a
matter of customizing everything to your workflow, no? :)

You can create to-do lists as you would do in normal markdown, by starting
lines with `- [ ]` . When in normal mode, you can check/uncheck the item in the
to-do list with `<localleader>x` in normal mode.

> [!Note]
>
> If you have `vim-outline` installed, then you can use `<localleader>o` to
> display the unchecked items of the to-do list in a scratch buffer.

### Formatting

You can format text as usual by using `gq`.
Here `gq` uses `prettier`, provided that you have it installed.
That is, if you use `gq` plus motion, or if you visually select some text and
then hit `gq`, then `prettier` will only prettify such a portion of text. You
can also prettify the whole buffer on save by setting
`g:markdown_extras_config['format_on_save'] = true` in your `.vimrc`.

### Rendering

You can then use `:make` to render your buffer with `pandoc`, provided that
you have `pandoc` installed.

However, sometimes you want to render & open the rendered file at once, and
for this reason you have `:MDEMake`. Try to run call such a command and hit
    `<tab>` to see possible targets.

You can pass arguments to `pandoc` via the key
`pandoc_args` of the `g:markdown_extras_config` dictionary.
You could for example set the following:

```
  g:markdown_extras_config = {}
  g:markdown_extras_config['pandoc_args'] =
  [$'--css="{$HOME}/dotfiles/my_css_style.css"',
      $'--lua-filter="{$HOME}/dotfiles/emoji-admonitions.lua"']
```

> [!Note]
>
> The rendered file will automatically open if your Vim has the `:Open` command.

### Indices

As the plugin can be used for note-taking, it may be desirable to access
different indices in an ergonomic way. This can be achieved with the
`g:markdown_extras_indices` list in combination with the `:MDEIndices`
command. Note that `g:markdown_extras_indices` is nothing, but a list of files.

For more information about key-bindings, configuration, etc. take
a look at `:h markdown-extras`.

### Limitations

Nothing is perfect, and this plugin is no exception. Here are some random
limitations:

- Markdown is not a regular language, and many features rely on regular
  expressions. This means there will always be corner cases where some features
  fail. Parsing non-regular languages requires more advanced tools like
  Tree-sitter. However, it is generally not a good idea to "punish" all use
  cases with slow and memory-hungry solutions just for a few edge cases that
  likely occur very sporadically. I prefer efficiency and speed for most use
  cases, and for the others... well, patience!

- The plugin somewhat forces the use of reference-style links where the
  reference identifier is a number. You could try using strings as reference
  identifiers, but I won't guarantee that everything will work fine.

- The link management system heavily relies on the content below the
  `<!-- DO NOT REMOVE vim-markdown-extras references DO NOT REMOVE -->`
  comment. That comment must be unique. Attempting to pick links randomly
  scattered throughout the buffer using regular expressions would most likely
  lead to the issue described in the first bullet point.

### License

BSD-3.

<!-- DO NOT REMOVE vim-markdown-extras references DO NOT REMOVE-->

[1]: https://pandoc.org
[2]: https://prettier.io
[3]: https://github.com/tpope/vim-markdown
