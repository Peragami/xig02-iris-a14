@echo off
rem ============================================================
rem dump-partitions.bat  -  XIG02 (iris) full partition dump
rem
rem Prerequisites:
rem   - Bootloader unlocked, a recovery (TWRP) running on the
rem     device, visible from adb in recovery mode.
rem     NOTE: this device's bootloader does NOT support
rem     "fastboot boot" (unknown command). TWRP was started by
rem     flashing it to the INACTIVE slot's boot (boot_a) and
rem     switching the active slot - see
rem     research/boot-a-twrp-safety.md.
rem   - Run from cmd.exe. Do NOT redirect binary through
rem     PowerShell (it corrupts binary output).
rem
rem Usage:
rem   dump-partitions.bat [output_dir]
rem   Default output_dir: .\dump
rem
rem Behavior:
rem   - Dumps every partition in /dev/block/by-name except
rem     userdata (encrypted and huge) and the whole-disk
rem     entries sda-sdf (they duplicate all partitions and
rem     would take hours / tens of GB).
rem   - dd runs with conv=noerror,sync so a known unreadable
rem     region (see research/ota-install-error.md) does not
rem     stop the dump; bad blocks are zero-filled.
rem   - dd's stderr is redirected ON THE DEVICE to
rem     /tmp/dd-err.txt and then copied to <name>.dd.log.
rem     (With adb exec-out, device stderr otherwise leaks
rem     into the binary stream and appends ~100 bytes of
rem     dd status text to every .img - found 2026-11-25.)
rem   - Records partition size, dumped file size and SHA256
rem     into manifest.txt. File size must equal partition
rem     size; a mismatch is warned about.
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
  ) else (
    call :is_skipped "!P!"
    if "!SKIP!"=="1" (
      echo Skipping !P! ^(excluded by design^)
    ) else (
      call :dump_one "!P!"
      if errorlevel 1 goto :fatal_error
    )
  )
)

rem --- dmesg after --------------------------------------------
adb shell dmesg > "%OUT%\dmesg-after.txt" 2>nul

echo.
echo Done. Check manifest.txt and any *.dd.log with errors.
echo Copy the whole folder to a second location and verify hashes.
exit /b 0

:fatal_error
echo.
echo [STOPPED] A partition dump failed fatally. See messages above.
exit /b 1

rem ============================================================
:is_skipped
rem %1 = partition name. Sets SKIP=1 for userdata and the
rem whole-disk LUN entries sda..sdf.
set SKIP=0
if /i "%~1"=="userdata" set SKIP=1
for %%L in (sda sdb sdc sdd sde sdf) do (
  if /i "%~1"=="%%L" set SKIP=1
)
goto :eof

rem ============================================================
:dump_one
set NAME=%~1
set DEV=/dev/block/by-name/%NAME%

set PSIZE=
for /f "tokens=*" %%S in ('adb shell "blockdev --getsize64 %DEV%" 2^>nul') do set PSIZE=%%S
if "%PSIZE%"=="" set PSIZE=unknown

echo Dumping %NAME% (partition bytes: %PSIZE%) ...
adb exec-out "dd if=%DEV% bs=4096 conv=noerror,sync 2>/tmp/dd-err.txt" > "%OUT%\%NAME%.img"
if errorlevel 1 (
  echo [WARN] dd returned an error for %NAME% - see %NAME%.dd.log
)
adb shell "cat /tmp/dd-err.txt" > "%OUT%\%NAME%.dd.log" 2>nul

set FSIZE=0
for %%F in ("%OUT%\%NAME%.img") do set FSIZE=%%~zF
if "%FSIZE%"=="0" (
  if not "%PSIZE%"=="0" (
    echo [ABORT] %NAME%.img is empty. exec-out may not work in this recovery. Stop and ask for the fallback method.
    exit /b 1
  )
)
if not "%PSIZE%"=="unknown" (
  if not "%FSIZE%"=="%PSIZE%" (
    echo [WARN] Size mismatch for %NAME%: partition %PSIZE% vs file %FSIZE%. Check %NAME%.dd.log.
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
