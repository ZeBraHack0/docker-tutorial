# 为什么需要NVIDIA Docker

Docker 容器与平台无关，但也与硬件无关。当使用特殊的硬件，如 NVIDIA GPUs 时，这就产生了一个问题，这些硬件需要内核模块和用户级库来操作。因此， Docker 本机不支持容器中的 NVIDIA GPUs 。

解决这个问题的早期解决方案之一是在容器中完全安装 NVIDIA 驱动程序，并在启动时映射到与 NVIDIA GPUs （例如 `/dev/nvidia0` ）对应的字符设备中。此解决方案很脆弱，因为主机驱动程序的版本必须与容器中安装的驱动程序版本完全匹配。这一要求大大降低了这些早期容器的可移植性，破坏了 Docker 更重要的特性之一。

为了使 Docker 映像能够利用 NVIDIA GPUs 实现可移植性，英伟达开发了 [`nvidia-docker` ](https://github.com/NVIDIA/nvidia-docker)，这是一个托管在 Github 上的开源项目，它提供了基于 GPU 的可移植容器所需的两个关键组件：

1. 与驱动程序无关的 CUDA 图像；以及
2. Docker 命令行包装器，在启动时将驱动程序和 GPUs （字符设备）的用户模式组件装入容器。

`nvidia-docker` 本质上是围绕 `docker` 命令的包装器，它透明地为容器提供了在 GPU 上执行代码所需的组件。只有在使用 `nvidia-docker` run 来执行使用 GPUs 的容器时才是绝对必要的。但为了简单起见，在本文中，我们将其用于所有 Docker 命令。



# 安装NVIDIA Docker

NVIDIA Docker依赖于NVIDIA驱动和docker engine，在安装前请确保这两样依赖已经完成安装。

可以使用ansible工具直接安装：

```shell
ansible-galaxy install ryanolson.nvidia-docker
```

也可以使用apt-get安装：

```shell
sudo apt-get install nvidia-docker2
```



# 操作NVIDIA Docker

首先启动容器并挂载megatron：

```shell
alias sdmegatron="sudo nvidia-docker run -dit -v ~megatron:/workspace/megatron nvcr.io/nvidia/pytorch:20.12-py3"
```

可以给命令赋予别名以简化操作。

然后查看新启动的容器id并连接shell：

```shell
sudo docker ps | grep "20.12"
alias domeg="sudo docker exec -it d3522ad007db /bin/bash"
```

