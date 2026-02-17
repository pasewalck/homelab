#!/bin/bash
set -e

sudo apt install wireguard

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'

print() { echo -e "${NC}$1"; }

usage() {
    print "Usage: $0 --client-priv <path-to-client-priv-key> --psk <psk> --server-pub <path-to-server-pub-key> --client-ip <client-ip> --server-endpoint <server-ip> --allowed-ips <allowed-ips> --wg-interface <wg-interface-name>"
    print "  --client-priv          Path to the client private key"
    print "  --psk                  Pre-shared key for authentication"
    print "  --server-pub           Path to the server public key"
    print "  --client-ip            The IP address of the client"
    print "  --server-endpoint      The IP address of the server"
    print "  --allowed-ips          Allowed IP addresses"
    print "  --wg-interface         The name of the WireGuard network interface"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --client-priv)
            CLIENT_PRIV="$2"
            shift 2
            ;;
        --psk)
            PSK="$2"
            shift 2
            ;;
        --server-pub)
            SERVER_PUB="$2"
            shift 2
            ;;
        --client-ip)
            CLIENT_IP="$2"
            shift 2
            ;;
        --server-endpoint)
            SERVER_ENDPOINT="$2"
            shift 2
            ;;
        --allowed-ips)
            ALLOWED_IPS="$2"
            shift 2
            ;;
        --wg-interface)
            WG_INTERFACE="$2"
            shift 2
            ;;
        *)
            print "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$CLIENT_PRIV" ] || [ -z "$PSK" ] || [ -z "$SERVER_PUB" ] || [ -z "$CLIENT_IP" ] || [ -z "$SERVER_ENDPOINT" ] || [ -z "$ALLOWED_IPS" ] || [ -z "$WG_INTERFACE" ]; then
    print "${RED}Error: Missing required arguments!"
    usage
    exit 1
fi

CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)

WG_CONF="/etc/wireguard/${WG_INTERFACE}.conf"

sudo cat > "$WG_CONF" <<EOF
[Interface]
Address = $CLIENT_IP
PrivateKey = $CLIENT_PRV

[Peer]
PublicKey = $SERVER_PUB
Endpoint = $SERVER_ENDPOINT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
PresharedKey = $PSK
EOF

sudo chown root:root "$WG_CONF"
sudo chmod 600 "$WG_CONF"
sudo wg-quick up $WG_INTERFACE