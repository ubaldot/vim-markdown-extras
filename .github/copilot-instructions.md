# Copilot instructions for `vim-markdown-extras`

## Build, test, and lint commands

This repository does not define a separate build or lint pipeline. The primary automation is the Vim-based unit test suite under `test/`.

### Run full test suite

From repository root:

```bash
cd test
./run_tests.sh 1
```

On Windows (from repository root):

```powershell
Set-Location test
.\run_tests.cmd
```

### Run a single test file

From `test/`, run `runner.vim` with a custom `g:TestFiles` list:

```bash
vim --clean -Es -u NONE -i NONE --not-a-term \
  -c "set runtimepath+=.. | filetype indent plugin on | syntax on | let g:TestFiles=['test_links.vim']" \
  -S runner.vim
```

### Run a single test function

`test/README.md` documents manual function-level execution inside Vim:

1. Open Vim from `test/`.
2. `:source test_links.vim`
3. `:call Test_IsURL()`

Use this for focused debugging of one function.

## High-level architecture

The plugin is split into a global startup layer plus markdown-buffer feature wiring:

- `plugin/markdown_extras.vim` is the global entrypoint. It enforces minimum Vim patch levels, checks optional executables (`prettier`, `pandoc`), sets global toggles (`use_prettier`, `use_pandoc`), tracks visited markdown buffers, and defines global commands like `:MDEIndex`, `:MDEReleaseNotes`, and `:MDEPathToURL`.
- `ftplugin/markdown.vim` is the per-buffer integration layer. It wires buffer-local commands (`:MDEConvertLinks`, `:MDESanitizeLinks`, `:MDETableInsert`, `:MDEMake`) and maps `<Plug>` actions to default `<localleader>` mappings when enabled.
- `autoload/mde_*.vim` modules contain implementation logic:
  - `mde_links.vim`: link parsing, reference dictionary refresh, conversion/sanitization, preview/open popups, URL/path conversion.
  - `mde_tables.vim`: table insertion, formatting/alignment, per-cell editing popup/split flows, summation.
  - `mde_utils.vim`: surround/unset logic, block helpers, formatting operator behavior, range utilities.
  - `mde_funcs.vim`: `<CR>` behavior for lists/tables, checkbox toggling, visited-buffer navigation, generic remove action.
  - `mde_constants.vim`: regex/delimiter dictionaries for markdown text-style parsing.
  - `mde_indices.vim` and `mde_highlight.vim`: index popup and text-property highlighting.
- `after/syntax/markdown.vim` extends markdown syntax for underline and checkbox conceal behavior.
- Test harness flow is `test/run_tests.sh` or `test/run_tests.cmd` -> `test/runner.vim` -> `g:TestFiles` list of `test_*.vim` files.

## Key conventions

- **Vim9script-first code style:** modules use `vim9script`, `import autoload`, typed function signatures, and script-local state. Keep new code aligned with this style.
- **Public behavior through `<Plug>` mappings:** `ftplugin/markdown.vim` defines `<Plug>` mappings first, then conditionally binds default `<localleader>` mappings if not already mapped. Preserve this layering when adding features.
- **Configuration via `g:markdown_extras_config`:** feature switches and options are centralized in this dictionary (examples: `use_default_mappings`, `hack_CR`, `smart_textstyle`, `smart_table_format`, `fuzzy_search`, `large_files_threshold`, `pandoc_args`).
- **Reference-link section sentinel is required:** link management routines depend on the exact marker line  
  `<!-- DO NOT REMOVE vim-markdown-extras references DO NOT REMOVE-->`  
  and parse reference definitions after it.
- **Cross-platform path/URL behavior is deliberate:** file links are normalized through `PathToURL()`/`URLToPath()` in `mde_links.vim`; avoid bypassing these helpers for file-link features.
- **Tests follow strict naming and cleanup patterns:** test functions are `def g:Test_*()`, and tests usually clean buffers/files at the end (e.g., `:%bw!` plus cleanup helpers). Keep this pattern to avoid shared-state failures.
