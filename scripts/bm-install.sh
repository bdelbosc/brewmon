#!/bin/bash
set -x
set -e
echo "### This script will install the BrewMon stack"

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

if command_exists influx; then
  echo "### InfluxDB already installed"
else
  echo "### Install InfluxDB"
  wget https://dl.influxdata.com/influxdb/releases/influxdb_1.7.1_armhf.deb -O /tmp/influxdb.deb
  sudo dpkg --force-confold -i /tmp/influxdb.deb
  /bin/rm /tmp/influxdb.deb
fi
sudo systemctl start influxdb.service
influx -execute "CREATE DATABASE brewmon"

if command_exists grafana-cli; then
  echo "### Grafana already installed"
else
  echo "### Install Grafana"
  wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_5.4.0_armhf.deb -O /tmp/grafana.deb
  sudo dpkg --force-confold -i /tmp/grafana.deb
  /bin/rm /tmp/grafana.deb
fi

echo "### Patch BrewPi"
echo "TODO"

echo "### Restart BrewPi"
echo "TODO"
