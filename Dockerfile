FROM phusion/baseimage:0.9.16
MAINTAINER Rob Genova rcgenova@gmail.com

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Environmental variables
ENV RIAK_VERSION 2.1.1-1

# Install Java 7
RUN sed -i.bak 's/main$/main universe/' /etc/apt/sources.list
RUN apt-get update -qq && apt-get install -y software-properties-common && \
    apt-add-repository ppa:webupd8team/java -y && apt-get update -qq && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java7-installer

# Install Riak
RUN curl https://packagecloud.io/install/repositories/basho/riak/script.deb.sh | bash
RUN apt-get install -y riak=${RIAK_VERSION}

# Add run script
COPY scripts/run /etc/service/riak/run
RUN chmod 755 /etc/service/riak/run

## Set configs
RUN sed -i.bak 's/listener.http.internal = 127.0.0.1/listener.http.internal = 0.0.0.0/' /etc/riak/riak.conf && \
    sed -i.bak 's/listener.protobuf.internal = 127.0.0.1/listener.protobuf.internal = 0.0.0.0/' /etc/riak/riak.conf && \
    echo "erlang.distribution.port_range.minimum = 6000" >> /etc/riak/riak.conf && \
    echo "erlang.distribution.port_range.maximum = 7999" >> /etc/riak/riak.conf && \
    echo "search = on"

# Expose ports

## protocol buffers, HTTP
EXPOSE 8087 8098

## EPMD
EXPOSE 4369

## Erlang internode communication
EXPOSE 6000-7999

## Handoff
EXPOSE 8099

## Search
EXPOSE 8985 8093

VOLUME /var/lib/riak
VOLUME /var/log/riak

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
