# docker-riak-lite

Quickstart guide to running Riak on Docker for both development and production environments.

## Install Docker

You will need to install Docker. See: [https://docs.docker.com/installation/](https://docs.docker.com/installation)

## Docker and distributed databases

Storage and networking are two important considerations when running a distributed database on Docker.

### Storage

Docker's Union File System poses performance problems for disk I/O intensive applications. For this reason, it is essential to bypass it with data volumes. The VOLUME instruction in a Dockerfile establishes that the given directory should be externally mounted. Launching the container with the -v option maps the volume to a specific, host-accessible directory. This enables data persistence independent of container status as well as increased performance.

### Networking

Docker uses Bridge/NAT networking & virtual IPs by default. This is acceptable for a development environment where all containers reside on the same host. Distributed systems running in production environments, however, require multiple physical hosts for independence of failure and fault tolerance. Bridge/NAT networking is incompatible with distributed systems due to the fact that internal IPs are not directly addressable outside of the context of their parent host. The only viable production configuration, therefore, is to run each node/container on a dedicated host and expose the host's networking directly to it (using the --net=host option). Cumbersome and complicated workarounds that have the potential to enable multiple containers per host in production are outside of the scope of this guide (for now).

## Get the image

You can clone the repo and build the image locally or just pull it from DockerHub.

### Clone and build

```bash
$ git clone https://github.com/rcgenova/docker-riak-lite.git
$ cd docker-riak-lite
$ sudo docker build -t "rcgenova/docker-riak-lite" .
```

### Pull

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
