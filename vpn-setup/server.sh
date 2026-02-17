#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'

print() { echo -e "${NC}$1${NC}"; }

validate_ip() {
    local ip="$1"
    local valid_ip_pattern="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

    if [[ $ip =~ $valid_ip_pattern ]]; then
        IFS='.' read -r octet1 octet2 octet3 octet4 <<< "$ip"
        if (( octet1 <= 255 && octet2 <= 255 && octet3 <= 255 && octet4 <= 255 )); then
            return 0
        fi
    fi
    return 1
}

validate_mask() {
    local mask="$1"

    if [[ $mask =~ ^[0-9]{1,2}$ ]]; then
        local mask_value="$mask"
        if (( mask_value >= 0 && mask_value <= 32 )); then
            return 0
        fi
    fi
    return 1
}

ip_to_integer() {
    local ip="$1"
    local offset="$2"
    IFS='.' read -r octet1 octet2 octet3 octet4 <<< "$ip"

    # Using Workaround by kapa2512 from https://github.com/jeff-hykin/better-shell-syntax/issues/93
    # Instead of i=$(( 1 << 2 )) using i=$(( ((0) | 1 << 2) )) to avoid vs code formatting issues.

    local part1=$(( ((0) | a << 24) ))
    local part2=$(( ((0) | b << 16) ))
    local part3=$(( ((0) | c << 8) ))
    local part4=$(( ((0) | d << 0) ))

    local total_ip_num=$((part1+part2+part3+part4+offset))

    local reconstructed_ip=$(printf "%d.%d.%d.%d\n" \
        $((total_ip_num >> 24 & 255)) \
        $((total_ip_num >> 16 & 255)) \
        $((total_ip_num >> 8 & 255)) \
        $((total_ip_num & 255)))

    echo "$reconstructed_ip"
}

read -p "Enter WireGuard interface (default: wg0): " WG_INTERFACE
WG_INTERFACE=${WG_INTERFACE:-wg0}

while true; do
    read -p "Enter your server IP: " SERVER_IP
    if [[ -z "$SERVER_IP" ]]; then
        print "${RED}Error: Server IP cannot be empty. Please provide a valid IP."
    elif ! validate_ip "$SERVER_IP"; then
        print "${RED}Error: Invalid IP address format."
    else
        break
    fi
done

read -p "Enter the server port (default: 51820): " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-51820}

SERVER_ENDPOINT="$SERVER_IP:$SERVER_PORT"

print "${NC}Choose your IP range for ALLOWED_IPS:"
print "${NC}1. 10.200.200.0/24 (default)"
print "${NC}2. 10.0.0.0/24"
print "${NC}3. Custom (enter your own)"

read -p "Select an option [1-4]: " IP_RANGE_OPTION

case $IP_RANGE_OPTION in
  1)
    IP_RANGE="10.200.200.0"
    SUBNET_MASK="24"
    ;;
  2)
    IP_RANGE="10.0.0.0"
    SUBNET_MASK="24"
    ;;
  3)
    while true; do
        read -p "Enter the custom IP range (e.g., 10.0.0.0): " CUSTOM_IP
        if [[ -z "$CUSTOM_IP" ]]; then
            print "${RED}Error: IP range cannot be empty."
        elif ! validate_ip "$CUSTOM_IP"; then
            print "${RED}Error: Invalid IP address format."
        else
            break
        fi
    done

    while true; do
        read -p "Enter the subnet mask (e.g., 24, 16): " CUSTOM_MASK
        if [[ -z "$CUSTOM_MASK" ]]; then
            print "${RED}Error: Subnet mask cannot be empty."
        elif ! validate_mask "$CUSTOM_MASK"; then
            print "${RED}Error: Invalid subnet mask format."
        else
            break
        fi
    done

    ;;
  *)
    print "${YELLOW}Invalid option. Defaulting to 10.200.200.0/24"
    IP_RANGE="10.200.200.0"
    SUBNET_MASK="24"
    ;;
esac

ALLOWED_IPS="$IP_RANGE/$SUBNET_MASK"

print "${NC}Using network: $ALLOWED_IPS"

SYSCTL_CONF="/etc/sysctl.conf"
WG_CONF="/etc/wireguard/${WG_INTERFACE}.conf"

sudo apt update && sudo apt install -y wireguard ufw

sudo ufw allow $SERVER_PORT/udp
sudo ufw reload
sudo ufw enable

sudo sysctl -w net.ipv4.ip_forward=1
if grep -q "^net.ipv4.ip_forward" $SYSCTL_CONF; then
    sudo sed -i "s/^net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/" $SYSCTL_CONF
else
    echo "net.ipv4.ip_forward=1" | sudo tee -a $SYSCTL_CONF
fi

sudo sysctl -p

SERVER_PRIV=$(wg genkey)
SERVER_PUB=$(echo "$SERVER_PRIV" | wg pubkey)
PSK=$(wg genpsk)


sudo cat > "$WG_CONF" <<EOF
[Interface]
Address = $(increment_ip $IP_RANGE 1)/24
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_PRIV
EOF

counter=0
declare -A CLIENT_IPS

while true; do
    read -p "Add a client? (y/n): " add_client
    if [[ "$add_client" == "y" ]]; then
        client_priv=$(wg genkey)
        client_pub=$(echo "$client_priv" | wg pubkey)

        client_ip_addr="$(increment_ip $IP_RANGE $counter+2)/32"

        sudo tee -a "$WG_CONF" > /dev/null <<EOF
[Peer]
PublicKey = $client_pub
AllowedIPs = $client_ip_addr
PersistentKeepalive = 25
PresharedKey = $PSK
EOF

        CLIENT_IPS[$counter]="$client_ip_addr"

        print "${YELLOW}Important. Setup your client!"
        print "${NC}curl -fsSL https://github.com/pasewalck/homelab-guide/blob/main/vpn-setup/client.js -o ./client.sh && sudo bash ./client.sh --client-priv $client_priv --psk $PSK --client-ip $client_ip_addr --server-endpoint $SERVER_IP --server-pub $SERVER_PUB --allowed-ips $ALLOWED_IPS --wg-interface $WG_INTERFACE"
        print "${NC}"

        ((counter++))

    elif [[ "$add_client" == "n" ]]; then
        break
    fi
done

sudo chown root:root "$WG_CONF"
sudo chmod 600 "$WG_CONF"

sudo wg-quick up $WG_INTERFACE


while true; do
    read -p "Setup NGINX to forward all the traffic to one of the clients? (y/n): " nginx_setup
    if [[ "$nginx_setup" == "y" ]]; then

        while true; do
            print "${NC}Available Clients:"
            for client_id in "${!CLIENT_IPS[@]}"; do
                print "${NC}$client_id. ${CLIENT_IPS[$client_id]}"
            done

            read -p "Select client ID to forward traffic to: " CLIENT_ID

            if [[ -z "${CLIENT_IPS[$CLIENT_ID]}" ]]; then
                print "${RED}Error: Invalid client ID selected."
            else
                continue
            fi
        done

        client_ip="${CLIENT_IPS[$CLIENT_ID]}"

        curl -fsSL https://github.com/pasewalck/homelab-guide/blob/main/vpn-setup/nginx-stream.js -o ./nginx-stream.sh
        sudo bash ./nginx-stream.sh --target-endpoint "$client_ip:80" --target-endpoint-secure "$client_ip:443"
    elif [[ "$add_client" == "n" ]]; then
        break
    fi
done
