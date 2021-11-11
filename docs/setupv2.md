#Setup

Configure the host file with the hostname and IPs.

``` bash
cat /etc/hosts
```

```c
192.168.0.100 dnsserver.cruise.com
192.168.135.21 test01.cruise.com
192.168.0.100 dnsserver
127.0.0.1 localhost
```
Download CoreDNS from the website, unpack the binary to ==/usr/local/bin== and make it executable.

```bash 
wget https://github.com/coredns/coredns/releases/download/v1.8.6/coredns_1.8.6_linux_amd64.tgz  
```
``` bash 
tar -xvzf coredns_1.8.6_linux_amd64.tgz
```
``` bash
cp coredns /usr/local/bin/
```
``` bash
sudo chmod +x /usr/local/bin/coredns
```
``` bash
ll /usr/local/bin/coredns
```
Install resolvconf as a tool to manually manage ==/etc/resolv.conf==.

``` bash
apt install resolvconf
```
Set dns as default in ==/etc/NetworkManager/NetworkManager.conf==.

``` bash
vi /etc/NetworkManager/NetworkManager.conf
```
```
dns=default
```
Add nameserver 127.0.0.1 to ==/etc/resolvconf/resolv.conf.d/head==.

``` bash
vi /etc/resolvconf/resolv.conf.d/head
```
```
nameserver 127.0.0.1
```
Create ==/etc/coredns/Corefile== and paste the configuration shown below. 

```bash
vi /etc/coredns/Corefile
```
```
groophy.org:53 {
    	forward . tls://2606:4700:4700::1111 tls://1.1.1.1
    	hosts /etc/hosts
log
    	errors
    	Cache
}
.:53 {
    	forward . tls://2606:4700:4700::1111 tls://1.1.1.1
    	log
    	errors
    	Cache
}
```
We are using Cloudflare as a DNS provider(1.1.1.1).

Create a new user for CoreDNS and set some permissions on the ==/opt/coredns== directory.

```bash
sudo useradd -d /var/lib/coredns -m coredns
```
```bash
sudo chown coredns:coredns /opt/coredns
```
Download the SystemD service unit file from coredns to ==/etc/systemd/system/coredns.service==.

```bash
wget https://github.com/coredns/deployment/blob/master/systemd/coredns.service   
```
```bash
mv coredns.service /etc/systemd/system/
```
Disable SystemD's default DNS server.

```bash
sudo systemctl stop systemd-resolved && sudo systemctl disable systemd-resolved
```
???+ note

    From that moment on, you will not be able to resolve any web pages anymore, unless you enable DNS again

Enable and start CoreDNS

```bash
sudo systemctl enable coredns && sudo systemctl start coredns
```
Now we can able to resolve domain names, again. E.g. try to ==dig +short kit.edu==. If an IP address is printed, everything works fine.

```bash
dig +short kit.edu
```
??? success "Output"
    ```c
    141.3.128.6
    ```
Try the below command
```bash
nslookup dnsserver.groophy.org
```
??? success "Output"
    ```c
    Server:         192.168.0.100
    Address:        192.168.0.100#53

    Name:   dnsserver.cruise.com
    Address: 192.168.0.100
    ```
Try the below command
```bash
nslookup google.com
```
??? success "Output"
    ```c 
    Server:         192.168.0.100
    Address:        192.168.0.100#53

    Non-authoritative answer:
    Name:   google.com
    Address: 142.250.71.14
    Name:   google.com
    Address: 2404:6800:4007:824::200e
    ```

!!! info "Conclusion"
        
    Able to resolve both internal servers and outside the world.
