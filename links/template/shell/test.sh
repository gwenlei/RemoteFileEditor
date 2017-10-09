OUTPUT_DIRECTORY="/home/jsondir/output_centos66v2"
VM_NAME="centos66"
SSH_USERNAME="root"
ISO_URL="/home/html/iso/CentOS-6.6-x86_64-bin-DVD1.iso"
KS="http://192.168.0.82/centos-cdrom-lei2-v2.cfg"
JSON_TEMP="/home/jsondir/template/centos66.json"
JSON="/home/jsondir/centos66.json"
SSH_PASSWORD=`sh /home/jsondir/template/passwd.sh`
VM_NAME=$VM_NAME$SSH_PASSWORD
echo $VM_NAME
KS_TEMP=`echo $KS|sed "s/http:\/\/\([0-9]\+\.*\)\{4,4\}/\/home\/html/g"`
echo $KS_TEMP

sed "s#OUTPUT_DIRECTORY#$OUTPUT_DIRECTORY#g" $JSON_TEMP > $JSON
sed -i "s/VM_NAME/$VM_NAME/g" $JSON
sed -i "s/SSH_USERNAME/$SSH_USERNAME/g" $JSON
sed -i "s/SSH_PASSWORD/$SSH_PASSWORD/g" $JSON
sed -i "s#ISO_URL#$ISO_URL#g" $JSON
sed -i "s#KS#$KS#g" $JSON
sed "s/SSH_PASSWORD/$SSH_PASSWORD/g" /home/jsondir/template/centos-cdrom-lei2-v2.cfg > $KS_TEMP
