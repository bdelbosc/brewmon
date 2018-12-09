#!/bin/bash
set -x
set -e

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

check_archi() {
  case $(uname -m) in
    armv7l)
      ;;
    *)
      echo "### Sorry bm-install script only support Raspberry Pi, armv7l architecture"
      exit 1
  esac
}

echo "### This script will install the BrewMon stack on a RaspberryPI that is running BrewPi in legacy version"

check_archi

echo "### Download latest brewmon source"
wget https://github.com/bdelbosc/brewmon/archive/master.zip -O /tmp/brewmon.zip
unzip /tmp/brewmon.zip -d /tmp

if [[ ! -f /etc/influxdb/influxdb.conf ]]; then
  echo "### Installing configuration files for InfluxDB and Grafana"
  sudo /bin/cp -arn /tmp/brewmon-master/etc/influxdb /etc/
  sudo /bin/cp -arn /tmp/brewmon-master/etc/grafana /etc/
fi

if command_exists influx; then
  echo "### InfluxDB already installed"
else
  echo "### Install InfluxDB"
  wget https://dl.influxdata.com/influxdb/releases/influxdb_1.7.1_armhf.deb -O /tmp/influxdb.deb
  sudo dpkg --force-confold -i /tmp/influxdb.deb
  /bin/rm /tmp/influxdb.deb
fi

echo "### Make sure InfluxDB is up"
sudo systemctl start influxdb.service

echo "### Make sure brewmon database exists"
influx -execute "CREATE DATABASE brewmon"

if command_exists grafana-cli; then
  echo "### Grafana already installed"
else
  echo "### Install Grafana and ajax plugin"
  wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_5.4.0_armhf.deb -O /tmp/grafana.deb
  sudo dpkg --force-confold -i /tmp/grafana.deb
  /bin/rm /tmp/grafana.deb
  sudo grafana-cli plugins install ryantxu-ajax-panel
  sudo service grafana-server restart
fi

echo "### Install brewmon python package"
cd /tmp/brewmon-master
sudo python setup.py install --force

if [[ ! -f /var/www/html/lcd.php ]]; then
  echo "### Add a lcp.php page to BrewPi"
  sudo wget https://raw.githubusercontent.com/bdelbosc/brewpi-www/legacy/lcd.php -O /var/www/html/lcd.php
  sudo chown www-data.www-data /var/www/html/lcd.php
fi

if [[ ! -f /home/brewpi/brewpi.py.brewmon-backup ]]; then
  echo "### Backup brewpi.py script"
  sudo cp /home/brewpi/brewpi.py /home/brewpi/brewpi.py.brewmon-backup
  echo "### Patch brewpi.py"
  sudo wget https://raw.githubusercontent.com/bdelbosc/brewpi-script/legacy/brewpi.py -O /home/brewpi/brewpi.py
  sudo chown brewpi.brewpi /home/brewpi/brewpi.py
fi

echo "### Cleaning"
/bin/rm -rf /tmp/brewmon.zip /tmp/brewmon-master

echo "### BrewMon ready, you need to restart the BrewPi script"
