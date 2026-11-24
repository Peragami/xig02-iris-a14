@echo off
rem ============================================================
rem restore-partitions.bat  -  XIG02 (iris) restore to stock
rem
rem Restores partitions from a dump folder produced by
rem dump-partitions.bat, returning the device to the stock
rem state captured in that dump (V14.0.23.0).
rem
rem Prerequisites:
rem   - Bootloader unlocked (NEVER re-lock; see docs/restore.md)
rem   - Device in fastboot mode, connected directly by USB
rem   - Battery 50% or more
rem   - Run from cmd.exe
rem
rem Usage:
rem   restore-partitions.bat [dump_dir] [WRITE]
rem   Default dump_dir: .\dump
rem   Without WRITE this is a DRY RUN: it only verifies the
rem   dump against manifest.txt and prints the flash plan.
rem   With WRITE it flashes after a typed confirmation.
rem
rem Safety rules (docs/restore.md, safety.md):
rem   - Aborts unless fastboot reports product = iris.
rem   - Aborts if any file is missing, size differs, or its
rem     SHA256 does not match manifest.txt.
rem   - Logical partitions (system, system_ext, product,
rem     vendor, odm) are NOT flashed individually: they live
rem     inside "super", which is flashed as a whole. The dump
rem     must contain super, otherwise the restore is
rem     incomplete and the script aborts.
rem   - userdata is not part of the dump and is never touched.
rem     User data does not come back (unlock already wiped it).
rem   - If any *.dd.log in the dump contains read errors, the
rem     dump has zero-filled regions; WRITE then needs an
rem     extra confirmation (type RESTORE).
rem ============================================================
setlocal enabledelayedexpansion

set DUMP=%~1
if "%DUMP%"=="" set DUMP=%CD%\dump
set MODE=%~2

set MANIFEST=%DUMP%\manifest.txt
if not exist "%MANIFEST%" (
  echo [ABORT] manifest.txt not found in %DUMP%
  exit /b 1
)

echo Dump folder: %DUMP%
if /i "%MODE%"=="WRITE" (echo Mode: WRITE) else (echo Mode: DRY RUN - verification only, nothing is flashed)

rem --- device checks ------------------------------------------
fastboot devices 1>nul 2>nul
if errorlevel 1 (
  echo [ABORT] fastboot not working.
  exit /b 1
)
set PROD=
for /f "tokens=2 delims= " %%V in ('fastboot getvar product 2^>^&1 ^| findstr /b "product:"') do set PROD=%%V
if /i not "%PROD%"=="iris" (
  echo [ABORT] product is "%PROD%", not iris. Wrong device.
  exit /b 1
)
echo Device check OK: product = iris

rem --- dump read-error scan ------------------------------------
set WARNDUMP=0
for %%L in ("%DUMP%\*.dd.log") do (
  findstr /i /c:"error" "%%L" >nul 2>nul
  if not errorlevel 1 set WARNDUMP=1
)
if "%WARNDUMP%"=="1" (
  echo [WARN] Some *.dd.log files contain read errors.
  echo [WARN] That dump has zero-filled regions and a restore
  echo [WARN] from it may not be perfect. See docs/restore.md.
)

rem --- verify every manifest entry ------------------------------
set FAIL=0
set HAS_SUPER=0
for /f "eol=# tokens=1,2,3,4" %%A in (%MANIFEST%) do (
  set NAME=%%A
  set FSIZE=%%C
  set HASH=%%D
  if /i "!NAME!"=="super" set HAS_SUPER=1
  call :verify_one "!NAME!" "!FSIZE!" "!HASH!"
)
if "%HAS_SUPER%"=="0" (
  echo [ABORT] super is not in the manifest. Restore would be incomplete.
  exit /b 1
)
if "%FAIL%"=="1" (
  echo [ABORT] Dump verification failed. Do NOT restore from this dump.
  exit /b 1
)
echo Verification OK: all files match manifest.txt.

rem --- flash plan ----------------------------------------------
echo.
echo Flash plan ^(logical partitions are inside super, skipped^):
for /f "eol=# tokens=1" %%A in (%MANIFEST%) do (
  call :plan_one "%%A"
)

if /i not "%MODE%"=="WRITE" (
  echo.
  echo DRY RUN finished. Re-run with WRITE at the end to flash.
  exit /b 0
)

rem --- confirmation ----------------------------------------------
echo.
echo This will overwrite the current partitions with the stock dump.
echo The bootloader stays unlocked. User data does not come back.
if "%WARNDUMP%"=="1" (
  set /p CONFIRM=Dump has read-error regions. Type RESTORE to continue:
  if not "!CONFIRM!"=="RESTORE" (echo Aborted. & exit /b 1)
) else (
  set /p CONFIRM=Type YES to continue:
  if not "!CONFIRM!"=="YES" (echo Aborted. & exit /b 1)
)

rem --- flash ------------------------------------------------------
for /f "eol=# tokens=1" %%A in (%MANIFEST%) do (
  call :flash_one "%%A"
  if errorlevel 1 (
    echo [ABORT] Flashing stopped at %%A. Do not reboot into the system;
    echo stay in fastboot and ask for guidance.
    exit /b 1
  )
)

echo.
echo All partitions flashed. Rebooting.
fastboot reboot
echo After reboot, verify it boots into stock MIUI.
echo If it bootloops, boot recovery and factory reset, then retry.
exit /b 0

rem ============================================================
:verify_one
set VNAME=%~1
set VSIZE=%~2
set VHASH=%~3
set VFILE=%DUMP%\%VNAME%.img
if not exist "%VFILE%" (
  echo [FAIL] %VNAME%.img is missing.
  set FAIL=1
  goto :eof
)
for %%F in ("%VFILE%") do set ASIZE=%%~zF
if not "!ASIZE!"=="%VSIZE%" (
  echo [FAIL] %VNAME%: size differs - manifest %VSIZE%, actual !ASIZE!
  set FAIL=1
  goto :eof
)
set AHASH=
for /f "skip=1 tokens=*" %%H in ('certutil -hashfile "%VFILE%" SHA256 2^>nul') do (
  if not defined AHASH set AHASH=%%H
)
set AHASH=%AHASH: =%
if /i not "!AHASH!"=="%VHASH%" (
  echo [FAIL] %VNAME%: SHA256 differs from manifest.
  set FAIL=1
  goto :eof
)
goto :eof

rem ============================================================
:is_logical
rem sets LOGICAL=1 for partitions contained in super
set LOGICAL=0
set BASE=%~1
if /i "%BASE:~-2%"=="_a" set BASE=%BASE:~0,-2%
if /i "%BASE:~-2%"=="_b" set BASE=%BASE:~0,-2%
if /i "%BASE%"=="system" set LOGICAL=1
if /i "%BASE%"=="system_ext" set LOGICAL=1
if /i "%BASE%"=="product" set LOGICAL=1
if /i "%BASE%"=="vendor" set LOGICAL=1
if /i "%BASE%"=="odm" set LOGICAL=1
goto :eof

rem ============================================================
:plan_one
call :is_logical "%~1"
if "%LOGICAL%"=="1" (
  echo   skip  %~1 ^(inside super^)
) else (
  echo   flash %~1
)
goto :eof

rem ============================================================
:flash_one
call :is_logical "%~1"
if "%LOGICAL%"=="1" goto :eof
echo Flashing %~1 ...
fastboot flash %~1 "%DUMP%\%~1.img"
if errorlevel 1 exit /b 1
goto :eof
