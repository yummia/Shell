#! /bin/bash
echo "--- 删除原有 mysql 及其依赖 ---"
yum remove -y `rpm -qa|grep mariadb`
echo "--- 下载 mysql-5.7.35 ---"
sleep 1
cd /
mkdir -p /datafs/{software,module}
cd /datafs/software/
yum info wget
yum install -y wget
#wget https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.35-linux-glibc2.12-x86_64.tar.gz
mv ~/mysql-5.7.35* ./
tar -zxvf mysql-5.7.35* -C /datafs/module/
cd /datafs/module/ 
mv mysql-5.7.35* mysql-5.7.35
echo "--- 配置 mysql 用户 ---"
sleep 1
groupadd mysql
useradd -r -g mysql mysql
chown -R mysql. mysql-5.7.35
cd mysql-5.7.35
echo "--- 配置环境变量 ---"
sleep 1
#echo "export MYSQL_HOME=/datafs/module/mysql-5.7.35" >> /etc/profile.d/my_env.sh
#echo "export PATH=$PATH:$MYSQL_HOME/bin" >> /etc/profile.d/my_env.sh
cat <<EOF >> /etc/profile.d/my_env.sh
export MYSQL_HOME=/datafs/module/mysql-5.7.35
export PATH=$PATH:$MYSQL_HOME/bin
EOF
source /etc/profile.d/my_env.sh
echo "--- 配置数据存储目录 ---"
sleep 1
mkdir {data,logs};chown -R mysql. ./*
cd data/
echo "--- 配置 my.cnf 文件 ---"
sleep 1
cat << EOF >> /etc/my.cnf
[client]
port = 3306
default-character-set = utf8mb4

[mysqld]
port = 3306
basedir = /datafs/module/mysql-5.7.35
datadir = /datafs/module/mysql-5.7.35/data
pid-file = /datafs/module/mysql-5.7.35/data/mysql.pid
socket = /tmp/mysql.sock

sql_mode=ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
#ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION

max_connections=200

default_storage_engine=INNODB
lower_case_table_names=1

user = mysql

# skip-grant-tables

server-id = 1
character-set-server = utf8mb4
log_error = /datafs/module/mysql-5.7.35/logs/mysql-error.log
slow_query_log = 1
long_query_time = 1
slow_query_log_file = /datafs/module/mysql-5.7.35/logs/mysql-slow.log
performance_schema = 0
explicit_defaults_for_timestamp

# 保证日志跟系统时间保持一致
log_timestamps=SYSTEM

[mysqld_safe]
general_log = 1
log-output = 'FILE,TABLE'
gerneral_log_file = /datafs/module/mysql-5.7.35/logs/mysqld.log
slow_query_log = 1
slow_query_log_file = /datafs/module/mysql-5.7.35/logs/mysql-slow.log
long_query_time = 5
log-error = /datafs/module/mysql-5.7.35/logs/mysql-error.log

[mysqldump]
quick
default-character-set = utf8mb4
max_allowed_packet = 256M
EOF
echo "--- 初始化数据库 ---"
sleep 1
cd ..
bin/mysqld --initialize --user=mysql --basedir=/datafs/module/mysql-5.7.35 --datadir=/datafs/module/mysql-5.7.35/data
echo "--- 启动 MySQL 数据库 ---"
sleep 1
/datafs/module/mysql-5.7.35/support-files/mysql.server start
cp -a /datafs/module/mysql-5.7.35/support-files/mysql.server /etc/rc.d/init.d/mysqld
chkconfig --add mysqld
chkconfig --list mysqld
echo "--- 保存初始化 MySQL 初始化密码 ---"
sleep 1
temppasswd=`grep "A temporary password" /datafs/module/mysql-5.7.35/logs/mysql-error.log | awk '{print $NF}'`
echo "--- 登录 MySQL ---"
sleep 1
mysql -uroot -p$temppasswd --connect-expired-password << EOF
alter user 'root'@'localhost' identified by '123456';
flush privileges;
grant all privileges on *.* to 'demo'@'%' indentified by '123456' with grant option;
flush privileges;
select `user`,`host` from mysql.user;
create database test;
show databases;
use test;
show tables;
exit
EOF
echo "--- 打开防火墙，放行 MySQL 3306 端口 ---"
sleep 1
systemctl restart firewalld
systemctl status firewalld
firewall-cmd --zone=public --add-port=3306/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-all
echo "--- 查看主机 IP ---" 
sleep 1
hostname -I




