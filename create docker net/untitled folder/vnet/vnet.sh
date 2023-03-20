#!/bin/bash

source ../include/YCFile.sh
source ../include/YCLog.sh
source ../include/YCTool.sh
source ../include/YCOS.sh

####################################################
username=""
num_node=2
bridge="ovs"  # "ovs" or "brctl"
netPrefix="11.0.0"
gw="vnet-br0"
gw_suffix=200
####################################################

show_usage() {
    appname=$0
    echo_info "Usage: ${appname} [command], e.g., ${appname} create ns"
    echo_info "  -- create  [ns|mininet|docker|kvm]"
    echo_info "  -- destroy [ns|mininet|docker|kvm]"
    echo_info "  -- help                          show help message"
}

cmdbr=""
addbr=""
addif=""
delbr=""
delif=""
set_cmdbr() {
    if [ ${bridge} == "ovs" ]; then
        cmdbr="ovs-vsctl"
        addbr="add-br"
        addif="add-port"
        delbr="del-br"
        delif=""
        local _ret=`check_cmd ${cmdbr}`
        if [ ${_ret} == -1 ]; then
            echo_back "sudo apt-get install openvswitch-switch -y"
        fi 
    else
        cmdbr="brctl"
        addbr="addbr"
        addif="addif"
        delbr="delbr"
        delif="delif"
        local _ret=`check_cmd ${cmdbr}`
        if [ ${_ret} == -1 ]; then
            echo_back "sudo apt-get install bridge-utils -y"
        fi 
    fi
    
    local _ret=`check_cmd ifconfig`
    if [ ${_ret} == -1 ]; then
        echo_back "sudo apt-get install net-tools -y > /dev/null"
    fi

    local _ret=`check_cmd ip`
    if [ ${_ret} == -1 ]; then
        echo_back "sudo apt-get install iproute2 -y > /dev/null"
    fi
}

ns_create() {
    # gateway of the virtual network
    echo_back "sudo ${cmdbr} ${addbr} ${gw}"
    echo_back "sudo ifconfig ${gw} ${netPrefix}.${gw_suffix}/24 up"
    local _start=1
    local _end=${num_node}
    for idx in `seq ${_start} ${_end}`
    do
        namespace="net${idx}"
        intf0="veth-${idx}"
        intf1="br-eth${idx}"
        echo_line 60 "-" "Creating namespace ${namespace}"
        echo_back "sudo ip netns add ${namespace}"
        echo_back "sudo ip link add ${intf0} type veth peer name ${intf1}"
        echo_back "sudo sysctl net.ipv6.conf.${intf0}.disable_ipv6=1"
        echo_back "sudo sysctl net.ipv6.conf.${intf1}.disable_ipv6=1"
        echo_back "sudo ip link set ${intf0} netns ${namespace}"
        echo_back "sudo ip netns exec ${namespace} ifconfig lo 127.0.0.1 up"
        echo_back "sudo ip netns exec ${namespace} ifconfig ${intf0} ${netPrefix}.${idx}/24 up"
        echo_back "sudo ip link set ${intf1} up"
        echo_back "sudo ip netns exec ${namespace} route add default gw ${netPrefix}.${gw_suffix}"
        echo_back "sudo ${cmdbr} ${addif} ${gw} ${intf1}"
    done

    echo_back "sudo iptables -t nat -A POSTROUTING -s ${netPrefix}.0/24 ! -d ${netPrefix}.0/24 -j MASQUERADE"

    echo_back "sudo sysctl -w net.ipv4.ip_forward=1"
    echo_back "sudo ip link set ${gw} up"
}
ns_destroy() {
    echo_back "sudo ifconfig ${gw} down"
    echo_back "sudo ${cmdbr} ${delbr} ${gw}"
  
    local _start=1
    local _end=${num_node}
    for idx in `seq ${_start} ${_end}`
    do
        namespace="net${idx}"
        echo_back "sudo ip netns delete ${namespace}"
    done

    echo_back "sudo iptables -t nat -D POSTROUTING -s ${netPrefix}.0/24 ! -d ${netPrefix}.0/24 -j MASQUERADE"
}

mininet_create() {
    # TODO
    echo_warn "TODO"
}
mininet_destroy() {
    # TODO
    echo_warn "TODO"
}

