FROM ubuntu:focal

LABEL maintainer="Ralf Geschke <ralf@kuerbis.org>"

LABEL last_changed="2020-02-01"


# necessary to set default timezone Etc/UTC
ENV DEBIAN_FRONTEND noninteractive


RUN apt-get update \
  && apt-get -y upgrade \
  && apt-get -y dist-upgrade \
  && apt-get install -y ca-certificates \
  && apt-get install -y --no-install-recommends \
  && apt-get install -y locales \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  && apt-get install -y curl git gnupg


#RUN apt update    

# testing Ubuntu 20.04 focal, in case of errors, switch to 18.04 again

RUN apt install -y pdns-recursor
#server pdns-backend-sqlite3 pdns-backend-mysql mysql-client

# bind etc., remove later! 
RUN apt install -y dnsutils iproute2 sqlite3



EXPOSE 8081
EXPOSE 53/udp
EXPOSE 53/tcp 


USER root
RUN mkdir -p /app
COPY entrypoint.sh /app/entrypoint.sh
#COPY wait-for-it.sh /app/wait-for-it.sh
RUN chmod 755 /app/entrypoint.sh 
#&& chmod 755 /app/wait-for-it.sh
RUN chown -R pdns:pdns /app

#USER pdns 
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["app:start"]
