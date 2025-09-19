while ($true) {
    $targetIp = "192.168.222.1"
    Write-Host "Searching for device at $targetIp..."

    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect($targetIp, 22, $null, $null)
    # Wait for a short timeout (e.g., 100 milliseconds)
    $wait = $connect.AsyncWaitHandle.WaitOne(100, $false)

    if ($wait) {
        $tcpClient.EndConnect($connect) | Out-Null
        $tcpClient.Close()
        
        Write-Host "Device found at $targetIp. Checking device integrity..."

        # Step 1: Check if the target block device exists on the remote device
        $checkCommand = "if [ -b /dev/mmcblk2 ]; then echo 'exists'; else echo 'not_found'; fi"
        $checkResult = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${targetIp} $checkCommand

        if ($checkResult -match "exists") {
            Write-Host "/dev/mmcblk2 found. Proceeding with flashing..."
            
            # Step 2: Upload the file
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null .\singleflight-24.10.2-sunxi-cortexa7-friendlyarm_nanopi-neo-air-ext4-sdcard.img.gz root@${targetIp}:/tmp/
            
            # Step 3: Write to the device and reboot
            $flashCommand = "gunzip -c /tmp/singleflight-24.10.2-sunxi-cortexa7-friendlyarm_nanopi-neo-air-ext4-sdcard.img.gz | dd of=/dev/mmcblk2 bs=4M && reboot"
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${targetIp} $flashCommand
            
            # Step 4: Show success message and wait for user confirmation
            Write-Host "Flashing command sent. Waiting for user confirmation..."
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show('Flashing command sent successfully!', 'Success', 'OK', 'Information')
            Write-Host "Press any key to continue to the disconnection phase..."
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null

        } else {
            Write-Host "CRITICAL: Target device /dev/mmcblk2 not found on the remote host. Aborting flash."
            # Display a pop-up message box on Windows using only English characters
            Add-Type -AssemblyName System.Windows.Forms
            $message = 'CRITICAL: Target device /dev/mmcblk2 not found! Flashing operation aborted.'
            $caption = 'Flashing Error'
            [System.Windows.Forms.MessageBox]::Show($message, $caption, 'OK', 'Error')
        }
        
        Write-Host "Commands sent to the device. Waiting for it to disconnect..."
        
        # Wait until the device is no longer reachable
        while ($true) {
            $disconnectClient = New-Object System.Net.Sockets.TcpClient
            $disconnectConnect = $disconnectClient.BeginConnect($targetIp, 22, $null, $null)
            $disconnectWait = $disconnectConnect.AsyncWaitHandle.WaitOne(100, $false)
            if (-not $disconnectWait) {
                $disconnectClient.Close()
                break # Exit loop when connection fails
            }
            $disconnectClient.EndConnect($disconnectConnect) | Out-Null
            $disconnectClient.Close()
            Write-Host "Waiting for device to disconnect..."
            Start-Sleep -Seconds 2
        }
        Write-Host "Device has disconnected. Resuming search..."

    } else {
        $tcpClient.Close()
        Write-Host "Device not found at $targetIp. Retrying..."
    }
}