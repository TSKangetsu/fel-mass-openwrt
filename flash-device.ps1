while ($true) {
    $targetIp = "192.168.223.1"
    Write-Host "Searching for device at $targetIp..."

    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect($targetIp, 22, $null, $null)
    # Wait for a short timeout (e.g., 100 milliseconds)
    $wait = $connect.AsyncWaitHandle.WaitOne(100, $false)

    if ($wait) {
        $tcpClient.EndConnect($connect) | Out-Null
        $tcpClient.Close()
        
        Write-Host "Device found at $targetIp. Proceeding with flashing..."
        
        # Step 1: Upload the file
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null .\openwrt-sunxi-cortexa7-friendlyarm_nanopi-neo-air-squashfs-factory.bin root@${targetIp}:/tmp/
        
        # Step 2: Write to the device and reboot
        $flashCommand = "mtd write /tmp/openwrt-sunxi-cortexa7-friendlyarm_nanopi-neo-air-squashfs-factory.bin /dev/mtd0 && reboot"
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${targetIp} $flashCommand
        
        # Step 3: Show success message and wait for user confirmation
        Write-Host "Flashing command sent. Waiting for user confirmation..."
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show('Flashing command sent successfully!', 'Success', 'OK', 'Information')
        
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