FROM ubuntu:lunar-20230314

LABEL maintainer="Ralf Geschke <ralf@kuerbis.org>"

LABEL last_changed="2023-04-04"


# necessary to set default timezone Etc/UTC
ENV DEBIAN_FRONTEND noninteractive


# Ubuntu 23.04 lunar
RUN apt-get update \
  && apt-get -y upgrade \
  && apt-get -y dist-upgrade \
  && apt-get install -y ca-certificates \
  && apt-get install -y --no-install-recommends \
  && apt-get install -y locales \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  && apt-get install -y curl git gnupg \
	&& apt-get install -y pdns-recursor \
  && apt-get -y upgrade \
  && rm -rf /var/lib/apt/lists/* 


EXPOSE 8081 53/udp 53/tcp 


USER root
RUN mkdir -p /app && mkdir /run/pdns-recursor && chown -R root:pdns /run/pdns-recursor
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod 755 /app/entrypoint.sh && chown -R pdns:pdns /app 

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["app:start"]
