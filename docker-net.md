# netns详解

## 概述

Network Namespace （以下简称netns）是Linux内核提供的一项实现网络隔离的功能，它能隔离多个不同的网络空间，并且各自拥有独立的网络协议栈，这其中便包括了网络接口（网卡），路由表，iptables规则等。例如大名鼎鼎的docker便是基于netns实现的网络隔离。

## 常用命令

- ip netns list：列出所有命名空间
- ip netns add NAME：添加新的命名空间
- ip netns set NAME NETNSID：给命名空间分配ID
- ip [-all] netns delete [NAME]：删除命名空间
- ip netns identify [PID]：查看进程的网络命名空间内
- ip netns pids NAME：查找使用此网络命名空间并将其作为主要网络命名空间的进程。
- ip [-all] netns exec [NAME] cmd ...：在指定的网络命名空间中执行命令
- ip netns monitor：监控对网络命名空间的操作
- ip netns list-id：列出所有已分配的ID



# IPtables详解

## 概述

iptables是linux系统默认集成的防火墙。

iptables的基本组成：表、链、规则

> 表（tables）提供特定的功能，iptables内置了4个表，即filter表、nat表、mangle表和raw表，分别用于实现包过滤，网络地址转换、包重构(修改)和数据跟踪处理

> 链（chains）是数据包传播的路径，每一条链其实就是众多规则中的一个检查清单，每一条链中可以有一 条或数条规则。当一个数据包到达一个链时，iptables就会从链中第一条规则开始检查，看该数据包是否满足规则所定义的条件。如果满足，系统就会根据 该条规则所定义的方法处理该数据包；否则iptables将继续检查下一条规则，如果该数据包不符合链中任一条规则，iptables就会根据该链预先定 义的默认策略来处理数据包。

> 规则链
>  ①INPUT——进来的数据包到`应用层`适用此规则链中的策略
>  ②OUTPUT——`应用层`外出的数据包应用此规则链中的策略
>  ③FORWARD—— 数据包从一个网络转发到另外一个网络应用此规则链中的策略
>  ④PREROUTING——对数据包作路由选择前应用此链中的规则
>  （注意：所有的数据包进来的时侯都先由这个链处理）
>  ⑤POSTROUTING——对数据包作路由选择后应用此链中的规则
>  （注意：所有的数据包出来的时侯都先由这个链处理）



## 查看当前规则

```shell
iptables --list
```

## 默认规则

iptables可以分别对 流入 流出 转发 三种数据包进行端口级的默认规则配置

```shell
vim /etc/sysconfig/iptables
```

## 常见规则配置

一般常用的参数如下:

```shell
# -A 添加一条防火墙规则，后面一般接上 INPUT OUTPUT FORWARD
# -D 删除一条防火墙规则，后面一般接上 INPUT OUTPUT FORWARD
# -t table   是指'操作的表',filter、nat、mangle或raw,'默认使用filter'
# -i 指定流量进入的网卡，后面接上网卡名称，如：lo eth0 eth1
# -o 指定流量出口的网卡，后面接上网卡名称，如：lo eth0 eth1
# -j 指定规则的行为，后面一般接上 DROP ACCEPT DENY
# -p 指定应用的协议，如 tcp udp icmp http
# --dport 进入数据包的目标端口，后面接上端口名称
# --sport 出口数据包的源端口，后面接上端口名称
# --state 连接的状态，后面一般接上 NEW ESTABLISHED RELATED
# -s 源ip地址，后面接上发起数据的ip地址
# -d 目标ip地址，后面接上数据包的目标ip地址
```

常用规则示例：

```shell
# 允许来自本机(127.0.0.1)的流入流量 流出流量
-A INPUT -i lo -j ACCEPT
-A OUTPUT -o lo -j ACCEPT

# 允许icmp协议的(例如ping，traceroute)数据包，类似ping，不但需要数据流出，也需要数据流入
-A INPUT -p icmp -j ACCEPT
-A OUTPUT -p icmp -j ACCEPT
# 另一种写法
-A INPUT -p icmp --state NEW -j ACCEPT

# 允许80端口的所有流量
-A INPUT -p tcp --dport 80 -j ACCEPT
-A OUTPUT -p tcp --sport 80 -j ACCEPT

# 拒绝3306端口的所有流量
-A INPUT -p tcp --dport 3306 -j DROP
-A OUTPUT -p tcp --sport 3306 -j DROP

# 只允许来自192.168.1.150的ssh(22端口)连接
-A INPUT -p tcp --dport 22 -s 192.168.1.150 -j ACCEPT
-A OUTPUT -p tcp --sport 22 -d 192.168.1.150 -j ACCEPT
```



## **IPtables中SNAT和MASQUERADE的区别**

IPtables中可以灵活的做各种网络地址转换（NAT），网络地址转换主要有两种：SNAT和DNAT。

SNAT是source network address  translation的缩写，即源地址目标转换。比如，多个PC机使用ADSL路由器共享上网，每个PC机都配置了内网IP，PC机访问外部网络的时候，路由器将数据包的报头中的源地址替换成路由器的ip，当外部网络的服务器比如网站web服务器接到访问请求的时候，他的日志记录下来的是路由器的ip地址，而不是pc机的内网ip，这是因为，这个服务器收到的数据包的报头里边的“源地址”，已经被替换了，所以叫做SNAT，基于源地址的地址转换。

