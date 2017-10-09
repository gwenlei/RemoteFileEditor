set URL=http://192.168.0.82:9090/static/win/qemu-ga.zip
bitsadmin /transfer qemu-ga.zip /download /priority normal %URL% C:\win\qemu-ga.zip

"%ProgramFiles(x86)%\7-zip\7z.exe" x C:\win\qemu-ga.zip -o"C:\Program Files"

qemu-ga -p \\.\Global\com.redhat.spice.0
