#!/bin/bash

GITHUB=1

# No arguments passed, then no exit
if [ "$#" -eq 0 ]; then
  GITHUB=0
fi

VIM_PRG=${VIM_PRG:=$(which vim)}

if [ -z "$VIM_PRG" ]; then
  echo "ERROR: vim (\$VIM_PRG) is not found in PATH"
  if [ "$GITHUB" -eq 1 ]; then
	exit 1
  fi
fi

# Setup dummy VIMRC file
# OBS: You can also run the following lines in the test file because it is
# source before running the tests anyway. See Vim9-conversion-aid
VIMRC="VIMRC"

tmp="$(mktemp "${VIMRC}.XXXX")"

cat >"$tmp" <<'EOF' &&
vim9script

set runtimepath+=..
filetype indent plugin on
syntax on

g:TestFiles = [
	'test_markdown_extras.vim',
	'test_utils.vim',
	'test_regex.vim',
	'test_tables.vim',
	'test_links.vim'
  ]
EOF

mv "$tmp" "$VIMRC"

# Display vimrc content
echo "----- vimrc content ---------"
cat $VIMRC
echo ""

VIM_CMD=(
    "$VIM_PRG"
    --clean
		-Es
    -u "$VIMRC"
    -i NONE
    --not-a-term
    -S runner.vim
)

# Execute Vim
"${VIM_CMD[@]}"

# Check that Vim started and that the runner did its job
if [ $? -eq 0 ]; then
    echo "Vim executed successfully.\n"
else
    echo "Vim execution failed with exit code $?.\n"
		exit 1
fi

# Check the test results
cat results.txt
echo "-------------------------------"
if grep -qw FAIL results.txt; then
	echo "ERROR: Some test(s) failed."
	echo
	if [ "$GITHUB" -eq 1 ]; then
		rm "$VIMRC"
		rm results.txt
		exit 3
	fi
else
	echo "SUCCESS: All the tests  passed."
	echo
	rm "$VIMRC"
	rm results.txt
	exit 0
fi

# kill %- > /dev/null
# vim: shiftwidth=2 softtabstop=2 noexpandtab
