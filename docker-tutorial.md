# 什么是docker

- docker是基于go语言实现的开源容器项目，始于2013年初
- 宗旨：build, ship.  run any app anywhere （即对应用组件的一次封装，到处运行）



# docker核心概念

- docker镜像：用于创建docker容器的只读模板
- docker容器：轻量级沙箱，用于运行和隔离应用。由于镜像本身只读，因此容器从镜像启动时，会在最上层创建一个可写层。容器可以视为docker镜像的一个实例
- docker仓库：类似于代码仓库，是docker集中存放镜像文件的场所。用户可以使用类似git的方式管理docker镜像文件



# docker安装

卸载旧版Docker，docker, docker.io, docker-engine都是旧版Docker名字。

```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

更新apt-get，安装包使得apt可以使用https。

```bash
 sudo apt-get update
 sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

添加Docker官方的GPG密钥

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

设置stable仓库

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

或：

```bash
sudo add-apt-repository \
   "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/ \
  $(lsb_release -cs) \
  stable"
```

更新apt包索引，安装最新版本的Docker Engine和containerd

```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

重启 docker

```bash
service docker restart
```

测试docker

```bash
sudo docker run hello-world
```



# docker服务配置

将当前用户加入到docker用户组

```shell
sudo usermod -aG docker USER_NAME
newgrp docker
```

每次重启docker后，可以通过查看docker版本确定服务是否正常运行

```shell
docker version
```



# docker镜像

## 获取镜像

一般来说，docker hub上的镜像的命名方式为：NAME[:TAG]，如ubuntu:14.04

获取镜像的命令为：

```shell
docker pull ubuntu:14.04
```

如果不手动添加标签，则默认使用:latest作为标签

每一份镜像由若干只读层组成，每一层会有一个256bits的layer id

docker的底层实现按照layer来存储镜像，因此若不同的镜像包含相同的只读层，docker实际上仅保存一份layer

运行`docker pull`时，系统实际上自动补全了默认的仓库地址：`regestry.hub..docker.com`，如果需要使用其他的镜像网站，需要手动补全仓库地址

## 查看镜像

使用images命令列出镜像：

```shell
docker images
```

可以看到本机上各镜像的TAG，创建时间，大小，ID等信息

使用tag命令为镜像设置别名：

```shell
docker tag OLD_NAME:OLD_TAG NEW_NAME:NEW_TAG
```

使用inspect命令可以进一步查看某个镜像的详细信息，如作者、架构、各层哈希等等

```shell
docker inspect NAME:TAG
```

使用history命令可以查看镜像各层的创建命令（即各层内的写命令）：

```
docker history NAME:TAG
```

使用search命令可以搜索远端仓库中的镜像：

```shell
docker search TERM
```

其中term为关键字

## 删除镜像

使用docker rmi删除指定别名：

```shell
docker rmi NAME:TAG
docker rmi IMAGE_ID
```

删除别名不影响镜像文件本身，但如果该别名为镜像文件的最后一个别名，则镜像文件会被一并删除

需要注意的是，如果某一个docker镜像存在正在运行的容器，则无法直接删除镜像。

使用`docker ps -a`可以查看本机上运行的所有容器

使用`docker rm container_id`来删除正在运行的容器

或者使用`docker rm -f IMAGE_ID` 来强制删除容器

## 创建镜像

- 基于已有镜像的容器创建：启动容器后运行

  ``` shell
  docker commit -m "comments" -a "auther" container_id NAME:TAG
  ```

  提交成功返回新创建的镜像ID

- 根据本地模板导入

  ```shell
  docker import file - NAME:TAG
  ```


## 导入导出镜像

- 导出镜像

  ```shell
  docker save -o filename NAME:TAG
  ```

  

- 导入镜像

  ```shell
  docker load --input filename
  ```

## 上传镜像

```shell
docker push NAME:TAG REGISTOR_HOST/NAME:TAG
```



# 操作docker容器

## 新建容器

根据镜像创建一个停止状态的容器

```shell
docker create -it NMAE:TAG
```

要启动新建的容器，使用

```shell
docker start container_id
```

直接新建容器并执行指定指令：

```shell
docker run -it NMAE:TAG COMMAND
```

退出容器界面但不关闭容器：ctrl+D或`exit`

直接新建容器并在后台执行指定命令：

```
docker run -d NMAE:TAG COMMAND
```

此时，如要获取docker的输出信息，可以使用：

```shell
docker logs container_id
```

需要注意的是，运行一个容器并不会直接进入容器，而是会返回一个容器id，还需要使用attach等命令将shell连接该容器

## 终止容器

```shell
docker stop [-t timeout] container_id
```

该命令会向容器发送一个SIGTERM信号，并在等待一段超时时间（默认10s）后再次发送SIGKILL

也可以使用以下命令直接终止容器：

```shell
docker kill container_id
```

或者直接重启容器：

```shell
docker restart container_id
```

## 进入容器

当需要进入正在后台运行中的容器执行指令时，有以下几种方法：

将当前shell连接到容器shell：

```shell
docker attach container_id
```

新建一个容器shell并连接到当前shell：

```
docker exec -it container_id COMMAND
```

## 删除容器

使用`docker rm container_id`来删除正在运行的容器

或者使用`docker rm -f IMAGE_ID` 来强制删除容器

## 容器导入/导出

导出：

```shell
docker export -o FILENAME container_id
```

导入：

```
docker import FILENAME NAME:T
```

## 查看容器

获取容器IP：

```shell
docker inspect -f "{{ .NetworkSettings.IPAddress }}" ${_docker_name}
```

获取容器pid：

```shell
sudo docker inspect -f '{{.State.Pid}}' ${_docker_name}
```





# docker仓库管理

## 基本操作

登录docker账户：

```shell
docker login
```

在仓库内搜索指定镜像：

```shell
docker search KEYWORD
```

在仓库内拉取指定镜像：

```shell
docker pull NAME:TAH
```

## 搭建本地私有仓库

安装官方提供的registry镜像：

```shell
docker pull registry
```

或者直接自动安装并启动：

```shell
docker run -d -p 5000:5000 registry
```

从而获得一个本地的私有仓库服务，监听端口为5000

仓库默认创建在容器的`/tmp/registry`目录下，也可以通过-v指定目录

## 上传镜像到指定仓库

首先标记镜像：

```shell
docker tag NAME:TAG IP:port/registry
```

然后可以上传指定镜像到该仓库：

```shell
docker push NAME:TAG REGISTOR_HOST/NAME:TAG
```

如果要从本地仓库下载镜像，还需要添加启动参数：

```shell
DOCKER_OPTS="--insecure-registry IP:port"
```

并重启docker服务



# docker数据管理

## 数据卷

创建一个类似主机挂载的数据目录，具有以下也行：

- 可以在容器之间共享
- 数据修改立即生效
- 对数据卷的更新不会影响镜像
- 卷独立于容器存在，可以安全地卸载

创建数据卷：

```shell
docker run -v PATH -it NMAE:TAG COMMAND
```

该命令在容器的PATH下创建一个数据卷

也可以挂载一个已有的目录PATH1到容器的PATH2：

```shell
docker run -v PATH1：PATH2 -it NMAE:TAG COMMAND
```

## 数据卷容器

为了让不同的容器共享数据卷，一个好的做法是创建数据卷容器：

- 首先创建一个容器并在该容器下创建一个数据卷；
- 向新创建的其他容器挂载该数据卷：

```shell
docker run -it --volumes-from CONTAINER_NAME NMAE:TAG COMMAND
```

删除容器并不会删除对应的数据卷，需要显式删除：

```shell
docker rm -v PATH NMAE:TAG
```

使用数据卷容器进行数据备份：

```shell
docker run --volumes-from CONTAINER_NAME -v $(pwd):/backup --name worker NMAE:TAG tar cvf /backup/backup.tar /dbdata 
```

- --volumes-from：指定是从哪个数据卷容器挂载数据卷到新建的worker容器
- -v：挂载本地的当前目录到worker容器的/backup目录
- tar cvf : 将数据卷目录/dbdata 压缩并保存到/backup目录

使用数据卷容器进行数据恢复：

首先创建一个带有数据卷的容器：

```shell
docker run -v /dbdata --name dbdata2 ubuntu /bin/bash
```

然后创建一个新的容器来挂载dbdata2的数据卷，并解压备份文件到所挂载的容器卷中：

```
docker run --volumes-from dbdata2 -v $(pwd):/backup worker tar xvf /backup/backup.t
```



# 端口映射与容器互联

## 端口映射访问容器

当容器中运行允许访问的网络应用时，可以使用`-p localPort:containerPort` 指定端口，`-P`由操作系统自动分配一个49000-49900之间的端口。多次使用-p可以指定多个端口对。

指定端口时还可以特别指定具体的地址，如：

```shell
docker run -d -p 127.0.0.1:5000:6000 # 指定地址指定端口
docker run -d -p 127.0.0.1::6000 # 指定地址任意端口
docker run -d -p 127.0.0.1::6000/udp # 指定地址任意端口指定协议
```

## 查看端口映射

```shell
docker port CONTAINER [PRIVATE_PORT[/PROTO]]
```

## 容器互联

容器互联允许多个容器中的应用进行快速交互，容器之间根据彼此的名称进行访问。容器的自定义命名使用`--name CONTAINER_NAME`来完成。

容器的互联使用参数选项`--link NAME:ALIAS`，其中name是要连接的容器的名称，alias是连接本身的别名。

容器的互联通过以下方式实现：

- 更新环境变量
- 更新`/etc/hosts`文件



# dockerfile

## 简介

dockerfile本身由命令语句构成，支持#注释。dockerfile可以分成四个部分：基础镜像信息、维护者信息、镜像操作指令和启动时执行指令。

```dockerfile
# base image to use
# Maintainer
# Command to update the image 
# Command when creating a new container
```

- Base：`FRPOM ubuntu`
- Command to update the image：`RUN COMMAND`，每执行一次镜像添加一层
- Command when creating a new container：`CMD COMMAND`，在创建容器时执行

## dockerfile指令集

- FROM
- MAINTAINER
- RUN：支持直接接命令或json数组（命令和参数需要用双引号隔开），前者使用shell环境，后者使用exec命令执行
- CMD：支持直接接命令或json数组
- LABEL：用于指定生成镜像的元数据标签信息
- EXPOSE：用于声明镜像内服务所监听的端口
- ENV：指定环境变量
- ADD：复制src的内容到dst，src可以是dockerfile目录下的路径，也可以是压缩文件或URL（自动下载解压）
- COPY：复制src的内容到dst，src为dockerfile目录下的路径
- VOLUMN：创建一个数据挂载点
- USER：指定运行容器时的用户名
- WORKDIR：为后续命令指定工作目录

## 根据dockerfile创建镜像

- 通过`dockerfile build FILE_PATH`来创建镜像
- 通过`-t`指定镜像的标签信息
- 由于Dockerfile所在目录（内容路径）最好为空目录，因此当使用非空目录时，使用`-f`选项

 ## dockerignore

`.dockerignore`文件中的匹配模式允许docker忽略内容路径下的匹配目录或文件

## 实践技巧

- 精简镜像用途
- 不使用过于臃肿的基础镜像
- 提供足够清晰的命令注释和维护者信息
- 正确使用版本号
- 减少镜像层数（将多条RUN指令合并成一条）
- 即使删除临时文件和缓存文件
- 提高生成速度
- 即使删除临时文件和缓存文件
- 提高生成速度：减少内容目录下的文件，合理使用缓存，使用dockerignore跳过中间文件和临时文件
- 减少外部源的干扰：需要使用外部数据时尽量指定持久的地址

# 常见docker操作系统

- busybox
- Alpine
- Debian/Ubuntu
-  CentOS/Fedora



# 添加SSH服务

## 基于commit命令创建

运行容器后安装openssh-server：

```shell
apt-get install openssh-server -y
```

创建所需目录：

```shell
mkdir -p /var/run/sshd
```

创建自动启动ssh服务的脚本：

```shell
#!/bin/bash
/usr/sbin/sshd -D
```

并添加执行权限：

```shell
chmod +x run.sh
```

将退出后的容器保存为新的镜像：

```shell
docker commit CONTAINER_NAME IMAGE_NAME:TAG
```

从外部使用ssh访问容器：

```shell
docerk run -p 10022:22 IMAGE_NAME:TAG /run.sh
```

## 使用dockerfile创建

创建工作目录，在其中创建dockerfile和run.sh

其中dockerfile的内容如下：

```dockerfile
RUN apt-get install openssh-server -y
RUN mkdir -p /var/run/sshd
RUN mkdir -p /root/.ssh
ADD run.sh /run.sh
ADD aithorized_keys /root/.ssh/aithorized_keys
EXPOSE  22
CMD ["/run"]
```



# Web服务与应用

## Apache

### 官方镜像

官方提供了名为httpd的Apache镜像

创建项目目录public-html，在其中加入html文件

在dockerfile中将public-html文件内容拷贝到`/usr/local/apache2/htdocs/`：

```dockerfile
COPY ./public-html /usr/local/apache2/htdocs
```

### 自定义镜像

创建dockerfile如下：

```dockerfile
FROM sshd:dockerfile
MAINTAINER email

