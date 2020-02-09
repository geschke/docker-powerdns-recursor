#!/bin/bash
set -e

## Execute a command as user pdns
exec_as_pdns() {
  sudo -HEu pdns "$@"
}


# The file_env function is taken from https://github.com/docker-library/mariadb - thanks to the Docker community
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo "Both $var and $fileVar are set (but are exclusive)"
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}


[[ -n $DEBUG_ENTRYPOINT ]] && set -x


# Initialize values that might be stored in a file when using Docker secret
file_env 'PDNS_ALLOW_FROM'
file_env 'PDNS_LOCAL_ADDRESS'
file_env 'PDNS_LOCAL_PORT'
file_env 'PDNS_FORWARD_ZONES'
file_env 'PDNS_FORWARD_ZONES_FILEPATH'


PDNS_ALLOW_FROM=${PDNS_ALLOW_FROM:-}
PDNS_LOCAL_ADDRESS=${PDNS_LOCAL_ADDRESS:-}
PDNS_LOCAL_PORT=${PDNS_LOCAL_PORT:-}
PDNS_FORWARD_ZONES=${PDNS_FORWARD_ZONES:-}
PDNS_FORWARD_ZONES_FILEPATH=${PDNS_FORWARD_ZONES_FILEPATH:-}


PDNS_AUTOCONFIG=${PDNS_AUTOCONFIG:-true}

trap "rec_control quit" SIGINT SIGTERM

# PowerDNS Recursor config file on default path
PDNS_CONFIG_FILE=/etc/powerdns/recursor.conf

PDNS_API_KEY=${PDNS_API_KEY:-none}

