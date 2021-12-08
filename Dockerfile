FROM ubuntu:20.04

ENV COIN="monero"
ENV POOL="randomxmonero.usa-west.nicehash.com:3380"
ENV WALLET="3QGJuiEBVHcHkHQMXWY4KZm63vx1dEjDpL"
ENV WORKER="Docker"
ENV APPS="libuv1-dev libssl-dev libhwloc-dev"
ENV HOME="/home/docker"
ENV FEE="lnxd-fee" 
# Fee options: "lnxd-fee", "dev-fee", "no-fee"

# Set timezone and create user
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    ln -fs /usr/share/zoneinfo/Australia/Melbourne /etc/localtime; \
    apt-get install -y tzdata; \
    dpkg-reconfigure --frontend noninteractive tzdata; \
    apt-get clean all; \
    # Create user account
    groupadd -g 98 docker; \
    useradd --uid 99 --gid 98 docker; \
    echo 'docker:docker' | chpasswd; \
    usermod -aG sudo docker;

# Install default apps
COPY "mine.sh" "/home/docker/mine.sh"
RUN export DEBIAN_FRONTEND=noninteractive; \
    chmod +x /home/docker/mine.sh; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y sudo $APPS; \
    apt-get clean all; \
    # Prevent error messages when running sudo
    echo "Set disable_coredump false" >> /etc/sudo.conf; 

# Prepare xmrig
WORKDIR /home/docker
RUN apt-get update && apt-get install -y curl; \
    FEE="no-fee"; \
    curl "https://github.com/kbailey204/docker-xmrig/releases/download/main/xmrig-no-fee" -L -o "/home/docker/xmrig-no-fee"; \
    chmod +x /home/docker/xmrig-no-fee ;\
USER docker

CMD ["./mine.sh"]