DNAT是destination network address translation的缩写，即目标网络地址转换，典型的应用是，有个web服务器放在内网配置内网ip，前端有个防火墙配置公网ip，互联网上的访问者使用公网ip来访问这个网站，当访问的时候，客户端发出一个数据包，这个数据包的报头里边，目标地址写的是防火墙的公网ip，防火墙会把这个数据包的报头改写一次，将目标地址改写成web服务器的内网ip，然后再把这个数据包发送到内网的web服务器上，这样，数据包就穿透了防火墙，并从公网ip变成了一个对内网地址的访问了，即DNAT，基于目标的网络地址转换。

MASQUERADE，地址伪装，在iptables中有着和SNAT相近的效果，但也有一些区别，但使用SNAT的时候，出口ip的地址范围可以是一个，也可以是多个，例如：

如下命令表示把所有10.8.0.0网段的数据包SNAT成192.168.5.3的ip然后发出去，

iptables -t nat -A POSTROUTING -s 10.8.0.0/255.255.255.0 -o eth0 -j SNAT --to-source 192.168.5.3

如下命令表示把所有10.8.0.0网段的数据包SNAT成192.168.5.3/192.168.5.4/192.168.5.5等几个ip然后发出去

iptables -t nat -A POSTROUTING -s 10.8.0.0/255.255.255.0 -o eth0 -j SNAT --to-source 192.168.5.3-192.168.5.5

这就是SNAT的使用方法，即可以NAT成一个地址，也可以NAT成多个地址，但是，对于SNAT，不管是几个地址，必须明确的指定要SNAT的ip，假如当前系统用的是ADSL动态拨号方式，那么每次拨号，出口ip192.168.5.3都会改变，而且改变的幅度很大，不一定是192.168.5.3到192.168.5.5范围内的地址，这个时候如果按照现在的方式来配置iptables就会出现问题了，因为每次拨号后，服务器地址都会变化，而iptables规则内的ip是不会随着自动变化的，每次地址变化后都必须手工修改一次iptables，把规则里边的固定ip改成新的ip，这样是非常不好用的。

MASQUERADE就是针对这种场景而设计的，他的作用是，从服务器的网卡上，自动获取当前ip地址来做NAT。

比如下边的命令：

iptables -t nat -A POSTROUTING -s 10.8.0.0/255.255.255.0 -o eth0 -j MASQUERADE

如此配置的话，不用指定SNAT的目标ip了，不管现在eth0的出口获得了怎样的动态ip，MASQUERADE会自动读取eth0现在的ip地址然后做SNAT出去，这样就实现了很好的动态SNAT地址转换。



# 容器网络搭建教程

## 新建ns网络

- 创建网桥：ovs或bridge
- 创建网关：指定ip和虚拟网卡名
- 创建连接：
  - 为每台设备新建一个网络命名空间，并配置lo网络
  - 创建一对虚拟网卡接口，将其中之一加入到新创建的ns中
  - 为ns中的虚拟接口配置ip，启动另一个接口（不需要配置ip）
  - 配置从ns接口到网关的路由
  - 将网关和外部接口连接
- 配置iptables：从ns内部网段到网关网段的nat规则（MASQUERADE模式）
- 启动网关

需要注意的是，所有的node ip必须从1以后开始分配，0被预留为广播地址



## 删除ns网络

- 关闭网关
- 删除网关
- 删除所有新建的ns
- 删除iptables内新增的nat规则



## 新建docker并配置ns网络

- 拉取docker镜像

- 安装依赖：

  ```shell
  {net-tools openssh-server vim iputils-ping iperf iperf3 tcpdump}
  ```

- 为每个docker配置ssh：

  - 允许root登录
  - 修改密码
  - 重启ssh
  - ssh-copy-id到目标docker

- 为已经启动的容器配置ns网络：

  - 创建从容器进程到ns目录下的软连接
  - 其他步骤同ns网络搭建



## 删除docker网络

- 停止容器
- 删除容器
- 从本地ssh列表中删除对应的ip
- 删除ns目录下的对应pid文件
- 删除镜像
- 删除ns网络



## 一些实践bug

新建docker无法连网：Temporary failure resolving 'archive.ubuntu.com'。

解决方案：修改`/etc/default/docker`

```shell
DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4 --dns 127.0.0.53"
```

dns服务器地址可以改为宿主机的对应ip。

修改后重启docker服务：

```c++
sudo service docker restart
```

注意修改后需要删除旧的image文件以更新dns缓存



# 搭建容器互联网络：直接路由

docker跨主机互联的首要问题在于默认的docker0网桥使用了相同的网段导致IP冲突，因此我们需要给每个宿主机新建一个网段，为该机器上的所有docker提供服务：

```c++
docker network create --driver bridge --subnet 12.0.6.0/24 --gateway 12.0.6.200 megaNet
```

搭建好新的docker网段后（自动生成新的网桥megaNet），我们可以使用指定网段/网桥来生成容器：

```shell
sudo nvidia-docker run -dit --name ${_docker_name} --net megaNet ${_version}
```

然后我们需要新增路由来保证每个宿主机可以找到其他机器上的docker：

对于任意一个跨机器docker（假设其megaNet网段为12.0.1.0/24，宿主机IP为192.168.0.1）添加如下路由

```shell
sudo route add -net 12.0.1.0/24 gw 192.168.0.1
```

此时可以确保ping通目标网段的网关（如12.0.6.200），但是可能无法ping通该网段下的docker，原因是在ubuntu系统下主机的forward链默认被drop了，因此添加如下防火墙规则：

```shell
sudo iptables -t filter -P FORWARD ACCEPT
```

即可完成互联。
