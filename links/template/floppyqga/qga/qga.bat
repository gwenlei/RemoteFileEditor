bitsadmin /create myDownloadJob
bitsadmin /addfile myDownloadJob https://192.168.0.82:9090/static/win/qemu-ga.zip c:\win\qemu-ga.zip
bitsadmin /addfile myDownloadJob https://192.168.0.82:9090/static/upload/qemu-ga-x64.msi c:\win\qemu-ga-x64.msi
bitsadmin /SetSecurityFlags myDownloadJob 30
bitsadmin /resume myDownloadJob
ping -n 120 127.0.0.1 >nul
bitsadmin /complete myDownloadJob

"%ProgramFiles(x86)%\7-zip\7z.exe" x C:\win\qemu-ga.zip -o"C:\Program Files"

cd "C:\Program Files\qemu-ga"
