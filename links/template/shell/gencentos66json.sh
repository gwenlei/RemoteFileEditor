OUTPUT_DIRECTORY="/home/jsondir/output_centos66v2"
DISK_SIZE=6000
VM_NAME="centos66"
SSH_USERNAME="root"
ISO_URL="/home/html/iso/CentOS-6.6-x86_64-bin-DVD1.iso"
KS="http://192.168.0.82/centos6-ks-lei.cfg"
#KS="http://192.168.0.82/centos-cdrom-lei2-v2.cfg"
#KS="http://192.168.0.82/CentOS67_64bit_password_sshkey.ks"
JSON_TEMP="/home/jsondir/template/centos66.json"
JSON="/home/jsondir/centos66.json"
HEADLESS="false"
ISO_CHECKSUM=`md5sum $ISO_URL | awk '{print $1}'`
SSH_PASSWORD="engine"
#SSH_PASSWORD=`sh /home/jsondir/template/passwd.sh`
VM_NAME=$VM_NAME
#VM_NAME=$VM_NAME$SSH_PASSWORD
echo $VM_NAME
KS_TEMP=`echo $KS|sed "s/http:\/\/\([0-9]\+\.*\)\{4,4\}/\/home\/jsondir\/template/g"`
echo $KS_TEMP
KS_SER=`echo $KS|sed "s/http:\/\/\([0-9]\+\.*\)\{4,4\}/\/home\/html/g"`
echo $KS_SER

sed "s#OUTPUT_DIRECTORY#$OUTPUT_DIRECTORY#g" $JSON_TEMP > $JSON
sed -i "s/DISK_SIZE/$DISK_SIZE/g" $JSON
sed -i "s/VM_NAME/$VM_NAME/g" $JSON
sed -i "s/SSH_USERNAME/$SSH_USERNAME/g" $JSON
sed -i "s/SSH_PASSWORD/$SSH_PASSWORD/g" $JSON
sed -i "s#ISO_URL#$ISO_URL#g" $JSON
sed -i "s/ISO_CHECKSUM/$ISO_CHECKSUM/g" $JSON
sed -i "s/HEADLESS/$HEADLESS/g" $JSON
sed -i "s#KS#$KS#g" $JSON
sed "s/SSH_PASSWORD/$SSH_PASSWORD/g" $KS_TEMP > $KS_SER
sed -i "s/SSH_USERNAME/$SSH_USERNAME/g" $KS_SER

if [ -d "$OUTPUT_DIRECTORY" ]; then
rm -r "$OUTPUT_DIRECTORY"
fi

/home/packerdir/packer build $JSON
qemu-img convert -f qcow2 $OUTPUT_DIRECTORY/$VM_NAME -O qcow2 -o compat=0.10 /home/html/template/$VM_NAME.qcow2

