#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
CYAN='\033[0;36m'

print() { echo -e "${NC}$1${NC}"; }
error() { echo -e "${NC}${RED}$1${NC}"; }

# Check for local config (useful for testing)
if [ -f "./open-ports-temp.conf" ]; then
    source "./open-ports-temp.conf"
elif [ -f "/etc/open-ports-temp.conf" ]; then
    source "/etc/open-ports-temp.conf"
else
    error "Configuration file not found!"
    exit 1
fi

TIME="${TIME:-300}"

if [ -z "$PORTS" ]; then
    error "No ports configured!"
    exit 1
fi

PORTS=$(print "$PORTS" | tr -d ' ')

IFS=',' read -ra PORT_LIST <<< "$PORTS"

for port in "${PORT_LIST[@]}"; do
    print "${GREEN}Opening${NC} $port."
    ufw allow "$port"
done

print "All ports are ${GREEN}open${NC}. Waiting for ${CYAN}$TIME${NC} seconds..."

sleep "$TIME"

for port in "${PORT_LIST[@]}"; do
    print "${RED}Closing${NC} $port."
    ufw delete allow "$port"
done

print "Ports are ${RED}closed."
