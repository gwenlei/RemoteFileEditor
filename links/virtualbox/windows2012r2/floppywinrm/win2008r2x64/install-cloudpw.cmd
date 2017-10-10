 mkdir %SystemDrive%\win

 :: Fetch netframework4.0
bitsadmin /create myDownloadJob3
bitsadmin /addfile myDownloadJob3 https://192.168.0.82:9090/static/win/NDP46-KB3045557-x86-x64-AllOS-ENU.exe %SystemDrive%\win\NDP46-KB3045557-x86-x64-AllOS-ENU.exe
bitsadmin /addfile myDownloadJob3 https://192.168.0.82:9090/static/win/uppowershell.ps1 %SystemDrive%\win\uppowershell.ps1
bitsadmin /addfile myDownloadJob3 https://192.168.0.82:9090/static/win/winrm.ps1 %SystemDrive%\win\winrm.ps1
bitsadmin /addfile myDownloadJob3 https://192.168.0.82:9090/static/upload/qemu-ga-x64.msi %SystemDrive%\win\qemu-ga-x64.msi
bitsadmin /addfile myDownloadJob3 https://192.168.0.82:9090/static/upload/CloudInstanceManager.msi %SystemDrive%\win\CloudInstanceManager.msi
bitsadmin /SetSecurityFlags myDownloadJob3 30
bitsadmin /resume myDownloadJob3
ping -n 120 127.0.0.1 >nul
bitsadmin /complete myDownloadJob3


%SystemDrive%\win\NDP46-KB3045557-x86-x64-AllOS-ENU.exe /q
msiexec.exe /i "%SystemDrive%\win\CloudInstanceManager.msi" /passive
::msiexec.exe /i "%SystemDrive%\win\qemu-ga-x64.msi" /passive

 cd %SystemDrive%\win
 powershell Set-ExecutionPolicy Unrestricted
:: powershell .\uppowershell.ps1
:: powershell .\winrm.ps1

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /d 0 /f

echo ==^> enable remote desktop
netsh advfirewall firewall add rule name="Open Port 3389" dir=in action=allow protocol=TCP localport=3389
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

powershell .\testinstallfeatures.ps1

