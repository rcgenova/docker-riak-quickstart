# Recovering a container after crash or restart

Restarting a container in Docker will cause a new private IP address to be assigned. This requires a change to the Riak nodename and a "force-replace" administrative action to [replace the old node with the new one](http://docs.basho.com/riak/latest/ops/running/nodes/renaming) (from a cluster metadata perspective). The use of host-mapped storage VOLUMEs allows us to maintain the node's state through the transition.

The steps below assume that the 'riak1' container was restarted and that the 'riak2' container is used to facilitate the replacement.
  
<b>Get the old nodename:</b>

```bash
OLDNAME=riak@$(sudo docker exec -it riak1 cat /etc/riak/riak.conf | grep nodename | awk -F"@" '{ print $2 }' | tr -d ["\r"])
```

<b>Get the new nodename:</b>

```bash
NEWNAME=riak@$(sudo docker exec -it riak1 ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
```

<b>Inform the cluster that the old node is "down" (from another running container):</b>

```bash
sudo docker exec -it riak2 riak-admin down $OLDNAME
```

<b>Update the nodename setting in /etc/riak/riak.conf, to reflect the new IP:</b>

```bash
sudo docker exec -it riak1 sed -i.bak "s/$OLDNAME/$NEWNAME/" /etc/riak/riak.conf
```

<b>Rename the ring directory (effectively removes it and creates a backup):</b>

```bash
sudo docker exec -it riak1 mv /var/lib/riak/ring /var/lib/riak/ring_old
```

<b>Start riak:</b>

```bash
sudo docker exec -it riak1 riak start
```

<b>Re-join the re-named node to the cluster:</b>

```bash
NODE2NAME=riak@$(sudo docker exec -it riak2 cat /etc/riak/riak.conf | grep nodename | awk -F"@" '{ print $2 }' | tr -d ["\r"])
sudo docker exec -it riak1 riak-admin cluster join $NODE2NAME
```

<b>Issue a force-replace:</b>

```bash
sudo docker exec -it riak2 riak-admin cluster force-replace $OLDNAME $NEWNAME
```

<b>Cluster plan:</b>

```bash
sudo docker exec -it riak2 riak-admin cluster plan
```

<b>Cluster commit:</b>

```bash
sudo docker exec -it riak2 riak-admin cluster commit
```

<b>Member-status:</b>

```bash
sudo docker exec -it riak2 riak-admin member-status
```
