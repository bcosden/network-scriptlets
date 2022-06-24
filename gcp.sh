# Define your variables
project=angular-expanse-327722 #Set your project Name. Get your PROJECT_ID use command: gcloud projects list 
region=us-central1 #Set your region. Get Regions/Zones Use command: gcloud compute zones list
zone=us-central1-c # Set availability zone: a, b or c.
vpcrange=192.168.0.0/24 # Set VPN CIDR
envname=onprem #Enviroment Name you want to create
vmname=vm1 #VM Name
mypip=$(curl -4 ifconfig.io -s) #Gets your Home Public IP or replace with that information. It will add it to the Firewall Rule for remote access to your VM.

#Set default project
gcloud config set project $project

#Create VPC
gcloud compute networks create $envname-vpc \
    --subnet-mode=custom \
    --mtu=1460 \
    --bgp-routing-mode=regional

#Create VPC Subnet
gcloud compute networks subnets create $envname-subnet \
    --range=$vpcrange \
    --network=$envname-vpc \
    --region=$region

#Create Firewall Rule
gcloud compute firewall-rules create $envname-allow-traffic-from-azure \
    --network $envname-vpc \
    --allow tcp,udp,icmp \
    --source-ranges 192.168.0.0/16,10.0.0.0/8,172.16.0.0/16,35.235.240.0/20,$mypip/32

#Create Unbutu VM:
gcloud compute instances create $envname-vm1 \
    --zone=$zone \
    --machine-type=f1-micro \
    --network-interface=subnet=$envname-subnet,network-tier=PREMIUM \
    --image=ubuntu-1804-bionic-v20220126 \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --boot-disk-device-name=$envname-vm1 

#Cloud Router:
gcloud compute routers create $envname-router \
    --region=$region \
    --network=$envname-vpc \
    --asn=16550

#DirectConnect with Connectivity Partner:
gcloud compute interconnects attachments partner create $envname-vlan \
    --region $region \
    --edge-availability-domain availability-domain-1 \
    --router $envname-router \
    --admin-enabled

# Please use the pairing key to provision the attachment with your partner:
#     890c4350-XXXX-YYYY-ZZZZ-db2b6de5768b/us-central1/1

#Cloud Router and Interconnect (VLAN)
gcloud compute interconnects attachments delete $envname-vlan --region $region --quiet
gcloud compute routers delete $envname-router  --region=$region --quiet

#VPN tunnel and Gateway
gcloud compute vpn-tunnels delete $vpntunnelname --region $region --quiet
gcloud compute routes delete $vpntunnelname-route-1 --quiet
gcloud compute forwarding-rules delete $envname-vpn-rule-esp --region $region --quiet
gcloud compute forwarding-rules delete $envname-vpn-rule-udp500 --region $region --quiet
gcloud compute forwarding-rules delete $envname-vpn-rule-udp4500 --region $region --quiet
gcloud compute target-vpn-gateways delete $envname-vpn-gw --region $region --quiet
gcloud compute addresses delete $envname-vpn-pip --region $region --quiet

# VM Instance and Firewall Rules
gcloud compute instances delete $envname-vm1   --zone=$zone --quiet
gcloud compute firewall-rules delete $envname-allow-traffic-from-azure --quiet
gcloud compute networks subnets delete $envname-subnet  --region=$region --quiet
gcloud compute networks delete $envname-vpc --quiet
