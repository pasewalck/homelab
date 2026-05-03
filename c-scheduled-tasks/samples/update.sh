#!/bin/bash
# Credit for idea and parts of code: https://jermsmit.com/automating-linux-updates-and-weekly-reboots/

apt-get update
apt-get -y dist-upgrade
apt-get clean
apt-get autoclean
apt autoremove -y --purge