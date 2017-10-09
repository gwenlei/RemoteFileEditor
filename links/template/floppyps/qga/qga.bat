set URL=https://192.168.0.82:9090/static/win/qemu-ga.zip
bitsadmin /transfer qemu-ga.zip /download /priority normal %URL% C:\win\qemu-ga.zip

set URL=https://192.168.0.82:9090/static/upload/qemu-ga-x64.msi
bitsadmin /transfer qemu-ga-x64.msi /download /priority normal %URL% C:\win\qemu-ga-x64.msi

start /wait %SystemDrive%\win\qemu-ga-x64.msi /S /v/qn

"%ProgramFiles(x86)%\7-zip\7z.exe" x C:\win\qemu-ga.zip -o"C:\Program Files"

cd "C:\Program Files\qemu-ga"
qemu-ga -p \\.\Global\org.qemu.guest_agent.0
