:: create the cygwin directory
mkdir %SystemDrive%\cygwin

:: Fetch cygwin
bitsadmin /create myDownloadJob
bitsadmin /addfile myDownloadJob https://192.168.0.82:9090/static/cygwin/7z1512.exe c:\cygwin\7z1512.exe
bitsadmin /addfile myDownloadJob https://192.168.0.82:9090/static/cygwin/cygwinlocal.zip c:\cygwin\cygwinlocal.zip
bitsadmin /addfile myDownloadJob https://192.168.0.82:9090/static/cygwin/setup-x86_64.exe c:\cygwin\setup-x86_64.exe
bitsadmin /SetSecurityFlags myDownloadJob 30
bitsadmin /resume myDownloadJob
ping -n 120 127.0.0.1 >nul
bitsadmin /complete myDownloadJob

start /wait %SystemDrive%\cygwin\7z1512.exe /S /v/qn
"%ProgramFiles(x86)%\7-zip\7z.exe" x %SystemDrive%\cygwin\cygwinlocal.zip -o%SystemDrive%\windows\temp

:: goto a temp directory and install
cd /D %SystemDrive%\windows\temp

:: packages -- comma separated
set PACKAGES=cygrunsrv,makepasswd,nano,openssh,rsync

%SystemDrive%\cygwin\setup-x86_64.exe -a x86_64 -X -d -q -R %SystemDrive%\cygwin -P %PACKAGES% -L

:: Resolve the path with %~dp0 - for easy execution in both test and prod.
set _PATH=%~dp0install-cygwin-sshd.sh

:: Windows path -> linux path, i.d., replace \ with /
set _LINUX_PATH=%_PATH:\=/%

:: Execute the bash part
%SystemDrive%\cygwin\bin\bash -l -c %_LINUX_PATH%

:: Firewall Rules
netsh advfirewall firewall add rule name="sshd" dir=in action=allow program="%SystemDrive%\cygwin\usr\sbin\sshd.exe" enable=yes
netsh advfirewall firewall add rule name="ssh" dir=in action=allow protocol=TCP localport=22

:: Start at last -- server is powered off by packer when ssh is avail. 
net start sshd
