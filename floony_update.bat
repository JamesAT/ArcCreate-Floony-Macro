@echo off
setlocal
title Floony Macro Updater

set "REPO_ZIP=https://github.com/JamesAT/ArcCreate-Floony-Macro/archive/refs/heads/main.zip"

set "TARGET=%~dp0"
set "WORK=%TEMP%\floony_update"
set "BACKUP=%TARGET%..\floony_backup"
set "CHANGELOG=floony\other\misc\changelog.lua"

echo Checking for updates...
if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%REPO_ZIP%' -OutFile '%WORK%\update.zip' -UseBasicParsing; Expand-Archive -Path '%WORK%\update.zip' -DestinationPath '%WORK%\src' -Force } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 goto :fail_download

rem The zip contains one folder (ArcCreate-Floony-Macro-main). Find it.
set "SRC="
for /d %%D in ("%WORK%\src\*") do set "SRC=%%D"
if not defined SRC goto :fail_layout
if not exist "%SRC%\floony.lua" goto :fail_layout
if not exist "%SRC%\floony\" goto :fail_layout

rem Read the newest version from each changelog (the first addChangelog entry is the latest).
set "LOCAL_VER_N="
set "REMOTE_VER_N="
call :getver "%TARGET%%CHANGELOG%" LOCAL_VER "not installed"
call :getver "%SRC%\%CHANGELOG%" REMOTE_VER "unknown"

echo.
echo ================================================
echo   Installed version : %LOCAL_VER%
echo   Latest version    : %REMOTE_VER%
echo ================================================
if not defined REMOTE_VER_N goto :msg_unknown
if not defined LOCAL_VER_N goto :msg_new
call :cmpver "%LOCAL_VER_N%" "%REMOTE_VER_N%"
if "%CMP%"=="0" goto :msg_same
if "%CMP%"=="1" goto :msg_egg

:msg_new
echo A new update is available!
goto :menu

:msg_unknown
echo Could not read the latest version from the changelog.
goto :menu

:msg_same
echo You already have the latest version. You can still reinstall it.
goto :menu

:msg_egg
echo.
echo   Hold on... your version is NEWER than the latest release!
echo   Either you are cooking up the next update, or you came from the future.
echo   Installing now would roll your macros BACK to the older version.
goto :menu

:menu
echo.
echo   [I] Install the update
echo   [T] Test only (checks everything, changes nothing)
echo   [C] Cancel
echo.
choice /c ITC /n /m "Your choice: "
if errorlevel 3 goto :cancel
if errorlevel 2 goto :test
if errorlevel 1 goto :install
goto :menu

:test
echo.
echo ---------------- TEST (nothing is changed) ----------------
for %%F in ("%WORK%\update.zip") do echo [OK] Download finished: %%~zF bytes
echo [OK] Found floony.lua and the floony folder
set "COUNT=0"
for /f %%N in ('dir /s /b "%SRC%\floony\*.lua" ^| find /c /v ""') do set "COUNT=%%N"
echo [OK] The update contains %COUNT% .lua files inside the floony folder.
echo.
echo What installing would do in your floony folder:
echo   New = added, Newer/Older = replaced, EXTRA = deleted
robocopy "%SRC%\floony" "%TARGET%floony" /MIR /L /NJH /NJS /NP /NDL
echo floony.lua would also be replaced.
echo.
echo [TEST DONE] Everything worked. Nothing was changed.
echo Downloaded files for you to look at: %SRC%
goto :menu

:install
echo.
echo Saving a backup of your current macros...
if exist "%TARGET%floony\" robocopy "%TARGET%floony" "%BACKUP%\floony" /MIR /NFL /NDL /NJH /NJS /NP >nul
if exist "%TARGET%floony.lua" copy /y "%TARGET%floony.lua" "%BACKUP%\floony.lua" >nul

echo Installing...
copy /y "%SRC%\floony.lua" "%TARGET%floony.lua" >nul
if errorlevel 1 goto :fail_copy
robocopy "%SRC%\floony" "%TARGET%floony" /MIR /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 goto :fail_copy

rmdir /s /q "%WORK%"
echo.
echo Done! Now go to ArcCreate and click "Reload macro scripts".
echo (Your old version is saved in: %BACKUP%)
pause
exit /b 0

:cancel
rmdir /s /q "%WORK%"
echo Nothing was changed.
pause
exit /b 0

:fail_download
echo.
echo [FAILED] The download did not work. Check your internet connection,
echo and make sure the GitHub repo is public.
pause
exit /b 1

:fail_layout
echo.
echo [FAILED] The download worked, but the files are not where the updater expects them.
echo It needs floony.lua and a floony folder at the top level of the repo.
echo Downloaded files are in: %WORK%
pause
exit /b 1

:fail_copy
echo.
echo [FAILED] Could not copy the files. Close ArcCreate and try again.
echo Your backup (if one was made) is in: %BACKUP%
pause
exit /b 1

rem ---------------------------------------------------------------
rem :getver "<changelog.lua path>" <VARIABLE NAME> "<text if not found>"
rem Sets <VARIABLE NAME> to "<version> (<date>)" and <VARIABLE NAME>_N to just "<version>".
rem ---------------------------------------------------------------
:getver
set "%~2=%~3"
set "%~2_N="
if not exist "%~1" exit /b
set "FILEPATH=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m=[regex]::Match((Get-Content -Raw -LiteralPath $env:FILEPATH),'addChangelog\(\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]\s*,\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]'); if($m.Success){$m.Groups[1].Value + '|' + $m.Groups[2].Value}" > "%WORK%\ver.tmp" 2>nul
for /f "usebackq tokens=1,2 delims=|" %%A in ("%WORK%\ver.tmp") do (
    set "%~2_N=%%A"
    set "%~2=%%A (%%B)"
)
exit /b

rem ---------------------------------------------------------------
rem :cmpver "<version A>" "<version B>"
rem Compares component by component (Major.Minor.Patch) from left to right.
rem Sets CMP to -1 (A is older), 0 (same) or 1 (A is newer).
rem ---------------------------------------------------------------
:cmpver
set "CMP="
set "VA=%~1"
set "VB=%~2"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $a = [regex]::Matches($env:VA, '\d+') | ForEach-Object { [int]$_.Value }; $b = [regex]::Matches($env:VB, '\d+') | ForEach-Object { [int]$_.Value }; $max = [math]::Max($a.Count, $b.Count); $res = 0; for ($i = 0; $i -lt $max; $i++) { $valA = if ($i -lt $a.Count) { $a[$i] } else { 0 }; $valB = if ($i -lt $b.Count) { $b[$i] } else { 0 }; if ($valA -gt $valB) { $res = 1; break }; if ($valA -lt $valB) { $res = -1; break } }; Write-Output $res } catch { }" > "%WORK%\cmp.tmp" 2>nul
set /p CMP=<"%WORK%\cmp.tmp"
exit /b