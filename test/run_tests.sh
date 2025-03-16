#!/bin/bash

# Script to run the unit-tests for the vim-markdown_extras.vim
# Copied and adapted from Vim LSP plugin

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

echo "vim9script" > "$VIMRC"
echo "">> "$VIMRC"
echo "set runtimepath+=.." >> "$VIMRC"
echo "set runtimepath+=../after"  >> "$VIMRC"
echo "filetype indent plugin on" >> "$VIMRC"
echo "syntax on" >> "$VIMRC"

# Display vimrc content
echo "----- vimrc content ---------"
cat $VIMRC
echo ""
# Construct the VIM_CMD with correct variable substitution and quoting
VIM_CMD="$VIM_PRG --clean -Es -u $VIMRC -i NONE --not-a-term"

# Add test files here:
TESTS=('test_markdown_extras.vim' 'test_utils.vim' 'test_regex.vim')

# convert bash list to Vim list
TESTS_STRING=$(printf "'%s', " "${TESTS[@]}")
TESTS_STRING=${TESTS_STRING%, }  # Remove trailing comma

eval $VIM_CMD " -c \"vim9cmd g:TestName = [$TESTS_STRING]\" -S runner.vim"

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