RUN apt-get -yq install apache2 && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/lock/apache2 && mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html
COPY /sample /app

EXPOSE 80
WORKDIR /app
CMD ["/run.sh"]
```

然后将目标html文件放到sample目录下即可

## Nginx

方法与Apache类似，区别在于html文件需要挂载到`/usr.share/nginx/html`文件夹下

## 其他Web server

- TomCat
- Jetty
- LAMP (linux-Apache-MySQL-PHP) / LNMP (linux-Nginx-MySQL-PHP)
- CMS (content management system): Wordpress/Ghost
- Gitlab

# 数据库应用

- mysql
- MongoDB
- Redis
- Memcached
- Cassandra



# 分布式处理与大数据平台

- RabbitMQ
- Celery
- Hadoop
- Spark
- Storm
- ElasticSearch



# Docker核心实现技术

## 基本架构

- 服务端：docker daemon一般在宿主主机后台运行，接受并处理客户请求。服务端默认监听本地的`unix://var/run/docker.sock`套接字
- 客户端：为用户提供一系列可执行命令，从而与服务端交互

## 命名空间

- 进程命名空间：不同的进程命名空间中看到的进程号不同
- 网络命名空间：所有的dorcker虚拟网卡通过网桥docker0相连
- IPC命名空间：只有同一个IPC命名空间内的进程之间可以互相交互
- 挂载命名空间：不同挂载命名空间下看到的文件目录结构不同
- 用户命名空间：每个docker有独立的用户和组id，有独立的root账号

