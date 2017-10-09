yum install -y -q tomcat6  tomcat6-webapps tomcat6-admin-webapps
sed -i 's#</tomcat-users>#<role rolename="manager" /><user username="clouder" password="engine" roles="manager" /></tomcat-users>#' /etc/tomcat6/tomcat-users.xml
service tomcat6 start
chkconfig tomcat6 on
