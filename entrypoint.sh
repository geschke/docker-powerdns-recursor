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
#file_env 'MYSQL_HOST'

#PDNS_BACKEND=${PDNS_BACKEND:-none}
#PDNS_AUTOCONFIG=${PDNS_AUTOCONFIG:-true}


trap "rec_control quit" SIGINT SIGTERM

# PowerDNS config file on default path
PDNS_CONFIG_FILE=/etc/powerdns/pdns.conf

PDNS_API_KEY=${PDNS_API_KEY:-none}


#if ${PDNS_AUTOCONFIG} ; then

#  case ${PDNS_API_KEY} in
#    none)
#      echo "No API";
#      ;;
#    *)
#      echo "API Key used";

#      grep -q "^api=" ${PDNS_CONFIG_FILE} || echo "api=\n" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
#      sed -i -E "s/(^api=)(.*)/\1yes/g" ${PDNS_CONFIG_FILE};

#      grep -q "^api-key=" ${PDNS_CONFIG_FILE} || echo "api-key=\n" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
#      sed -i -E "s/(^api-key=)(.*)/\1${PDNS_API_KEY}/g" ${PDNS_CONFIG_FILE};

#      grep -q "^webserver=" ${PDNS_CONFIG_FILE} || echo "webserver=\n" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
#      sed -i -E "s/(^webserver=)(.*)/\1yes/g" ${PDNS_CONFIG_FILE};

#      grep -q "^webserver-address=" ${PDNS_CONFIG_FILE} || echo "webserver-address=\n" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
#      sed -i -E "s/(^webserver-address=)(.*)/\10\.0\.0\.0/g" ${PDNS_CONFIG_FILE};

#      grep -q "^webserver-port=" ${PDNS_CONFIG_FILE} || echo "webserver-port=\n" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
#      sed -i -E "s/(^webserver-port=)(.*)/\18081/g" ${PDNS_CONFIG_FILE};

#      grep -q "^webserver-allow-from=" ${PDNS_CONFIG_FILE} || echo "webserver-allow-from=\n" | tee --append ${PDNS_CONFIG_FILE} > /dev/null;
#      sed -i -E "s/(^webserver-allow-from=)(.*)/\10\.0\.0\.0\/0/g" ${PDNS_CONFIG_FILE};


#    ;;
#  esac


#fi

appCheck () {
  echo "Check PowerDNS database..."
  case ${PDNS_BACKEND} in
    mysql)
      echo "MySQL backend, starting PowerDNS server...";
      /app/wait-for-it.sh -t 30 ${MYSQL_HOST}:${MYSQL_PORT} 
      if [ $? -ne 0 ]; then
        echo "Error by connecting MySQL database, could not initialize check."
        return 1 # error
      else
        echo "Check database..."
        # The query command is taken from https://github.com/psi-4ward/docker-powerdns/blob/master/entrypoint.sh
        if [ "$(echo "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = \"$MYSQL_NAME\";" | $MYSQL_CLI)" -ne 0 ]; then
          echo "Check successful, database exists..."
          return 0
        else
          appInit
          return $?
        fi
      fi
      ;;
    sqlite3)
      echo "Check database...";

      if [ ! -f "$SQLITE3_PATH" ]; then
        echo "Database file does not exist, creating..."
        touch ${SQLITE3_PATH}
      fi
      echo "Check tables in database..."
      if [ "$(echo ".tables" | sqlite3 ${SQLITE3_PATH} | wc -w)" -ne 0 ]; then
          echo "Check successful, database exists..."
          return 0
        else
          appInit
          return $?
        fi
      return 0
    
      ;;   
    *)
      echo "No backend or backend not supported, omit check...";
      return 0
      ;;
  esac

}


appStart () {
    
  # start Powerdns
  echo "Starting PowerDNS Recursor..."
  /usr/sbin/pdns_recursor

  #
  #appCheck
  #if [ $? -ne 0 ] 
  #then
  #  echo "Error by checking, exit..."
  #  return 0
  #else

  #  case ${PDNS_BACKEND} in
  #    mysql)
  #      
  #      echo "MySQL backend, starting PowerDNS server...";
  #      /app/wait-for-it.sh -t 30 ${MYSQL_HOST}:${MYSQL_PORT} 
  #      if [ $? -ne 0 ]; then
  #        echo "Error by connecting MySQL database, could not start PowerDNS."
  #        return 1
  #      else
  #        echo "start PowerDNS..."

  #        exec /usr/sbin/pdns_server --daemon=no --guardian=no --loglevel=9
  #        return 0
  #      fi
      
  #      ;;
  #    sqlite3)
  #      echo "SQLite3 backend, starting PowerDNS server...";
  #      exec /usr/sbin/pdns_server --daemon=no --guardian=no --loglevel=9
      
  #      ;;   
  #    *)
  #      echo "No backend or backend not supported, starting...";
  #      exec /usr/sbin/pdns_server --daemon=no --guardian=no --loglevel=9
  #      ;;
  #  esac
  #fi
}


appHelp () {
  echo "Available options:"
  echo " app:start          - Starts Powerdns Recursor (default)"
  #echo " app:init           - Initialize Database"
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