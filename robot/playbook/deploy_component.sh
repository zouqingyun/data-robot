#!/usr/bin/env bash

##########################################################################################################################################
#                                                      自动化部署各种hadoop相关的软件包                                                  #
#  sh deploy_component.sh -p 22 -P 123456 -h slaves -f spark-2.0.0-bin-hadoop2.6.tgz -n spark-2.0.0-bin-hadoop2.6 -l spark -i /usr/local #
#                                                                                                                                        #
##########################################################################################################################################

#ssh的端口
ssh_port=22
#ssh的密码
ssh_passwd=""
#远程机器的列表文件
host_file=""
#安装包文件
package_file=""
#安装包解压后的名字
package_file_name=""
#软连接的名称
link_name=""
#远程的安装目录
install_dir="/usr/local"

while getopts "p:P:h:f:n:l:i:" arg
do
        case $arg in
             p)
                 ssh_port=$OPTARG;;
             P)
                 ssh_passwd=$OPTARG;;
             h)
                 host_file=$OPTARG;;
             f)
                 package_file=$OPTARG;;
             n)
                 package_file_name=$OPTARG;;
             l)
                 link_name=$OPTARG;;
             i)
                 install_dir=$OPTARG;;
             ?)
                 echo "Usage:script -p ssh_port -P ssh_passwd -h hosts_file -f package_file -n package_file_name -l link_name -i install_dir "
                 exit 1
                 ;;
        esac
done

# put package file to remote host's install dir
fab --port=$ssh_port -p$ssh_passwd -f hadoop-robot.py set_hosts:$host_file push_file:$package_file,$install_dir

# unzip package file
fab --port=$ssh_port -p$ssh_passwd -f hadoop-robot.py set_hosts:$host_file execute_remote_cmd:"tar -zxvf $package_file",$install_dir

# create soft link for install
fab --port=$ssh_port -p$ssh_passwd -f hadoop-robot.py set_hosts:$host_file execute_remote_cmd:"ln -s $package_file_name $link_name",$install_dir

# remove package file
fab --port=$ssh_port -p$ssh_passwd -f hadoop-robot.py set_hosts:$host_file execute_remote_cmd:"rm -rf $package_file",$install_dir
