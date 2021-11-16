#What is DHCP?

The Dynamic Host Configuration Protocol (DHCP) is a network service that enables host computers to be automatically assigned settings from a server as opposed to manually configuring each network host. Computers configured to be DHCP clients have no control over the settings they receive from the DHCP server, and the configuration is transparent to the computer’s user.

!!! info "Our Requirements"
     
    Configure DHCP on a standalone server with a single NIC.


##Setup:
Configuring VLAN:

Add VLAN 700 to the eth1 device.

```bash
ip link add link eth1 name eth4 address 00:11:22:33:44:55 type vlan id 700
```

It is not necessary, but you can disable IPv6 on this particular VLAN interface.
```bash
sysctl -w net.ipv6.conf.eth1/700.disable_ipv6=1
```
```bash
net.ipv6.conf.eth1/700.disable_ipv6 = 1
```
Add an IPv4 address.

```bash
ip addr add 10.100.10.77/24 dev eth1.700
```

Bring VLAN interface up.
```bash
ip link set dev eth4 up
```
```bash
ip -detail addr show eth4
```
```c
eth4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc 
   noqueue state UP group default qlen 1000
   link/ether 08:00:27:fa:4b:19 brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 0 maxmtu 65535
   vlan protocol 802.1Q id 700 <REORDER_HDR> numtxqueues 1   
   numrxqueues 1 gso_max_size 65536 gso_max_segs 65535
   inet 10.100.10.77/24 scope global eth1.700
```
To make VLAN 700 on the eth1 interface at the boot time just add the following configuration.
```bash
vi /etc/network/interfaces
```
```c
# add vlan 700 on eth1 - static IP address
auto eth4
iface eth4 inet static
      address 192.168.10.2
      netmask 255.255.255.0
      pre-up sysctl -w net.ipv6.conf.eth1/700.disable_ipv6=1
```
These interfaces will be brought up in the order in which they were listed.    

##Configuring DHCP server:  

First, update the system repository index in your system and install the DHCP server

```bash
apt update && apt-get install isc-dhcp-server -y
```

Specify the interface on which the DHCP server will listen to.

```bash
vi /etc/default/isc-dhcp-server
```
```c
INTERFACESv4="eth4"
```
Add below the lines in the DHCP configuration file.
```bash
vi /etc/dhcp/dhcpd.conf
```
```c
authoritative;
option domain-name "groophy.org";
option domain-name-servers 192.168.0.100;
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
subnet 192.168.10.0 netmask 255.255.255.0 {
    range 192.168.10.11 192.168.10.240;
    option routers 192.168.10.254;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.168.10.255;
}
```

Enable and restart the DHCP server service. Issue the below command in Terminal to do so:
```bash
systemctl restart isc-dhcp-server.service
```
```bash
systemctl status isc-dhcp-server.service
```
##DHCP Client Configuration

Find your network interface name and update the network interface in the configuration.
```bash
ifconfig
```
```bash
vi /etc/network/interfaces
```
```c
auto ens33
iface ens33 inet dhcp
```
Restart the network-manager service and verify the new IP.
```bash
systemctl restart network-manager.service
```
```bash
ifconfig
```
