@echo off

REM Script to run the unit-tests for the MARKDOWN_EXTRAS Vim plugin on MS-Windows

SETLOCAL
REM Define the paths and files
SET "VIMPRG=vim.exe"
SET "VIMRC=vimrc_for_tests"
SET "VIM_CMD=%VIMPRG% --clean -u %VIMRC% -i NONE"

REM Create or overwrite the vimrc file with the initial setting
REM

(
    echo vim9script
    echo # ---- dummy vimrc file content -----
    echo set nocompatible
    echo set runtimepath+=..
    echo set runtimepath+=../after
    echo autoindent
    echo filetype plugin indent on
    echo # ----------------------------------
) >> "%VIMRC%"

REM Check if the vimrc file was created successfully
if NOT EXIST "%VIMRC%" (
    echo "ERROR: Failed to create %VIMRC%"
    exit /b 1
)

REM Display the contents of VIMRC (for debugging purposes)
type "%VIMRC%"

REM Run Vim with the specified configuration and additional commands
%VIM_CMD% -c "vim9cmd g:TestName = 'test_markdown_extras.vim'" -S "runner.vim"

REM Check the exit code of Vim command
if %ERRORLEVEL% EQU 0 (
    echo Vim command executed successfully.
) else (
    echo ERROR: Vim command failed with exit code %ERRORLEVEL%.
    del %VIMRC%
    exit /b 1
)

REM Check test results
echo MARKDOWN_EXTRAS unit test results:
type results.txt

REM Check for FAIL in results.txt
findstr /I "FAIL" results.txt > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ERROR: Some test failed.
    del %VIMRC%
    exit /b 1
) else (
    echo All tests passed.
)

REM Exit script with success
del %VIMRC%
exit /b 0
