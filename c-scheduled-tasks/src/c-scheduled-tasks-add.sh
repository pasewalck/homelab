#!/usr/bin/env bash

COPY_MODE="ask"

usage() {
    echo "Usage: $0 [--copy|--no-copy] <path-to-script>"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --copy)
            COPY_MODE="yes"
            shift
            ;;
        --no-copy)
            COPY_MODE="no"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Error: Unknown option '$1'"
            usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

SOURCE_FILE="$1"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'

ACTIVE_DIR="/etc/c-scheduled-tasks/active"
AVAILABLE_DIR="/etc/c-scheduled-tasks/available"

print() { echo -e "${NC}$1"; }

if [ -z "$SOURCE_FILE" ]; then
    print "${RED}Error: Missing required arguments!"
    usage
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    print "${RED}Error: File '$SOURCE_FILE' not found!"
    exit 1
fi

if [ ! -d "$ACTIVE_DIR" ]; then
    print "${YELLOW}Creating directory: $ACTIVE_DIR"
    mkdir -p "$ACTIVE_DIR"
fi

if [ ! -d "$AVAILABLE_DIR" ]; then
    print "${YELLOW}Creating directory: $AVAILABLE_DIR"
    mkdir -p "$AVAILABLE_DIR"
fi

SCRIPT_NAME=$(basename "$SOURCE_FILE")
TARGET_FILE="$SOURCE_FILE"

if [ "$COPY_MODE" = "ask" ]; then
    if [ -t 0 ]; then
        print "Move '$SCRIPT_NAME' to $AVAILABLE_DIR? [y/N]"
        read -r MOVE_TO_AVAILABLE

        case "$MOVE_TO_AVAILABLE" in
            y|Y|yes|YES)
                COPY_MODE="yes"
                ;;
            *)
                COPY_MODE="no"
                ;;
        esac
    else
        COPY_MODE="no"
    fi
fi

if [ "$COPY_MODE" = "yes" ]; then
    TARGET_FILE="$AVAILABLE_DIR/$SCRIPT_NAME"

    if [ "$SOURCE_FILE" != "$TARGET_FILE" ]; then
        if [ -e "$TARGET_FILE" ]; then
            print "${RED}Error: Target '$TARGET_FILE' already exists!"
            exit 1
        fi

        cp "$SOURCE_FILE" "$TARGET_FILE"
    fi
fi

chmod +x "$TARGET_FILE" && ln -sfn "$TARGET_FILE" "$ACTIVE_DIR/$SCRIPT_NAME"

print "Activated $SCRIPT_NAME"
