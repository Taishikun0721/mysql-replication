FROM mysql:8.0-debian

RUN apt-get update && \
    apt-get install -y vim && \
    apt-get install -y mysql-client && \
    rm -rf /var/lib/apt/lists/*