## 控制组(CGroups)

主要用于对共享资源进行隔离、限制、审计等。只有能控制分配到容器的资源，才能避免多个容器同时运行时对宿主机系统的资源竞争

- 资源限制
- 优先级
- 资源审计
- 隔离
- 控制

用户可以在`/sys/fs/cgroup/memory/docker`目录下看到相应的控制组设置

## 网络虚拟化

- docker启动时会创建一个网桥docker0，类似于一个软件交换机为名下的所有容器提供网络连接
- 创建一堆虚拟接口，分别放到本地主机和新容器的命名空间中
- 本地主机一端的虚拟接口连接到默认的docker0网桥或指定网桥上
- 容器一段的虚拟接口命名为eth0，只在容器的命名空间中可用
- 从网桥可用地址段中获取一个空闲地址分配给容器的eth0，并配置默认路由网关为docker0网卡内部接口docker0的IP地址

手动配置网络：

- `docker run`指定`--net=none`

- 创建网络命名空间：

  ```shell
  pid = 2288
  sudo mkdir -p /var/run/netns
  sudo ln -s /proc/$pid/ns/net /var/run/netns
  ```

- 创建一对"veth pair" A、B，绑定A接口到网桥docker0，并启用它：

  ```shell
  sudo ip ;oml add A type veth peer name B
  sudo brctl addif docker0 A
  sudo ip link set A up
  ```

  