# https://arthurchiao.art/blog/play-with-container-network-if/
docker_check() {
    local _ret=`check_cmd docker`
    if [[ ${_ret} == -1 ]]; then 
        echo_back "curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun"
    fi
}
docker_create() {
    docker_check

    local _version="ubuntu:18.04"
    local netPrefix="11.0.0"
    local expgw="ATP-br0"
    local expgw_suffix=200
    echo_back "sudo docker pull ${_version}"

    echo_back "sudo ${cmdbr} ${addbr} ${gw}"
    echo_back "sudo ifconfig ${gw} ${netPrefix}.${gw_suffix}/24 up"

    local _sw_list=(net-tools openssh-server vim iputils-ping iperf iperf3 tcpdump)

    local _start=1
    local _end=${num_node}
    for idx in `seq ${_start} ${_end}`
    do
        local _docker_name="node_${idx}"
        echo_line 80 "-" "Creating docker ${_docker_name}"
        echo_back "sudo docker run -tid --name ${_docker_name} ${_version}"

        echo_back "sudo docker exec -ti ${_docker_name} apt-get update > /dev/null"
        for _item in ${_sw_list[@]}
        do
            echo_back "sudo docker exec -ti ${_docker_name} apt-get install ${_item} -y > /dev/null"
        done

        echo_back "sudo docker exec -ti ${_docker_name} bash -c 'echo PermitRootLogin yes >> /etc/ssh/sshd_config'"
        echo_back "sudo docker exec -ti ${_docker_name} passwd"
        echo_back "sudo docker exec -ti ${_docker_name} service ssh restart"
        local _ip_addr=`sudo docker inspect -f "{{ .NetworkSettings.IPAddress }}" ${_docker_name}`
        echo_back "ssh-copy-id root@${_ip_addr}"
        echo_info "try 'ssh root@${_ip_addr}' to login to ${_docker_name}"
     
        local intf0="veth-${idx}"
        local intf1="br-eth${idx}"
        local _vm_pid=`sudo docker inspect -f '{{.State.Pid}}' ${_docker_name}`
	    if [ ! -d /var/run/netns ]; then 
            echo_back "sudo mkdir /var/run/netns"
        fi
        echo_back "sudo ln -s /proc/${_vm_pid}/ns/net /var/run/netns/${_vm_pid}"
        echo_back "sudo ip link add ${intf0} type veth peer name ${intf1}"
        echo_back "sudo sysctl net.ipv6.conf.${intf0}.disable_ipv6=1"
        echo_back "sudo sysctl net.ipv6.conf.${intf1}.disable_ipv6=1"
        echo_back "sudo ip link set ${intf0} netns ${_vm_pid}"
        echo_back "sudo ip netns exec ${_vm_pid} ifconfig ${intf0} ${netPrefix}.${idx}/24 up"
        echo_back "sudo ip link set ${intf1} up"
        echo_back "sudo ${cmdbr} ${addif} ${gw} ${intf1}"

        echo_line 80 "-" "END"
    done

    echo_back "sudo iptables -t nat -A POSTROUTING -s ${netPrefix}.0/24 ! -d ${netPrefix}.0/24 -j MASQUERADE"

    echo_back "sudo sysctl -w net.ipv4.ip_forward=1"
    echo_back "sudo ip link set ${gw} up"
}
docker_destroy() {
    docker_check

    local _version="ubuntu:18.04"
    local _start=1
    local _end=${num_node}
    for idx in `seq ${_start} ${_end}`
    do
        local _docker_name="node_${idx}"
        local _ip_addr=`sudo docker inspect -f "{{ .NetworkSettings.IPAddress }}" ${_docker_name}`
        local _vm_pid=`sudo docker inspect -f '{{.State.Pid}}' ${_docker_name}`
        echo_line 80 "-" "Removing docker ${_docker_name}"
        echo_back "sudo docker stop ${_docker_name}"
        echo_back "sudo docker rm -f ${_docker_name}"
        echo_back "ssh-keygen -f '/home/${username}/.ssh/known_hosts' -R '${_ip_addr}'"
        
        echo_back "sudo unlink /var/run/netns/${_vm_pid}"

        echo_line 80 "-" "END"
    done

    echo_back "sudo docker rmi ${_version}"

    echo_back "sudo ifconfig ${gw} down"
    echo_back "sudo ${cmdbr} ${delbr} ${gw}"
    echo_back "sudo iptables -t nat -D POSTROUTING -s ${netPrefix}.0/24 ! -d ${netPrefix}.0/24 -j MASQUERADE"
}

kvm_create() {
    # TODO
    echo_warn "TODO"
}
kvm_destroy() {
    # TODO
    echo_warn "TODO"
}

create() {
    local nettype=${1} 
    case ${nettype} in
        "ns")
            ns_create
            ;;
        "mininet")
            mininet_create
            ;;
        "docker")
            docker_create
            ;;
        "kvm")
            kvm_create
            ;;
        *)
            show_usage
            ;;
    esac
}

destroy() {
    local nettype=${1} 
    case ${nettype} in
        "ns")
            ns_destroy
            ;;
        "mininet")
            mininet_destroy
            ;;
        "docker")
            docker_destroy
            ;;
        "kvm")
            kvm_destroy
            ;;
        *)
            show_usage
            ;;
    esac
}

################################################################
####################    * Main Process *    ####################
################################################################
export LC_ALL=C

if (( $# == 0 )); then
    echo_warn "Argument cannot be NULL!"
    show_usage
    exit 0
fi

if (( $UID == 0 )); then
    echo_erro "Don't run this script as root!"
    exit 0
fi

username=`who am i | awk '{print $1}'`
set_cmdbr

global_choice=${1}
case ${global_choice} in
    "create")
        create ${2}
        ;;
    "destroy")
        destroy ${2}
        ;;
    "help")
        show_usage 
        ;;
    *)
        echo_erro "Unrecognized argument!"
        show_usage
        ;;
esac
