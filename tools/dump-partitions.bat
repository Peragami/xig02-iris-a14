@echo off
rem ============================================================
rem dump-partitions.bat  -  XIG02 (iris) full partition dump
rem
rem Prerequisites:
rem   - Bootloader unlocked, recovery booted via "fastboot boot"
rem     (NOT flashed), device visible from adb in recovery mode.
rem   - Run from cmd.exe. Do NOT redirect binary through
rem     PowerShell (it corrupts binary output).
rem
rem Usage:
rem   dump-partitions.bat [output_dir]
rem   Default output_dir: .\dump
rem
rem Behavior:
rem   - Dumps every partition in /dev/block/by-name except
rem     userdata (encrypted and huge).
rem   - dd runs with conv=noerror,sync so a known unreadable
rem     region (see research/ota-install-error.md) does not
rem     stop the dump; bad blocks are zero-filled and dd's
rem     stderr is kept per partition as <name>.dd.log.
rem   - Records partition size, dumped file size and SHA256
rem     into manifest.txt.
rem ============================================================
setlocal enabledelayedexpansion

set OUT=%~1
if "%OUT%"=="" set OUT=%CD%\dump
if not exist "%OUT%" mkdir "%OUT%"

echo Output: %OUT%

rem --- sanity checks -----------------------------------------
adb get-state 1>nul 2>nul
if errorlevel 1 (
  echo [ABORT] No adb device found. Boot the recovery first.
  exit /b 1
)

adb shell "ls /dev/block/by-name" > "%OUT%\by-name.txt" 2>nul
if errorlevel 1 (
  echo [ABORT] Cannot list /dev/block/by-name.
  exit /b 1
)
findstr /r "." "%OUT%\by-name.txt" >nul
if errorlevel 1 (
  echo [ABORT] /dev/block/by-name looks empty.
  exit /b 1
)

rem --- dmesg before ------------------------------------------
adb shell dmesg > "%OUT%\dmesg-before.txt" 2>nul

rem --- manifest header ----------------------------------------
set MANIFEST=%OUT%\manifest.txt
echo # XIG02 (iris) partition dump> "%MANIFEST%"
echo # format: name partition_bytes file_bytes sha256>> "%MANIFEST%"

rem --- dump loop ----------------------------------------------
for /f "usebackq tokens=* delims=" %%P in ("%OUT%\by-name.txt") do (
  set P=%%P
  call :trim P
  if "!P!"=="" (
    echo Skipping empty line
  ) else if /i not "!P!"=="userdata" (
    call :dump_one "!P!"
  ) else (
    echo Skipping userdata ^(encrypted, not dumped^)
  )
)

rem --- dmesg after --------------------------------------------
adb shell dmesg > "%OUT%\dmesg-after.txt" 2>nul

echo.
echo Done. Check manifest.txt and any *.dd.log with errors.
echo Copy the whole folder to a second location and verify hashes.
exit /b 0

rem ============================================================
:dump_one
set NAME=%~1
set DEV=/dev/block/by-name/%NAME%

for /f "tokens=*" %%S in ('adb shell "blockdev --getsize64 %DEV%" 2^>nul') do set PSIZE=%%S
if "%PSIZE%"=="" set PSIZE=unknown

echo Dumping %NAME% (partition bytes: %PSIZE%) ...
adb exec-out dd if=%DEV% bs=4096 conv=noerror,sync > "%OUT%\%NAME%.img" 2> "%OUT%\%NAME%.dd.log"
if errorlevel 1 (
  echo [WARN] dd returned an error for %NAME% - see %NAME%.dd.log
)

for %%F in ("%OUT%\%NAME%.img") do set FSIZE=%%~zF
if "%FSIZE%"=="0" (
  if not "%PSIZE%"=="0" (
    echo [ABORT] %NAME%.img is empty. exec-out may not work in this recovery. Stop and ask for the fallback method.
    exit /b 1
  )
)

set HASH=
for /f "skip=1 tokens=*" %%H in ('certutil -hashfile "%OUT%\%NAME%.img" SHA256 2^>nul') do (
  if not defined HASH set HASH=%%H
)
set HASH=%HASH: =%

echo %NAME% %PSIZE% %FSIZE% %HASH%>> "%MANIFEST%"
echo   file bytes: %FSIZE%  sha256: %HASH%
goto :eof

rem ============================================================
:trim
rem remove trailing CR/spaces from the variable named %1
for /f "tokens=* delims= " %%A in ("!%1!") do set %1=%%A
goto :eof
