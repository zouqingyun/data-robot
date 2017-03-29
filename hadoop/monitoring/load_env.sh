#!/bin/sh

##################################################################
#              crontab任务默认不会加载用户的环境变量             #
#                     该脚本会加载用户环境变量                   #
##################################################################

current_user=$(whoami)

# 加载bash_profile
if [ "x"$current_user = "xroot" ]; then
    echo "loading /$current_user/.bash_profile"
    . /$current_user/.bash_profile
else
    echo "loading /home/$current_user/.bash_profile"
    . /home/$current_user/.bash_profile
fi

# 不用加载.bashrc，因为.bash_profile默认会加载.bashrc

# 加载bashrc
# echo "loading /home/$current_user/.bashrc"
# . /home/$current_user/.bashrc