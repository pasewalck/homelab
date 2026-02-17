#!/bin/bash
set -e

sudo ufw allow http
sudo ufw allow https
sudo ufw reload
sudo ufw enable

sudo apt install nginx-full

NG_CONF="/etc/nginx/nginx.conf"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'

print() { echo -e "${NC}$1"; }

usage() {
    print "Usage: $0 --listen-port <listen-port> --listen-port-secure <listen-port-secure> --target-endpoint <target-endpoint> --target-endpoint-secure <target-endpoint-secure>"
    print "  --listen-port          Port to listen for incoming non-secure traffic"
    print "  --listen-port-secure      Port to listen for incoming secure traffic"
    print "  --target-endpoint      Target server address for non-secure communication"
    print "  --target-endpoint-secure  Target server address for secure communication"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --listen-port)
            LISTEN_PORT_HTTP="$2"
            shift 2
            ;;
        --listen-port-secure)
            LISTEN_PORT_HTTPS="$2"
            shift 2
            ;;
        --target-endpoint)
            TARGET_ENDPOINT_HTTP="$2"
            shift 2
            ;;
        --target-endpoint-secure)
            TARGET_ENDPOINT_HTTPS="$2"
            shift 2
            ;;
        *)
            print "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$TARGET_ENDPOINT_HTTP" ] || [ -z "$TARGET_ENDPOINT_HTTPS" ]; then
    print "${RED}Error: Missing required arguments!"
    usage
    exit 1
fi

if [ -z "$LISTEN_PORT_HTTP" ]; then
    LISTEN_PORT_HTTP="80"
fi
if [ -z "$LISTEN_PORT_HTTPS" ]; then
    LISTEN_PORT_HTTPS="443"
fi

NG_CONF="./nginx.conf"


BACKUP_BACKUP="${FILE}.bak"

cp "$NG_CONF" "$BACKUP_BACKUP"

awk '
/^[[:space:]]*http[[:space:]]*\{/ {
    in_http=1
}
{
    if (in_http) {
        print "#" $0
    } else {
        print
    }
}
in_http && /\{/ { brace_count++ }
in_http && /\}/ {
    brace_count--
    if (brace_count == 0) {
        in_http=0
    }
}
' "$BACKUP_BACKUP" > "$NG_CONF"

sudo tee -a "$NG_CONF" > /dev/null <<EOF

stream {
    upstream backend {
        server TARGET_ENDPOINT_HTTP;
    }
    server {
        listen $LISTEN_PORT;
        proxy_pass backend;
    }
    upstream backend_https {
        server $TARGET_ENDPOINT_HTTPS;
    }
    server {
        listen $LISTEN_PORT_HTTPS;
        proxy_pass backend_https;
    }
}
EOF

sudo systemctl reload nginx
