@echo off
start "Run Start" powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\run-start.ps1"
start "Flash Device" powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\flash-device.ps1"