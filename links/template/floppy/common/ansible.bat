:: create the cygwin directory
mkdir %SystemDrive%\win

:: Fetch netframework4.0
set URL=http://192.168.0.82:9090/static/win/NDP46-KB3045557-x86-x64-AllOS-ENU.exe
bitsadmin /transfer netframework4.0 /download /priority normal %URL% %SystemDrive%\win\NDP46-KB3045557-x86-x64-AllOS-ENU.exe

set URL=http://192.168.0.82:9090/static/win/uppowershell.ps1
bitsadmin /transfer upps /download /priority normal %URL% %SystemDrive%\win\uppowershell.ps1

set URL=http://192.168.0.82:9090/static/win/winrm.ps1
bitsadmin /transfer winrm /download /priority normal %URL% %SystemDrive%\win\winrm.ps1

start /wait %SystemDrive%\win\NDP46-KB3045557-x86-x64-AllOS-ENU.exe /S /v/qn

cd %SystemDrive%\win
powershell Set-ExecutionPolicy Unrestricted
powershell .\uppowershell.ps1
powershell .\winrm.ps1
