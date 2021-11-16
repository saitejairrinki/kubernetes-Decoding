#Kubernetes Setup With Backup and Restiore Solution 


* Cluster Build Tool  -Kubespray
* Object Storage  -Minio
* Backup Solution  -Velero

???+ info "For this activity, deploy 5 AWS instances with the Security groups"
      All traffic is enabled between the instances

      All traffic enabled for the testing machine(Our Laptop)
	  
|Node Name| Instance Details|
|----|----|
|Ansible Node | -t2.micro |
|Control Plane (2-Nodes) | -t2.medium|
|Worker (2-Nodes) | -t2.medium| 	  

Download the pem-key and transfer the pem-key to ansible node.
```bash
scp -i <pemkey> <pemkey> ubuntu@3.15.192.170:/home/ubuntu/
```
```bash
cp /home/ubuntu/<pemkey> .
```
```bash
chmod 400 <pemkey>
```
```bash
vi /etc/hosts
```
```c
172.31.27.136   cruise.org
```
###Configure HA proxy to build a Multi-master Kubernetes cluster:
Download and install the haproxy
```bash
apt-get update && apt-get install haproxy -y
```
Update haproxy configuration with as below with the details of the Ansible and Master nodes IP
```bash
vi /etc/haproxy/haproxy.cfg
```
```c
listen kubernetes-apiserver-https
  bind ansiblenodeIP:8383
  mode tcp
  option log-health-checks
  timeout client 3h
  timeout server 3h
  server master1 <IP1>:6443 check check-ssl verify none inter 10000
  server master2 <IP2>:6443 check check-ssl verify none inter 10000
  balance roundrobin
```
```bash
systemctl restart haproxy
```
```bash
netstat -atnlp
```

###Deploying Multi-master Kubernetes cluster with Kubespray:

Install Ansible and PIP

```bash
apt update && apt install software-properties-common -y
```
```bash
add-apt-repository --yes --update ppa:ansible/ansible
```
```bash
apt install ansible -y
```
```bash
ansible --version
```
```bash
apt install python3-pip -y
```
Clone the Kubespray source code and install requirements through Pip.
```bash
git clone https://github.com/kubernetes-sigs/kubespray.git
```
```bash
cd kubespray/
```
```bash
pip3 install -r requirements.txt
```
```bash
cp -rfp inventory/sample inventory/mycluster
```
```bash
declare -a IPS=(<master01_IP> <master02_IP> <Worker01_IP> <Worker02_IP>)
```
```bash
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

###Update the HA-Proxy server details
```bash
vi inventory/mycluster/group_vars/all/all.yml
```
```c
## External LB example config
apiserver_loadbalancer_domain_name: "cruise.org"
loadbalancer_apiserver:
   address: 172.31.27.136
   port: 8383
