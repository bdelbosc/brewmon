#!/bin/bash
set -x
echo "### This script will uninstall the BrewMon stack"

sudo /etc/init.d/grafana_server stop
sudo dpkg -r grafana
sudo pip uninstall -y brewmon
