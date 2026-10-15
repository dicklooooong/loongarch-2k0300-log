@echo off
rem ============================================================
rem  First-time push of this learning log to GitHub.
rem  Run this ONCE in a normal terminal (double-click also works).
rem  Requires Git for Windows: https://git-scm.com/download/win
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
git commit -m "chore: 初始化学习日志模板与目录结构" || echo       (nothing to commit, continuing)

echo [5/6] Linking remote: %REPO_URL%
git remote remove origin >nul 2>nul
git remote add origin "%REPO_URL%"
git remote -v

echo [6/6] Pushing to GitHub...
echo       A login window may pop up. Sign in with your GitHub account.
echo       If asked for a password in the terminal, paste a Personal Access
echo       Token (NOT your account password): GitHub > Settings >
echo       Developer settings > Personal access tokens > Contents: Read and write
echo.
git push -u origin main

if errorlevel 1 (
  echo.
  echo [FAILED] Push did not succeed. Check:
  echo   1. The remote repository exists and is EMPTY (no README added on GitHub).
  echo   2. You are authenticated: run  git config --global credential.helper manager
  echo      then retry, or clear cached credentials in Windows Credential Manager.
  echo   3. Run  git pull --rebase origin main  if the remote already has commits.
  echo.
) else (
  echo.
  echo [OK] Done. Your log is now at:
  echo      https://github.com/dicklooooong/loongarch-2k0300-log
  echo.
  echo From now on, publish daily updates with three commands:
  echo      git add .
  echo      git commit -m "log(daily): YYYY-MM-DD topic"
  echo      git push
  echo.
)
pause
