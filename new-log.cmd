@echo off
rem Double-click this file to create today's learning log.
rem The -ExecutionPolicy Bypass flag keeps it working even when script
rem execution is disabled for the current user.
rem Usage with arguments: new-log.cmd -Date 2026-10-01
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0new-log.ps1" %*
if errorlevel 1 pause
