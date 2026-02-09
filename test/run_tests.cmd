@echo off

REM Script to run the unit-tests for the MARKDOWN_EXTRAS Vim plugin on MS-Windows

SETLOCAL
REM Define the paths and files
SET "VIMPRG=vim.exe"
SET "VIMRC=vimrc_for_tests"
SET VIM_CMD=%VIMPRG% --clean -Es -u %VIMRC% -i NONE --not-a-term -S "runner.vim"

REM Create or overwrite the vimrc file with the initial setting
REM

(
    echo vim9script
    echo/
    echo set runtimepath+=..
    echo filetype plugin indent on
    echo syntax on
    echo/
    echo g:TestFiles = [
    echo  'test_markdown_extras.vim',
    echo  'test_utils.vim',
    echo  'test_regex.vim',
    echo  'test_links.vim',
    echo  'test_tables.vim'
    echo ]
) >> "%VIMRC%"


REM Check if the vimrc file was created successfully
if NOT EXIST "%VIMRC%" (
    echo "ERROR: Failed to create %VIMRC%"
    exit /b 1
)

REM Display the contents of VIMRC (for debugging purposes)
echo/
echo ----- dummy_vimrc content -------
type "%VIMRC%"
echo/

REM Run Vim with the specified configuration and additional commands
%VIM_CMD%

REM Check the exit code of Vim command
if %ERRORLEVEL% EQU 0 (
    echo Vim command executed successfully.
) else (
    echo/
    echo ERROR: Vim command failed with exit code %ERRORLEVEL%.
    del %VIMRC%
    exit /b 1
)

REM Check test results
echo ----------------------------------
echo MARKDOWN_EXTRAS unit-test results:
powershell -NoProfile -Command "Get-Content -Encoding UTF8 results.txt"
echo ----------------------------------

REM Check for FAIL in results.txt
findstr /I "FAIL" results.txt > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ERROR: Some test failed.
    del %VIMRC%
    exit /b 1
) else (
    echo SUCCESS: All tests passed.
)
echo/

REM REM Exit script with success
del %VIMRC%
exit /b 0
