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

## Deploying a development cluster

Note: Hector Castro has an excellent [repo](https://github.com/hectcastro/docker-riak) which fully automates this.

Create per-node data directories on the host:

```bash
sudo mkdir /riak
sudo mkdir /riak/node1
sudo mkdir /riak/node1/lib
sudo mkdir /riak/node1/log
sudo cp -R /riak/node1 /riak/node2
sudo cp -R /riak/node1 /riak/node3
```

Launch the containers:

```bash
sudo docker run --name "riak1" -v /riak/node1/lib:/var/lib/riak -v /riak/node1/log:/var/log/riak -d rcgenova/docker-riak-lite
sudo docker run --name "riak2" -v /riak/node2/lib:/var/lib/riak -v /riak/node2/log:/var/log/riak -d rcgenova/docker-riak-lite
sudo docker run --name "riak3" -v /riak/node3/lib:/var/lib/riak -v /riak/node3/log:/var/log/riak -d rcgenova/docker-riak-lite
```

Start Riak:

```bash
sudo docker exec -i -t riak1 riak start
sudo docker exec -i -t riak2 riak start
sudo docker exec -i -t riak3 riak start
```

Configure the cluster:

```bash
IP=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' riak1)
sudo docker exec -i -t riak2 riak-admin cluster join riak@$IP
sudo docker exec -i -t riak3 riak-admin cluster join riak@$IP
sudo docker exec -i -t riak3 riak-admin cluster plan
sudo docker exec -i -t riak3 riak-admin cluster commit
sudo docker exec -i -t riak3 riak-admin member-status
```

## Deploying a production cluster

Provision a host per node. Install Docker, pull the image and run the following commands:

```bash
sudo mkdir /riak
sudo mkdir /riak/lib
sudo mkdir /riak/log
sudo docker run --name "riak" --net=host -v /riak/lib:/var/lib/riak -v /riak/log:/var/log/riak -d rcgenova/docker-riak-lite
sudo docker exec -i -t riak riak start
```

Note the IP address of any one of the nodes:

```bash
IP=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' riak)
```

Join the nodes, running the following on all nodes but the first:

```bash
sudo docker exec -i -t riak riak-admin cluster join riak@$IP
```

Plan and commit (from any node):

```bash
sudo docker exec -i -t riak riak-admin cluster plan
sudo docker exec -i -t riak riak-admin cluster commit
sudo docker exec -i -t riak riak-admin member-status
```