- 将B放到容器的网络明明空间，命名为eth0，并配置一个可用IP

  ```shell
  sudo ip link set B netns $pid
  sudo ip netns exec $pid ip link set dev B name eth0
  sudo ip netns exec $pid ip link set eth0 up
  sudo ip netns exec $pid ip addr add 172.17.42.99/16 dev eth0
  sudo ip netns exec $pid ip route add default via 172.17.42.1
  ```

  这里假设网桥的默认网关为172.17.42.1，网段为172.17.42.1/16




# 配置私有仓库

## 安装registry

安装官方提供的registry镜像：

```shell
docker pull registry
```

或者直接自动安装并启动：

```shell
docker run -d -p 5000:5000 --restart=always  registry
```

从而获得一个本地的私有仓库服务，监听端口为5000

仓库默认创建在容器的`/tmp/registry`目录下，也可以通过-v指定目录

registry默认的配置文件为/etc/docker/registry/config.yml，可以通过`-v`指定使用本地主机的配置文件

也可以直接利用源码安装到本地：

- 需要Golang环境支持
- 需要在本地创建配置文件目录`/etc/docker/registry`
- 需要常见存储目录`/var/lib/registry`

## 配置TLS证书

私有仓库需要添加TLS认证，否则会报错。临时使用时也可以通过`DOCKER_OPTS=--insecure-registry`来避免

