@echo off
setlocal
title Floony Macro Updater

rem ===============================================================
rem  SETTINGS
rem ===============================================================
set "REPO_ZIP=https://github.com/JamesAT/ArcCreate-Floony-Macro/archive/refs/heads/main.zip"

set "TARGET=%~dp0"

rem The downloaded files are kept right next to this file (not in AppData).
rem The folder is deleted again when the updater ends (Install or Cancel).
set "WORK=%TARGET%floony_update_temp"

rem The backup of your old version goes one folder ABOVE the Macros folder.
rem (A backup inside Macros could be loaded by ArcCreate as a second copy of the macros.)
for %%I in ("%TARGET%..") do set "BACKUP=%%~fI\floony_backup"

set "CHANGELOG=floony\other\misc\changelog.lua"

rem ===============================================================
rem  DOWNLOAD
rem ===============================================================
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

rem What the PowerShell part (at the bottom of this file) needs to know.
set "FL_SRC=%SRC%\floony"
set "FL_DST=%TARGET%floony"
set "FL_SRC_LUA=%SRC%\floony.lua"
set "FL_DST_LUA=%TARGET%floony.lua"
set "FL_ZIP=%WORK%\update.zip"

rem ===============================================================
rem  VERSIONS
rem ===============================================================
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

rem ===============================================================
rem  MENU
rem ===============================================================
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
set "FL_MODE=test"
call :runps
if errorlevel 1 goto :test_failed
echo.
echo [TEST DONE] Everything worked. Nothing was changed.
echo The downloaded files are in: %WORK%
echo They are deleted when you choose Install or Cancel.
goto :menu

:test_failed
echo.
echo [TEST FAILED] See the message above.
goto :menu

:install
echo.
echo Saving a backup of your current macros...
call :backup
if errorlevel 1 goto :fail_backup

echo Installing...
set "FL_MODE=install"
call :runps
if errorlevel 1 goto :fail_copy

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

rem ===============================================================
rem  ERRORS (the downloaded files are always removed)
rem ===============================================================
:fail_download
if exist "%WORK%" rmdir /s /q "%WORK%"
echo.
echo [FAILED] The download did not work. Check your internet connection,
echo and make sure the GitHub repo is public.
pause
exit /b 1

:fail_layout
if exist "%WORK%" rmdir /s /q "%WORK%"
echo.
echo [FAILED] The download worked, but the files are not where the updater expects them.
echo It needs floony.lua and a floony folder at the top level of the repo.
pause
exit /b 1

:fail_backup
if exist "%WORK%" rmdir /s /q "%WORK%"
echo.
echo [FAILED] The backup could not be saved, so nothing was installed.
echo Close ArcCreate and try again.
pause
exit /b 1

:fail_copy
if exist "%WORK%" rmdir /s /q "%WORK%"
echo.
echo [FAILED] Could not install the files. See the message above.
echo Close ArcCreate and try again.
echo Your backup is in: %BACKUP%
pause
exit /b 1

rem ---------------------------------------------------------------
rem :backup
rem Saves the installed floony folder and floony.lua. Only the latest backup is kept.
rem Gives errorlevel 1 when something could not be saved.
rem ---------------------------------------------------------------
:backup
if not exist "%BACKUP%" mkdir "%BACKUP%"
if exist "%TARGET%floony\" (
    robocopy "%TARGET%floony" "%BACKUP%\floony" /MIR /NFL /NDL /NJH /NJS /NP >nul
    if errorlevel 8 exit /b 1
)
if exist "%TARGET%floony.lua" (
    copy /y "%TARGET%floony.lua" "%BACKUP%\floony.lua" >nul
    if errorlevel 1 exit /b 1
)
exit /b 0

