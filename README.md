# docker-riak-lite

Run Riak on Docker

## Install Docker

See: [https://www.docker.io/gettingstarted/#h_installation](https://www.docker.io/gettingstarted/#h_installation)

## Storage

Databases perform best on Docker with host-mounted storage. This requires a directly per container on the host system:

```bash
mkdir /data
```

Container volumes are mapped at run time with the -v option. This allows for data persistence when containers go down.

## Networking

Bridge/NAT networking & virtual IPs
Distributed systems
Erlang Port Mapper Daemon
--net=host

## Build image

```bash
$ git clone https://github.com/rcgenova/docker-riak-lite.git
$ cd docker-riak-lite
$ sudo docker build -t "rcgenova/docker-riak-lite" .
```

## Pull image

```bash
$ sudo docker pull rcgenova/docker-riak-lite
```

## Deployment: single node

Build or pull the image (see above).

Create a data directory on the host:

```bash
mkdir /data
```

Launch the container:

```bash
sudo docker run --name "riak" -v /var/lib/riak:/data -d rcgenova/docker-riak-lite
```

## Deployment: dev cluster

<b>Multiple containers on a single host.</b>

Build or pull the image.

Create the data directories:

```bash
mkdir /data1
mkdir /data2
mkdir /data3
```

Launch the containers:

```bash
sudo docker run --name "riak1" -v /var/lib/riak:/data1 -d rcgenova/docker-riak-lite
sudo docker run --name "riak2" -v /var/lib/riak:/data2 -d rcgenova/docker-riak-lite
sudo docker run --name "riak3" -v /var/lib/riak:/data3 -d rcgenova/docker-riak-lite
```

Configure the cluster:

```bash
sudo docker ps (take note of the container IDs)
```

## Deployment: production cluster

<b>The only viable way to run Riak on Docker in production is to run a single container per host with the --net=host option.</b>

```bash
sudo docker run --name "riak" -v /var/lib/riak:/data --net=host -d rcgenova/docker-riak-lite
```