## Internal loadbalancers for apiservers
loadbalancer_apiserver_localhost: false
```
Enable Kubernetes dashboard by updating the below files
```bash
vi inventory/sample/group_vars/k8s_cluster/addons.yml
```
```bash
vi inventory/mycluster/group_vars/k8s_cluster/addons.yml
```
```c
# Kubernetes dashboard
# RBAC required. see docs/getting-started.md for access details.
dashboard_enabled: true
```
Deploy cluster with below Ansible command.
```bash
ansible all -m ping -i inventory/mycluster/hosts.yaml --user ubuntu --private-key ../kmvelero.pem
```
```bash
ansible-playbook -i inventory/mycluster/hosts.yaml  --user ubuntu --private-key kmvelero.pem --become cluster.yml
```
On Master Node:
```bash
kubectl get nodes
```
??? Success "Output"
    ```c
	NAME    STATUS   ROLES                  AGE     VERSION
    node1   Ready    control-plane,master   5h14m   v1.22.3
    node2   Ready    control-plane,master   5h14m   v1.22.3
    node3   Ready    <none>                 5h13m   v1.22.3
    node4   Ready    <none>                 5h13m   v1.22.3
    ```
	
###Configure Minio on the Ansible Node:	
```bash
wget https://dl.min.io/server/minio/release/linux-amd64/minio
```
```bash
chmod +x minio
```
```bash
ll /usr/bin/minio
```
```bash
export MINIO_ROOT_USER=<Username>
```
```bash
export MINIO_ROOT_PASSWORD=<Password>
```
```bash
nohup minio server --console-address <AnsibleNodeIP>:<Port> /data > /dev/null 2>&1 &
```
Manually create the bucket by accessing the Minio Console.

###Configure Velero:
Switch to any master and download the velero source code and configure it.
```bash
Kubernetes Master Node01
```
```bash
ssh -i kmvelero.pem ubuntu@172.31.16.30
```
```bash
wget https://github.com/vmware-tanzu/velero/releases/download/v1.7.0/velero-v1.7.0-linux-amd64.tar.gz
```
```bash
tar -xvzf velero-v1.7.0-linux-amd64.tar.gz
```
```bash
mv velero-v1.7.0-linux-amd64/velero /usr/local/bin/
```
```bash
wget https://github.com/digitalocean/velero-plugin/archive/refs/tags/v1.0.0.tar.gz
```
```bash
nohup tar -xvzf v1.0.0.tar.gz
```
```bash
source <(velero completion bash)
```
Provide the username and password of the Minio console.
```bash
cp velero-plugin-1.0.0/examples/cloud-credentials cloud-credentials
```
```bash
vi cloud-credentials
```
[default]
```bash
aws_access_key_id=<MinioUsername>
```
```bash
aws_secret_access_key=<MinioPassword>
```
```bash
Initiate Velero to store the backup in the Minio buckets.
```
```bash
velero install --provider aws --plugins velero/velero-plugin-for-aws:v1.0.0 --bucket <bucketname created in the minio console> -- backup-location-configregion=minio,s3ForcePathStyle=true,s3Url=http://ansible_host(minio):9000 --secret-file <CredentialFile> 
```
Validate the access:
```bash
velero get backup-location
```
??? success "output"
    ```c
    NAME      PROVIDER   BUCKET/PREFIX   PHASE       LAST VALIDATED                  ACCESS MODE   DEFAULT
    default   aws        kmvbucket       Available   2021-11-09 12:08:44 +0000 UTC   ReadWrite     true
    ```
Copy the kubeconfig file to the Ansible node.	
```bash
cp /etc/kubernetes/admin.conf /home/ubuntu/
```
```bash
chmod 755 /home/ubuntu/admin.conf
```
```bash
scp -i kmvelero.pem ubuntu@172.31.16.30:/home/ubuntu/admin.conf 
```
```bash
kubeconfig
```
Configure Velero on the Ansible Node to access it from out of the cluster:
```bash
wget https://github.com/vmware-tanzu/velero/releases/download/v1.7.0/velero-v1.7.0-linux-amd64.tar.gz
```
```bash
nohup tar -xvzf velero-v1.7.0-linux-amd64.tar.gz
```
```bash
mv velero-v1.7.0-linux-amd64/velero /usr/local/bin/
```
```bash
wget https://github.com/digitalocean/velero-plugin/archive/refs/tags/v1.0.0.tar.gz
```
```bash
nohup tar -xvzf v1.0.0.tar.gz
```
```bash
cp velero-plugin-1.0.0/examples/cloud-credentials cloud-credentials
```
```bash
vi cloud-credentials
```
```bash
source <(velero completion bash)
```
```bash
vi /etc/hosts
```
###Validate the access from the Ansible node:
```bash
velero get backup-locations --kubeconfig kubeconfig
```
??? success "Output"
    ```c
    NAME      PROVIDER   BUCKET/PREFIX   PHASE       LAST VALIDATED                  ACCESS MODE   DEFAULT
    default   aws        kmvbucket       Available   2021-11-09 12:08:44 +0000 UTC   ReadWrite     true
    ```
	
#Backup & Restore: :material-database-refresh-outline:{ .heart }
##Backup:	
###Creating a namespace and deployment in it.
####On Master01:
```bash
kubectl create ns testing
```
```bash
kubectl -n testing apply -f nginx.yaml ### Deploying 4 nginx pods
```
####On Ansible node:
```bash
velero backup create firstbackup --include-namespaces testing --kubeconfig kubeconfig
```
```bash
velero get backup --kubeconfig kubeconfig
```
??? success "output"
    ```c
     NAME           STATUS      ERRORS   WARNINGS   CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
     firstbackup    Completed   0        0          2021-11-09 12:11:30 +0000 UTC   29d       default            <none>
    ```	
##Restore:
Deleting the Namespace Testing to perform restore
####On Master01:
```bash
kubectl delete namespace testing
```
####On Ansible node:
```bash
velero restore create firstbackup-restore --from-backup firstbackup --kubeconfig kubeconfig
```
```bash
velero get restores --kubeconfig kubeconfig
```
??? success "Output"
    ```c
	 NAME                  BACKUP        STATUS      STARTED                         COMPLETED                       ERRORS   WARNINGS   CREATED                         SELECTOR
     firstbackup-restore   firstbackup   Completed   2021-11-08 11:20:35 +0000 UTC   2021-11-08 11:20:36 +0000 UTC        0        0     2021-11-08 11:20:35 +0000 UTC   <none>
    ```

####On Master01:	
```bash
kubectl get deployments.apps -n testing
```
??? success "Output"
    ```c
	 NAME               READY   UP-TO-DATE   AVAILABLE   AGE
     nginx-deployment   4/4     4            4           155m
    ```
	
####Scheduling backup:
```bash
velero create schedule initbackup1 --schedule="13 12 * * *" --kubeconfig kubeconfig --include-namespaces testing
```
```bash
velero get schedules --kubeconfig kubeconfig
```

!!! Note
    Velero commands can also be executed from the Master node.

