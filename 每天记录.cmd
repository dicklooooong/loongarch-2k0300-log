@echo off
rem ============================================================
rem  DAILY ROUTINE - double-click this file only.
rem    1. creates/opens today's log in an editor
rem    2. after you save and close it, commits and pushes to GitHub
rem  Keep this file ASCII-only: cmd.exe reads .cmd as ANSI.
rem ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0daily.ps1" %*
echo.
pause
