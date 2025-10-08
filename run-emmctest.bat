@echo off
setlocal

set "targetIp=192.168.222.1"
set "fioCommand=fio --name=seq_read --rw=read --bs=1M --size=1G --direct=1 --iodepth=64 --filename=/dev/mmcblk2 --group_reporting"
set "tmpFile=fio_result.tmp"

echo "Starting device with sunxi-fel..."
start "sunxi-fel" sunxi-fel.exe -p uboot u-boot-sunxi-with-spl.bin write 0x45000000 openwrt-sunxi-cortexa7-friendlyarm_nanopi-neo-air-initramfs-kernel.bin write 0x48000000 dtb write 0x49000000 boot.scr

echo "Waiting for device to boot..."
timeout /t 15 /nobreak >nul

:waitForDevice
echo "Searching for device at %targetIp%..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@%targetIp% "echo Device found" >nul 2>nul
if %errorlevel% neq 0 (
    echo "Device not found, retrying in 5 seconds..."
    timeout /t 5 /nobreak >nul
    goto waitForDevice
)

echo "Device is online. Running I/O test... This may take a moment."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@%targetIp% "%fioCommand%" > %tmpFile% 2>&1

set "bw=N/A"
set "iops=N/A"

for /f "usebackq tokens=*" %%i in ("%tmpFile%") do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    if "!line:READ: bw=!" neq "!line!" (
        for /f "tokens=2,3 delims==," %%a in ("!line!") do (
            endlocal
            set "bw=%%~a"
            set "iops=%%~b"
            setlocal enabledelayedexpansion
        )
    )
    endlocal
)

set "bw=%bw:MiB/s=MiB/s%"
set "iops=%iops:io=, io%"

powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('FIO Test Result:\n\nREAD: bw=%bw%\n%iops%', 'eMMC Test', 'OK', 'Information')"

if exist %tmpFile% del %tmpFile%

echo "Test finished."
pause