@echo off
rem One-click publish: commit all changes and push to GitHub.
rem Usage:  publish.cmd "short topic"
rem         publish.cmd                 (will ask for the topic)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1" %*
if errorlevel 1 pause
