data-robot是hadoop相关的自动化脚本和工具
=======

### 依赖的环境
**以下环境只在执行部署脚本的主机上需要,远程主机不需要**
1. python环境
2. pip，首先下载[get-pip.py](https://bootstrap.pypa.io/get-pip.py),下载后执行python get-pip.py
3. fabric，执行pip install fabric

### 目前提供的功能
1. 同步本地到远程host(已测试)
2. 回滚远程机器的特定文件
3. 追加内容到远程主机的特定文件（目前只支持xml格式)

### 例子
1）同步test.txt文件到远程主机的/tmp目录(如果远程主机上已经存在该文件,默认会备份)
```
fab -f hadoop_robot.py set_hosts:vm_hosts.txt push_file:test.txt,/tmp

hadoop_robot.py 当前的fab文件
set_hosts 设置目标远程主机
   * vm_hosts.txt 包含了远程主机列表的文件,类似hadoop的slaves的配置文件,每行表示一个远程主机hostname或者ip
push_file 执行文件推送命令
   * text.txt 要推送的本地文件
   * /tmp 远程的目录
```

### 注意事项
目前相关的功能还在进一步测试中，暂时不推荐正式环境使用。可以自己测试一下，看效果，欢迎提bug。
.