rem ---------------------------------------------------------------
rem :runps
rem Runs the PowerShell part found at the bottom of this file (between the BEGIN and END marker lines).
rem It is saved as a normal .ps1 file in the work folder first, so you can open and read it there.
rem FL_MODE says what it does: "test" (changes nothing) or "install".
rem ---------------------------------------------------------------
:runps
set "FL_SELF=%~f0"
set "FL_PS1=%WORK%\floony_helper.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:FL_SELF); $a=$t.LastIndexOf('#PS-'+'BEGIN'); $b=$t.LastIndexOf('#PS-'+'END'); [IO.File]::WriteAllText($env:FL_PS1, $t.Substring($a,$b-$a))"
if errorlevel 1 exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File "%FL_PS1%"
exit /b

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

rem ===============================================================
rem  Nothing below this line is run by the batch file itself.
rem  The text between the BEGIN and END lines is the PowerShell part (see :runps).
rem ===============================================================
#PS-BEGIN
# ---------------------------------------------------------------
# PowerShell part of the updater.
# It compares the downloaded files with the installed ones, and copies only what is needed.
# A file with the same name AND the same content is called 'identical' and is skipped.
# ---------------------------------------------------------------
$ErrorActionPreference = 'Stop'

# A size the way the File Explorer 'Properties' window shows it, for example: 12.3 KB (12,598 bytes)
function Format-Size([long]$bytes) {
    if ($bytes -lt 1024) { return ('{0:N0} bytes' -f $bytes) }
    if ($bytes -lt 1MB)  { return ('{0:N1} KB ({1:N0} bytes)' -f ($bytes / 1KB), $bytes) }
    return ('{0:N2} MB ({1:N0} bytes)' -f ($bytes / 1MB), $bytes)
}

