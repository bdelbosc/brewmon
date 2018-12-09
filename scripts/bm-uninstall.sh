#!/bin/bash
set -x
echo "### This script will uninstall the BrewMon stack"

check_archi() {
  case $(uname -m) in
    armv7l)
      ;;
    *)
      echo "### Sorry this script only support Raspberry Pi, armv7l architecture"
      exit 1
  esac
}

check_archi

if [[ ! -f /home/brewpi/brewpi.py.brewmon-backup ]]; then
  echo "### Restore original BrewPi script"
  sudo /bin/cp /home/brewpi/brewpi.py.brewmon-backup /home/brewpi/brewpi.py
  sudo chown brewpi.brewpi /home/brewpi/brewpi.py
  sudo /bin/rm /home/brewpi/brewpi.py.brewmon-backup
fi

echo "### Uninstall InfluxDB"
sudo systemctl stop influxdb
sudo dpkg -r influxdb

echo "### Uninstall Grafana"
sudo /etc/init.d/grafana_server stop
sudo dpkg -r grafana

echo "### Uninstall BrewMon package"
sudo pip uninstall -y brewmon

echo "### You need to restart the BrewPi script"
