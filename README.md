# docker-riak-quickstart

Quickstart guide to running Riak on Docker for both development and production environments. (Please note that Basho does not officially support or recommend deploying Riak in production with Docker.)

## Install Docker

You will need to install Docker. See: [https://docs.docker.com/installation](https://docs.docker.com/installation).

## Docker and distributed databases

Storage and networking are two important considerations when running a distributed database on Docker.

### Storage

Docker's Union File System poses performance problems for disk I/O intensive applications. For this reason, it is essential to bypass it with data volumes. The VOLUME instruction in a Dockerfile establishes that the given directory should be externally mounted. Launching the container with the -v option maps the volume to a specific, host-accessible directory. This enables data persistence independent of container status as well as increased performance.

### Networking

Docker uses [Bridge/NAT networking](https://docs.docker.com/articles/networking/#how-docker-networks-a-container) & virtual IPs by default. This is acceptable for a development environment where all containers reside on the same host. Distributed systems running in production environments, however, require multiple physical hosts for independence of failure and fault tolerance. Bridge/NAT networking is incompatible with distributed systems due to the fact that internal IPs are not directly addressable outside of the context of their parent host. The only viable production configuration, therefore, is to run each node/container on a dedicated host and expose the host's networking directly to it (using the --net=host option at runtime). Cumbersome and complicated workarounds that have the potential to enable multiple containers per host in production are outside of the scope of this guide.

## Get the image

You can clone the repo and build the image locally or just pull it from DockerHub.

### Clone and build

```bash
$ git clone https://github.com/rcgenova/docker-riak-quickstart.git
$ cd docker-riak-quickstart
$ sudo docker build -t "rcgenova/docker-riak-quickstart" .
```

### Pull

```bash
$ sudo docker pull rcgenova/docker-riak-quickstart
```

## Deploying a development cluster

Note: Hector Castro has an excellent [repo](https://github.com/hectcastro/docker-riak) which fully automates the installation of a development environment.

Create per-node data directories on the host:

```bash
sudo mkdir /riak
sudo mkdir /riak/node1
sudo mkdir /riak/node1/lib
sudo mkdir /riak/node1/log
sudo cp -R /riak/node1 /riak/node2
sudo cp -R /riak/node1 /riak/node3
```

You may need to disable selinux ('sudo setenforce 0') on the host to enable the containers to write to the directories. [Boot2Docker](https://github.com/boot2docker/boot2docker) has it's own volume sharing requirements.  

Launch the containers. Note the volume mappings and exposing of ports 8087 and 8098 for the first container:

```bash
sudo docker run --name "riak1" -p 8087:8087 -p 8098:8098 -v /riak/node1/lib:/var/lib/riak -v /riak/node1/log:/var/log/riak -d rcgenova/docker-riak-quickstart
sudo docker run --name "riak2" -v /riak/node2/lib:/var/lib/riak -v /riak/node2/log:/var/log/riak -d rcgenova/docker-riak-quickstart
sudo docker run --name "riak3" -v /riak/node3/lib:/var/lib/riak -v /riak/node3/log:/var/log/riak -d rcgenova/docker-riak-quickstart
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

Wait a few minutes, then test via the HTTP API and the /stats endpoint:

```bash
curl localhost:8098/stats | python -m json.tool
```

Next steps: get started with a [Riak client](http://docs.basho.com/riak/latest/dev/taste-of-riak)!

## Deploying a production cluster

<b>As mentioned above in the Networking section, production deployments require a dedicated host per Riak node/container.</b>  

Install Docker, pull the image and run the following commands (on each host):

```bash
sudo mkdir /riak
sudo mkdir /riak/lib
sudo mkdir /riak/log
sudo docker run --name "riak" --net=host -v /riak/lib:/var/lib/riak -v /riak/log:/var/log/riak -d rcgenova/docker-riak-quickstart
sudo docker exec -i -t riak riak start
sudo docker exec -i -t riak riak ping
```

Obtain the eth0 IP address of any one of the hosts:

```bash
IP=$(sudo docker exec -it riak ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
```

Then, join the nodes by running the following command on all nodes but the first:

```bash
sudo docker exec -i -t riak riak-admin cluster join riak@$IP
```

Plan and commit (from any node):

```bash
sudo docker exec -i -t riak riak-admin cluster plan
sudo docker exec -i -t riak riak-admin cluster commit
sudo docker exec -i -t riak riak-admin member-status
```

## Configuration & tuning

The only non-default configuration in the Dockerfile is the enablement of [Riak Search](http://docs.basho.com/riak/latest/dev/using/search). You should review the documentation on [basic configuration](http://docs.basho.com/riak/latest/ops/building/configuration) and [choosing a backend](http://docs.basho.com/riak/latest/ops/building/planning/backends) to determine whether or not additional changes make sense. Changes to the default configs will require building a new image from an updated Dockerfile.  

It's also a good idea to [tune your Linux host(s)](http://docs.basho.com/riak/latest/ops/tuning/linux).

## Administration

Recovery from a downed container requires jumping through a few hoops administratively. See [ContainerRecovery.md](ContainerRecovery.md).


