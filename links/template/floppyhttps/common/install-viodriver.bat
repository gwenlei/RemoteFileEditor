: create the cygwin directory
mkdir %SystemDrive%\viodriver

:: Fetch cygwin
bitsadmin /create myDownloadJob3
bitsadmin /addfile myDownloadJob3 https://192.168.0.82:9090/static/cygwin/7z1512.exe %SystemDrive%\cygwin\7z1512.exe
bitsadmin /addfile myDownloadJob3 https://192.168.0.82:9090/static/upload/virtio-win-0.1.96_amd64.zip %SystemDrive%\viodriver\virtio-win-0.1.96_amd64.zip
bitsadmin /addfile myDownloadJob3 https://192.168.0.82:9090/static/upload/qemu-ga-x64.msi %SystemDrive%\viodriver\qemu-ga-x64.msi
bitsadmin /SetSecurityFlags myDownloadJob3 30
bitsadmin /resume myDownloadJob3
ping -n 180 127.0.0.1 >nul
bitsadmin /complete myDownloadJob3

start /wait %SystemDrive%\cygwin\7z1512.exe /S /v/qn
"%ProgramFiles(x86)%\7-zip\7z.exe" x %SystemDrive%\viodriver\virtio-win-0.1.96_amd64.zip -o%SystemDrive%\viodriver
pnputil -i -a %SystemDrive%\viodriver\vioserial\w7\amd64\vioser.inf
msiexec /i %SystemDrive%\viodriver\qemu-ga-x64.msi /qn

