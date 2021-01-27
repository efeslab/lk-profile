#!/bin/bash

apt update

DEBIAN_FRONTEND=noninteractive \
    apt install -y \
    sudo \
    ssh \
    net-tools \
    ethtool \
    ifupdown \
    network-manager \
    iputils-ping \
    git \
    vim \
    redis \
    memcached \
    mysql-server \
    postgresql postgresql-contrib \
    nginx \
    apache2 \
    cmake \
    build-essential \
    libgflags-dev \
    libsnappy-dev \
    zlib1g-dev \
    libbz2-dev \
    liblz4-dev \
    libzstd-dev
