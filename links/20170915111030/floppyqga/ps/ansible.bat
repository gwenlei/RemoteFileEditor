:: create the cygwin directory
mkdir %SystemDrive%\win

:: Fetch netframework4.0
tsadmin /create myDownloadJob
bitsadmin /addfile myDownloadJob https://192.168.0.82:9090/static/win/NDP46-KB3045557-x86-x64-AllOS-ENU.exe c:\win\NDP46-KB3045557-x86-x64-AllOS-ENU.exe
bitsadmin /addfile myDownloadJob https://192.168.0.82:9090/static/win/uppowershell.ps1 c:\win\uppowershell.ps1
bitsadmin /addfile myDownloadJob https://192.168.0.82:9090/static/win/winrm.ps1 c:\win\winrm.ps1
bitsadmin /SetSecurityFlags myDownloadJob 30
bitsadmin /resume myDownloadJob
ping -n 120 127.0.0.1 >nul
bitsadmin /complete myDownloadJob

cd %SystemDrive%\win
powershell Set-ExecutionPolicy Unrestricted
:: powershell .\uppowershell.ps1
:: powershell .\winrm.ps1
