#!/bin/bash

# /bin/bash
# exit 0

function bootstrap_db {
       sudo chown -R  mysql: /var/lib/mysql
       sudo chmod 755 /var/lib/mysql
    mysqld_safe --skip-grant-tables  &
    # mysqld_safe --wsrep-new-cluster &
    # Wait for the mariadb server to be "Ready" before starting the security reset with a max timeout
    TIMEOUT=${DB_MAX_TIMEOUT:-60}
    while [[ ! -f /var/lib/mysql/mariadb.pid ]]; do
        if [[ ${TIMEOUT} -gt 0 ]]; then
            let TIMEOUT-=1
            sleep 1
        else
            exit 1
        fi
    done
    TIMEOUT=${DB_MAX_TIMEOUT:-60}
    while [[ ! -S /var/run/mysqld/mysqld.sock ]]; do
        if [[ ${TIMEOUT} -gt 0 ]]; then
            let TIMEOUT-=1
            sleep 1
        else
            exit 1
        fi
    done
    sudo -E kolla_security_reset
    sleep 1
    sudo mysql -u root --password="${DB_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}' WITH GRANT OPTION;"
    sudo mysql -u root --password="${DB_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${DB_ROOT_PASSWORD}' WITH GRANT OPTION;"
    sleep 1
    sudo mysqladmin -uroot -p"${DB_ROOT_PASSWORD}" shutdown
    exit 0
}

# Only update permissions if permissions need to be updated
#if [[ $(stat -c %U:%G /var/lib/mysql) != "mysql:mysql" ]]; then
    sudo chown -R  mysql: /var/lib/mysql
    sudo chmod 755 /var/lib/mysql
#fi

# Create log directory, with appropriate permissions
#if [[ ! -d "/var/log/kolla/mariadb" ]]; then
    mkdir -p /var/log/kolla/mariadb
#fi
#if [[ $(stat -c %a /var/log/kolla/mariadb) != "755" ]]; then
    sudo chmod 755 /var/log/kolla/mariadb
#    sudo chown mysql /var/log/kolla/mariadb    --commented for mariadb.log permission denied issue in heka
#fi

# Create directory, with appropriate permissions
#if [[ ! -d "/var/run/mysqld" ]]; then
    sudo mkdir -p /var/run/mysqld
    sudo chown mysql: /var/run/mysqld
    sudo chmod 755 /var/run/mysqld
#fi

sudo chmod 777 /var/log/kolla/

# disable cluster
sudo sed -i 's/wsrep/# wsrep/g' /etc/mysql/my.cnf

# set up permissions for mysql_secure_installation
sudo chmod 777 .

# This catches all cases of the BOOTSTRAP variable being set, including empty
if [[ "${!KOLLA_BOOTSTRAP[@]}" ]]; then
    sudo mysql_install_db
    sudo chown mysql /var/log/kolla/mariadb/mariadb.log
    bootstrap_db
    exit 0
fi

if [[ "${!BOOTSTRAP_ARGS[@]}" ]]; then
    ARGS="${BOOTSTRAP_ARGS}"
fi