# Every file under a folder. The key is the lower-case path inside the folder.
function Get-FileMap([string]$folder) {
    $map = @{}
    if (Test-Path -LiteralPath $folder) {
        $root = (Get-Item -LiteralPath $folder).FullName.TrimEnd('\')
        Get-ChildItem -LiteralPath $root -Recurse -File -Force | ForEach-Object {
            $rel = $_.FullName.Substring($root.Length + 1)
            $map[$rel.ToLower()] = @{ Rel = $rel; Path = $_.FullName; Size = $_.Length; OldSize = 0 }
        }
    }
    return $map
}

# True when two files are the same: same size AND same content.
# (The size alone is not enough: changing one number in a file keeps its size.)
function Test-SameFile([string]$a, [string]$b) {
    if ((Get-Item -LiteralPath $a).Length -ne (Get-Item -LiteralPath $b).Length) { return $false }
    $hashA = (Get-FileHash -LiteralPath $a -Algorithm SHA256).Hash
    $hashB = (Get-FileHash -LiteralPath $b -Algorithm SHA256).Hash
    return ($hashA -eq $hashB)
}

# Sorts the files of the download into: New, Changed, Same (identical) and Extra (installed but not in the download).
function New-Plan([string]$srcDir, [string]$dstDir) {
    $src = Get-FileMap $srcDir
    $dst = Get-FileMap $dstDir
    $plan = @{ New = @(); Changed = @(); Same = @(); Extra = @() }

    foreach ($key in ($src.Keys | Sort-Object)) {
        $file = $src[$key]
        if (-not $dst.ContainsKey($key)) {
            $plan.New += $file
        }
        elseif (Test-SameFile $file.Path $dst[$key].Path) {
            $plan.Same += $file
        }
        else {
            $file.OldSize = $dst[$key].Size
            $plan.Changed += $file
        }
    }

    foreach ($key in ($dst.Keys | Sort-Object)) {
        if (-not $src.ContainsKey($key)) { $plan.Extra += $dst[$key] }
    }
    return $plan
}

# 'new', 'same' or 'changed' for one single file (floony.lua).
function Get-SingleStatus([string]$srcFile, [string]$dstFile) {
    if (-not (Test-Path -LiteralPath $dstFile)) { return 'new' }
    if (Test-SameFile $srcFile $dstFile) { return 'same' }
    return 'changed'
}

# TEST: only shows what an install would do.
function Invoke-Test {
    Write-Host ('[OK] Download finished: ' + (Format-Size (Get-Item -LiteralPath $env:FL_ZIP).Length))
    Write-Host '[OK] Found floony.lua and the floony folder'

    $plan = New-Plan $env:FL_SRC $env:FL_DST
    $all = @($plan.New) + @($plan.Changed) + @($plan.Same)
    $luaCount = @($all | Where-Object { $_.Rel -like '*.lua' }).Count
    Write-Host ('[OK] The update contains ' + $luaCount + ' .lua files inside the floony folder.')

    Write-Host ''
    Write-Host 'What installing would do in your floony folder:'
    Write-Host '  New = added | Changed = replaced | EXTRA = deleted | identical files are skipped'
    foreach ($f in $plan.New)     { Write-Host ('    New      ' + $f.Rel + '   ' + (Format-Size $f.Size)) }
    foreach ($f in $plan.Changed) { Write-Host ('    Changed  ' + $f.Rel + '   ' + (Format-Size $f.OldSize) + ' -> ' + (Format-Size $f.Size)) }
    foreach ($f in $plan.Extra)   { Write-Host ('    EXTRA    ' + $f.Rel + '   ' + (Format-Size $f.Size)) }
    Write-Host ('  ' + $plan.New.Count + ' new, ' + $plan.Changed.Count + ' changed, ' +
                $plan.Same.Count + ' identical (skipped), ' + $plan.Extra.Count + ' would be deleted')

    $status = Get-SingleStatus $env:FL_SRC_LUA $env:FL_DST_LUA
    if ($status -eq 'same') {
        Write-Host 'floony.lua is identical (skipped).'
    } elseif ($status -eq 'new') {
        Write-Host 'floony.lua would be added.'
    } else {
        Write-Host 'floony.lua would be replaced.'
    }
}

# INSTALL: copies the new and changed files, skips the identical ones, removes the old ones.
function Invoke-Install {
    $srcDir = $env:FL_SRC
    $dstDir = $env:FL_DST
    $plan = New-Plan $srcDir $dstDir

    # Safety: nothing is deleted unless the download really has files and the target is the 'floony' folder.
    $total = $plan.New.Count + $plan.Changed.Count + $plan.Same.Count
    if ($total -eq 0) { throw 'The downloaded floony folder is empty.' }
    if ((Split-Path -Leaf $dstDir) -ne 'floony') { throw 'The target folder is not named floony.' }

    $copied = 0
    foreach ($file in ($plan.New + $plan.Changed)) {
        $target = Join-Path $dstDir $file.Rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $file.Path -Destination $target -Force
        $copied++
    }

    foreach ($file in $plan.Extra) {
        Remove-Item -LiteralPath $file.Path -Force
    }

    # Remove folders that are empty now (deepest first).
    if (Test-Path -LiteralPath $dstDir) {
        Get-ChildItem -LiteralPath $dstDir -Recurse -Directory -Force |
            Sort-Object { $_.FullName.Length } -Descending |
            Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0 } |
            Remove-Item
    }

    # floony.lua
    $status = Get-SingleStatus $env:FL_SRC_LUA $env:FL_DST_LUA
    if ($status -ne 'same') {
        Copy-Item -LiteralPath $env:FL_SRC_LUA -Destination $env:FL_DST_LUA -Force
    }

    Write-Host ('[OK] ' + $plan.New.Count + ' new and ' + $plan.Changed.Count + ' changed file(s) installed.')
    Write-Host ('[OK] ' + $plan.Same.Count + ' identical file(s) skipped.')
    if ($plan.Extra.Count -gt 0) {
        Write-Host ('[OK] ' + $plan.Extra.Count + ' old file(s) removed.')
    }
    if ($status -eq 'same') {
        Write-Host '[OK] floony.lua is identical (skipped).'
    } else {
        Write-Host '[OK] floony.lua installed.'
    }
}

try {
    if ($env:FL_MODE -eq 'install') { Invoke-Install } else { Invoke-Test }
}
catch {
    Write-Host ('[FAILED] ' + $_.Exception.Message)
    exit 1
}
#PS-END