使用openssl可以快速生成证书：

```shell
mkdir -p certs
openssl req -newkey rsa:4096 -nodes -sha256 -keyout certs/myrepo.key -x509 -days 365 -out certs/myrepo.crt
```

创建过程中需要注意CN一栏要填入跟方文地址相同的域名，如`myrepo.com`

生成的证书文件需要发送给用户：`/etc/docker/certs.d/myrepo.com:5000/ca.crt`

随后需要启用证书：在docker run命令中加入参数`-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/myrepo.crt`和 `-e REGISTRY_HTTP_TLS_KEY=/certs/myrepo.key`

## 配置Nginx代理

为了让其他主机也可以访问本地仓库，需要配置nginx代理：

```shell
sudo apt-get -y install nginx
```

在`/etc/nginx/site-available/`目录下创建`/etc/nginx/site-available/docker-registry.conf`

然后将配置文件软链接到Nginx工作目录下：

```shell
sudo ln -s /etc/nginx/site-available/docker-registry.conf /etc/nginx/site-enabled/docker-registry.conf
```

也可以在Nginx中开启用户认证：

- 在配置文件中指定提示语句、用户名密码文件

- 用户名密码文件一般需要htpasswd工具生成，密码非明文：

  ```shell
  sudo htpasswd /etc/nginx/docker-registry-htpasswd -c username
  ```

- 重启nginx：`sudo service nginx restart`



# 高级网络配置

## DNS配置

容器中的DNS配置信息都是通过三个系统配置文件来维护的：

- `/etc/resolv.conf`：默认与宿主机的同名文件保持一致
- `/etc/hostname`
- `/erc/hosts`：只记录容器本身的一些地址和名称

对配置文件的修改不会被容器提交，可以选择在创建容器时使用参数指定：

- --hostname=HOSTNAME指定主机名
- --link=CONTAINER_NAME会将其他容器添加到hosts文件
- --dns-search=DOMAIN会添加DNS搜索域

## 容器访问控制

1. 容器要想访问外网，需要宿主机进行转发。

检查宿主机是否允许转发：

```shell
sudo sysctl net.ipv4.ip_forward
```

开启转发：

```shell
sudo sysctl -w net.ipv4.ip_forward=1
```

或者在启动容器时进行参数设定：`--ip-forward=true`

2. 然后检查防火墙规则是否需要配置：

默认情况下容器防火墙允许转发，即`--icc=true`

