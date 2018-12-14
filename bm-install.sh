#!/bin/bash
# BrewMon installer for Raspberry Pi
#
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

install_docker() {
  if command_exists docker; then
    echo "### docker already installed"
  else
    echo "### install docker"
    curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
  fi
  if command_exists docker-compose; then
    echo "### docker-compose already installed"
  else
    echo "### install docker-compose"
    sudo apt-get -y install python-pip
    sudo pip install docker-compose
  fi
}

build_docker_images() {
  cd /etc/brewmon/raspbian
  echo "### building docker images, have a beer..."
  time sudo docker-compose build --no-cache
}

pull_docker_images() {
  cd /etc/brewmon/raspbian
  echo "### pull docker images, have a beer..."
  time sudo docker-compose pull
}

clone_source() {
  if ! command_exists git; then
    echo "### install git"
    sudo apt-get -y install git
  fi
  if [[ ! -f /etc/brewmon ]]; then
    sudo git clone --depth 1 -b legacy https://github.com/bdelbosc/brewpi-docker /etc/brewmon
  fi
}

install_service() {
  if [[ ! -e /etc/systemd/system/brewmon.service ]]; then
    sudo ln -s /etc/brewmon/systemd/system/brewmon.service /etc/systemd/system/brewmon.service
    sudo systemctl daemon-reload
  fi
}


echo "### This script will install the BrewMon stack on a RaspberryPI that is running BrewPi in legacy version"
check_archi
install_docker
clone_source
# build_docker_images
pull_docker_images
install_service
sudo systemctl start brewmon.service
sudo systemctl status brewmon.service
