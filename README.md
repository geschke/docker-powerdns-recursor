# geschke/powerdns-recursor

[![Image Size](https://images.microbadger.com/badges/image/geschke/powerdns-recursor.svg)](https://microbadger.com/images/geschke/powerdns-recursor)
[![Version](https://images.microbadger.com/badges/version/geschke/powerdns-recursor.svg)](https://microbadger.com/images/geschke/powerdns-recursor)
[![Docker Automated build](https://img.shields.io/docker/cloud/build/geschke/powerdns-recursor)](https://hub.docker.com/r/geschke/powerdns-recursor)

This is a Docker image with PowerDNS recursor.

## Usage

To download the image run

    docker pull geschke/powerdns-recursor

## Configuration

**Environment Configuration:**

* `PDNS_AUTOCONFIG=true` Set this to false when using your own recursor.conf file.

* `PDNS_ALLOW_FROM=(empty)` Netmasks that are allowed to use the recursor.
* `PDNS_LOCAL_ADDRESS=(empty)` Local address to bind to. If this variable is not set, the default entry in the config file will be used.
* `PDNS_LOCAL_PORT=(empty)` Local port to bind to. If this variable is not set, the default entry in the config file will be used.

* `PDNS_FORWARD_ZONES=(empty)` Private domains to forward to the Authoritative Server.
* `PDNS_FORWARD_ZONES_FILEPATH=(empty)` Path of file with private domains to forward to the Authoritative Server.

* `PDNS_API_KEY=none` By setting an API key, the built-in webserver and the HTTP API  will be activated. It runs on 0.0.0.0/0 on port 8081 in the container, so if you don't want to provide the API publically, just omit the port setting on 8081 in the docker run command or the compose file.

These environment variables create a minimal configuration. If this does not fit your needs, mount your own recursor.conf file into the container to /etc/powerdns/recursor.conf.

## Usage example

```
 docker run -d --publish 192.168.1.1:53:53/udp --publish 192.168.1.1:53:53/tcp \
 --publish 8081:8081 --env "PDNS_API_KEY=Ix2phee9"  \
 --env PDNS_ALLOW_FROM="192.168.1.0/24,172.20.0.0/16,172.21.0.0/16,172.22.0.0/16" \
 --env PDNS_LOCAL_ADDRESS=0.0.0.0 \
 --name pdns_rec \
 geschke/powerdns-recursor
```

More examples coming soon.

## Credits

This image is based on the official Ubuntu image and the Ubuntu PowerDNS packages.

Thank you all!
