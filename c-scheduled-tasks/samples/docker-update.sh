#!/bin/bash
# Please install jq to make this script work! Run "sudo apt install jq"

SERVICES=/some/path/services/

find "$SERVICES" -name "docker-compose.yaml" -o -name "docker-compose.yml" 2>/dev/null | while read file; do
        dir=$(dirname "$file")
        cd "$dir" || continue

        if docker compose ps --status running --format json 2>/dev/null | jq -e 'length > 0' > /dev/null 2>&1; then
                output=$(docker compose pull 2>&1)
                if echo "$output" | grep -q "Downloaded newer image"; then
                        echo "New image(s) pulled for $dir"
                        docker compose up -d --remove-orphans
                else
                        echo "$dir is up to date!"
                fi
        fi
done

docker image prune -a -f