@echo off
rem ============================================================
rem  Set up this log repository on a NEW machine and push it.
rem  Run this ONCE (double-click also works).
rem  Requires Git for Windows: https://git-scm.com/download/win
rem  NOTE: keep all text in this file ASCII-only. cmd.exe reads .cmd
rem        as ANSI, so UTF-8 Chinese here would break the script.
rem ============================================================
setlocal
set "REPO_URL=https://github.com/dicklooooong/loongarch-2k0300-log.git"
cd /d "%~dp0"

where git >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Git not found in PATH.
  echo         Install it first: https://git-scm.com/download/win
  echo         After installing, CLOSE this window, open a NEW one, and run again.
  pause
  exit /b 1
)

echo [1/6] Checking git identity...
for /f "delims=" %%i in ('git config --global user.name') do set "GITNAME=%%i"
if "%GITNAME%"=="" (
  echo       Not configured yet. Please enter your details:
  set /p "NAME=      GitHub name : "
  set /p "MAIL=      GitHub email: "
  git config --global user.name "%NAME%"
  git config --global user.email "%MAIL%"
)
git config --global init.defaultBranch main >nul 2>nul
git config --global core.quotepath false >nul 2>nul
git config --global credential.helper manager >nul 2>nul

echo [2/6] Initializing repository...
if not exist ".git" (
  git init || (echo [ERROR] git init failed & pause & exit /b 1)
)
git branch -M main

echo [3/6] Staging files...
git add -A

echo [4/6] Creating the first commit...
git commit -m "chore: init learning log structure and templates" || echo       nothing to commit, continuing

echo [5/6] Linking remote: %REPO_URL%
git remote remove origin >nul 2>nul
git remote add origin "%REPO_URL%"
git remote -v

echo [6/6] Pushing to GitHub...
echo       A login window may pop up. Sign in with your GitHub account.
echo       If asked for a password in the terminal, paste a Personal Access
echo       Token (NOT your account password): GitHub ^> Settings ^>
echo       Developer settings ^> Personal access tokens ^> Contents: Read and write
echo.
git push -u origin main

if errorlevel 1 (
  echo.
  echo [FAILED] Push did not succeed. Check:
  echo   1. You are authenticated: git config --global credential.helper manager
  echo   2. The remote already has commits: run  git pull --rebase origin main
  echo      then push again. Do NOT force push unless you mean to.
  echo.
) else (
  echo.
  echo [OK] Done. Your log is at:
  echo      https://github.com/dicklooooong/loongarch-2k0300-log
  echo.
  echo Daily routine: double-click new-log.cmd to write, publish.cmd to upload.
  echo.
)
pause
