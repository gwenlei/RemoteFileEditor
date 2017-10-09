yum install -y -q mysql-server mysql mysql-deve
service mysqld start
chkconfig mysqld on
mysql -uroot -e "grant all privileges on *.* to 'root'@'%' identified by 'engine' with grant option;"
mysql -uroot -e "create database testdb;"
mysql -uroot -e "use testdb;create table tablea(id int(4),name char(20));insert into tablea values(1,'jack');"