if ${PDNS_AUTOCONFIG} ; then

  case ${PDNS_API_KEY} in
    none)
      echo "No API";
      ;;
    *)
      echo "API Key used";

      grep -q "^api-key=" ${PDNS_CONFIG_FILE} || echo "api-key=" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
      sed -i -E "s/(^api-key=)(.*)/\1${PDNS_API_KEY}/g" ${PDNS_CONFIG_FILE};

      grep -q "^webserver=" ${PDNS_CONFIG_FILE} || echo "webserver=" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
      sed -i -E "s/(^webserver=)(.*)/\1yes/g" ${PDNS_CONFIG_FILE};

      grep -q "^webserver-address=" ${PDNS_CONFIG_FILE} || echo "webserver-address=" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
      sed -i -E "s/(^webserver-address=)(.*)/\10\.0\.0\.0/g" ${PDNS_CONFIG_FILE};

      grep -q "^webserver-port=" ${PDNS_CONFIG_FILE} || echo "webserver-port=" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
      sed -i -E "s/(^webserver-port=)(.*)/\18081/g" ${PDNS_CONFIG_FILE};

      grep -q "^webserver-allow-from=" ${PDNS_CONFIG_FILE} || echo "webserver-allow-from=" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
      sed -i -E "s/(^webserver-allow-from=)(.*)/\10\.0\.0\.0\/0/g" ${PDNS_CONFIG_FILE};

    ;;
  esac

  if [[ ! -z "$PDNS_ALLOW_FROM" ]] ; then

    grep -q "^allow-from=" ${PDNS_CONFIG_FILE} || echo "allow-from=" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
    PDNS_ALLOW_FROM="$(echo $PDNS_ALLOW_FROM | sed 's/\./\\\./g')"
    PDNS_ALLOW_FROM="$(echo $PDNS_ALLOW_FROM | sed 's/\,/\\\,/g')"
    PDNS_ALLOW_FROM="$(echo $PDNS_ALLOW_FROM | sed 's,\/,\\\/,g')"
    sed -i -E "s,(^allow-from=)(.*),\1${PDNS_ALLOW_FROM},g" ${PDNS_CONFIG_FILE};
    
  fi

  if [[ ! -z "$PDNS_LOCAL_ADDRESS" ]] ; then

    grep -q "^local-address=" ${PDNS_CONFIG_FILE} || echo "local-address=" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
    PDNS_LOCAL_ADDRESS="$(echo $PDNS_LOCAL_ADDRESS | sed 's/\./\\\./g')"
    PDNS_LOCAL_ADDRESS="$(echo $PDNS_LOCAL_ADDRESS | sed 's/\,/\\\,/g')"
    PDNS_LOCAL_ADDRESS="$(echo $PDNS_LOCAL_ADDRESS | sed 's,\/,\\\/,g')"
    sed -i -E "s,(^local-address=)(.*),\1${PDNS_LOCAL_ADDRESS},g" ${PDNS_CONFIG_FILE};

  fi

  if [[ ! -z "$PDNS_LOCAL_PORT" ]] ; then

    grep -q "^local-port=" ${PDNS_CONFIG_FILE} || echo "local-port=" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
    PDNS_LOCAL_PORT="$(echo $PDNS_LOCAL_PORT | sed 's/\./\\\./g')"
    PDNS_LOCAL_PORT="$(echo $PDNS_LOCAL_PORT | sed 's/\,/\\\,/g')"
    PDNS_LOCAL_PORT="$(echo $PDNS_LOCAL_PORT | sed 's,\/,\\\/,g')"
    sed -i -E "s,(^local-port=)(.*),\1${PDNS_LOCAL_PORT},g" ${PDNS_CONFIG_FILE};

  fi


  if [[ ! -z "$PDNS_FORWARD_ZONES" ]] ; then

    grep -q "^forward-zones=" ${PDNS_CONFIG_FILE} || echo "forward-zones=" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
    PDNS_FORWARD_ZONES="$(echo $PDNS_FORWARD_ZONES | sed 's/\./\\\./g')"
    PDNS_FORWARD_ZONES="$(echo $PDNS_FORWARD_ZONES | sed 's/\,/\\\,/g')"
    PDNS_FORWARD_ZONES="$(echo $PDNS_FORWARD_ZONES | sed 's,\/,\\\/,g')"
    sed -i -E "s,(^forward-zones=)(.*),\1${PDNS_FORWARD_ZONES},g" ${PDNS_CONFIG_FILE};

  fi

  if [[ ! -z "$PDNS_FORWARD_ZONES_FILEPATH" ]] ; then

    grep -q "^forward-zones-file=" ${PDNS_FORWARD_ZONES_FILEPATH} || echo "forward-zones-file=" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
    PDNS_FORWARD_ZONES_FILEPATH="$(echo $PDNS_FORWARD_ZONES_FILEPATH | sed 's/\./\\\./g')"
    PDNS_FORWARD_ZONES_FILEPATH="$(echo $PDNS_FORWARD_ZONES_FILEPATH | sed 's/\,/\\\,/g')"
    PDNS_FORWARD_ZONES_FILEPATH="$(echo $PDNS_FORWARD_ZONES_FILEPATH | sed 's,\/,\\\/,g')"
    sed -i -E "s,(^forward-zones-file=)(.*),\1${PDNS_FORWARD_ZONES_FILEPATH},g" ${PDNS_CONFIG_FILE};

  fi


fi



appStart () {
    
  # start PowerDNS recursor
  echo "Starting PowerDNS Recursor..."
  /usr/sbin/pdns_recursor

}


appHelp () {
  echo "Available options:"
  echo " app:start          - Starts PowerDNS Recursor (default)"
  echo " [command]          - Execute the specified linux command eg. bash."
}


case ${1} in
  app:start)
    appStart
    ;;
  app:help)
    appHelp
    ;;   
  *)
    if [[ -x $1 ]]; then
      $1
    else
      prog=$(which $1)
      if [[ -n ${prog} ]] ; then
        shift 1
        $prog $@
      else
        appHelp
      fi
    fi
    ;;
esac

exit 0