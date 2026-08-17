#!/bin/bash
# /usr/local/bin/wireguard-automatic-switch.sh

source /etc/wireguard-automatic-switch/main.conf

LOCKFILE="/var/run/wireguard-automatic-switch.lock"

# Utils

is_interface_up() {
    ip link show "$1" 1>/dev/null 2>&1 && ip link show "$1" | grep -q "$1"
}

detect_environment() {
    if ping -c 1 -W 2 "$HOME_LAB_LOCAL" 1>/dev/null 2>&1; then
        echo "home"
    else
        echo "away"
    fi
}

use_environment() {
    use=$1
    dontuse=$2

    use_conf="/etc/wireguard/${use}.conf"
    dontuse_conf="/etc/wireguard/${dontuse}.conf"

    if is_interface_up "$use"; then
        echo "Interface "$use" already up – no action needed."
        exit 0
    fi
    echo "Bringing up $use, taking down $dontuse."
    if is_interface_up "$dontuse"; then
        wg-quick down "$dontuse"
    fi
    wg-quick up "$use_conf"
}


# Prevent concurrent runs

exec 200>"$LOCKFILE"
flock -n 200 || { echo "Another instance is running"; exit 1; }

# Detect current environment

ENV=$(detect_environment)

# Use correct interface

if [ "$ENV" == "home" ]; then
    use_environment "$DIRECT_IFACE" "$RELAY_IFACE"
else
    use_environment "$RELAY_IFACE" "$DIRECT_IFACE"
fi
