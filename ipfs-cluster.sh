#!/bin/bash

## DESCRIPTION: 

## AUTHOR: CHITRABALAN M (mchitrabalan@gmail.com)

sudo rm -r /home/$USER/ipfs
GO=`which go`
if test -z $GO
then
	sudo snap install go
fi

IPFS=`which ipfs`
if test -z $IPFS
then
	sudo mkdir /home/$USER/ipfs && cd /home/$USER/ipfs
	wget https://dist.ipfs.io/go-ipfs/v0.10.0/go-ipfs_v0.10.0_linux-amd64.tar.gz
	tar -xvzf go-ipfs_v0.10.0_linux-amd64.tar.gz
	cd go-ipfs
	chmod +x install.sh
	sudo ./install.sh
fi

sudo rm -r /home/$USER/IPFS-dep
mkdir /home/$USER/IPFS-dep && cd IPFS-dep
ipfs init
ipfs version
sudo sysctl -w net.core.rmem_max=2500000
ipfs bootstrap rm all
sudo npm install ipfs-swarm-key-gen -g
node-ipfs-swarm-key-gen > ~/.ipfs/swarm.key
touch /home/$USER/IPFS-dep/ipfs_id.txt
ipfs id > /home/$USER/IPFS-dep/ipfs_id.txt
IPFS_DEP=/home/$USER/IPFS-dep/
IPFS_ID=`grep ID $IPFS_DEP/ipfs_id.txt | cut -d: -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
echo "$IPFS_ID"

echo "Enter the Public IP Address "
read -p "IP Addr : " IP_ADDR
echo $IP_ADDR

ifconfig > "$IPFS_DEP"/ifconfig.txt
CHECK_IP=`grep "$IP_ADDR" "$IPFS_DEP"/ifconfig.txt`
if test -z "$CHECK_IP"
then
	echo "Enter the Correct Interface IP Address"
	goto exit
fi



echo "Do you want to change Gateway port from 8080"
read -p "Y or N :" RES
if test "$RES" = "Y"
then
	read -p "Enter the Port Number : " PORT
	sudo sed 's/8080/'$PORT'/g' /home/$USER/.ipfs/config
fi

ipfs bootstrap add /ip4/$IP_ADDR/tcp/4001/ipfs/$IPFS_ID
PEER_ID=ipfs bootstrap add /ip4/'$IP_ADDR'/tcp/4001/ipfs/'$IPFS_ID'
echo "PEER_ID "
echo $PEER_ID
export LIBP2P_FORCE_PNET=1
gnome-terminal -x sh -c "ipfs daemon"


IPFS_CLUSTER=`which ipfs-cluster-service`
if test -z $IPFS_CLUSTER;
then
	echo "Entering to install Cluster Service for IPFS"
	git clone https://github.com/ipfs/ipfs-cluster.git
	cd ipfs-cluster
	make install
	cd /home/$USER/IPFS-dep/ipfs-cluster/cmd/
	sudo cp -r ipfs*/ipfs* /bin
	ipfs-cluster-service --version
	ifs-cluster-ctl --version
fi

CLUSTER_SECRET=`od -vN 32 -An -tx1 /dev/urandom | tr -d ' \n'`
echo "export CLUSTER_SECRET = $CLUSTER_SECRET" >> /home/$USER/.bashrc
source /home/$USER/.bashrc

ipfs-cluster-service init
echo "Is it First Node : "
read -p "Y or N : " RES
if test "$RES" = "Y"
then 
	ipfs-cluster-service daemon
	echo "Cluster started sucessfully"
	BOOTSTRAP_ID=`grep id /home/$USER/.ipfs-cluster/identity.json | cut -d: -f2 | sed 's/"//g' |sed 's/,//g' |sed 's/ //g'`
	echo $BOOTSTRAP_ID > Bootstrap_id.txt
	echo $BOOTSTRAP_ID
	touch restart.sh
	echo "ipfs daemon &" > restart.sh
	echo "ipfs-cluster-service daemon &" >> restart.sh
	
else
	echo "Enter the String to Be pasted from First node"
	read -p "paste string bootstrap  ID :" BID
	gnome-terminal -x sh -c "ipfs-cluster-service daemon --bootstrap $BID"
	echo "ipfs daemon &" > restart.sh
	echo "ipfs-cluster-service daemon --bootstrap /ip4/$IP_ADDR/tcp/9096/p2p/$BID" >> restart.sh	
fi

exit:
	echo "Finished Installation ."
