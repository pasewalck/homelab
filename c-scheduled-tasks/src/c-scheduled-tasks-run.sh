#!/usr/bin/env bash

LOG_FILE="/var/log/c-scheduled-tasks.log"
EXIT_CODE=0
ACTIVE_DIR="/etc/c-scheduled-tasks/active"

if [ ! -d "$ACTIVE_DIR" ]; then
    exit 0
fi

while IFS= read -r -d '' file; do
    name=$(basename "$file")

    "$file" 2>&1 | awk -v n="$name" '{
        print strftime("[%Y-%m-%d %H:%M:%S]") "[" n "] " $0
    }' >>"$LOG_FILE"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "[$name] exited with error" >>"$LOG_FILE"
        EXIT_CODE=1
    fi
done < <(find -L "$ACTIVE_DIR" -mindepth 1 -maxdepth 1 -type f -executable -print0)

exit $EXIT_CODE