也可以再禁用默认转发，即`--icc=false`后再通过`--link=CONTAINER_NAME`来连接指定端口，此时默认转发规则为drop，对于每条连接会有两条异向的转发规则

3. 容器访问外网需要进行源地址映射：

可以通过`sudo iptables -t nat -nvl POSTROUTING`查看默认配置，nat表中的POSTROUTING链会把所有从容器发出的流量伪装成宿主机网卡流量

4. 外网访问容器需要进行目的地址映射：

启动容器时通过`-p`或`-P`进行参数设置，会自动进行nat配置，nat表中的PREROUTING链会将到达的数据包转发给DOCKER链，而DOCKER链会将所有非本机流量进行DNAT处理：将目的地址改写为容器指定IP的指定端口

## 网桥配置

Docker服务启动后会默认创建一个网桥docker0为所有容器提供网络连接，网桥所持有的网段可以通过参数设置：`--bip=CIDR`

用户可以通过brctl show来查看所有linux网桥

用户也可以为docker服务提供自定义网桥，通过参数配置`-b BRIDGE`或`--bridge=BRIDGE`来指定自定义网桥

例如：

```shell
# stop docker service and delete docker0
sudo service docker stop
sudo ip link set dev docker0 down
sudo brctl delbr docker 0
# create a new bridge
sudo brctl addbr bridge1
sudo ip addr add 192.168.5.1/24 dev bridge1
sudo ip link set dev bridge1 up
# configure docker service
echo `DOCKER_OPTS="-b=bridge0"` >> /etc/default/docker
```

## 创建点对点直连

如果需要容器不经过网桥直接连接，可以创建一对peer接口，放到两个容器中：

首先创建网络命名空间的跟踪文件（这里假设容器A的进程号位2829，容器B的操作与A对称）：

```shell
sudo mkdir -p /var/run/netns
sudo ln -s /proc/2829/ns/net /var/run/netns/2829
```

然后创建接口：

```shell
sudo ip link add A type veth peer name B
```

然后为容器添加IP和路由信息：

```shell
sudo ip link set A netns 2829
sudo ip netns exec 2989 ip addr add 10.1.1.1/32 dev A
sudo ip netns exec 2989 ip link set A up
sudo ip neetns exec 2829 ip route add 10.1.1.2/32 dev A
```



# libnetwork插件化网络功能

## 容器网络模型（CNM）

1.7版本以后docker尝试把网络和存储以插件化形式剥离出来，允许用户通过指令来选择不同的后端实现

在libnetwork中，系统结构可以分解为日被容器->接入点->网络，其生命周期为：

- 注册驱动到network controller
- network controller创建新的网络并绑定到现有驱动
- 网络创建一个接入点
- 将容器挂载到接入点

CNM支持的驱动类型共有四种：

- Null：不提供网络服务，容器启动后无网络连接
- Bridge：传统的基于linux网桥和iptables实现的单机网络
- overlay：通过vxlan隧道实现的跨主机容器网络
- remote：扩展类型，可以外接第三方网络实现方案

## 网络相关命令

在libnetwork的支持下，docker网络相关命令都作为network的子命令出现

- 列出所有可用网络：`docker network ls`
- 创建一个网络：`docker network create [OPTIONS] NETWORK`
- 删除网络：`docker network rm NETWOR`
- 接入容器：`docker network connect [OPTIONS] NETWORK CONTAINER`

- 卸载容器：`docker network disconnect [OPTIONS] NETWORK CONTAINER` 

- 查看网络信息：`docker network inspect [OPTIONS] NETWORK`

## 构建跨主机容器网络

- 跨主机网络连接需要网络管理平面来维护网络信息（常见硬件：交换机、路由器），可以通过运行一个简单的consul容器并映射到8500端口
- 运行容器并配置访问consul数据库节点：`DOCKER_OPTS=$"DOCKER_OPTS --cluster-store=consul://<CONSUL_NODE>:8500 --cluster-adverrise=eth0:2376"`然后重启docker
- 创建网络：`docker network create -d overlay multi`

- 启动容器连接网络：`docker run -it --name=c1 --net=multi CONTAINER`
