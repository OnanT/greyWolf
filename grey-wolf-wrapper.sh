#!/bin/bash
# "🔥🔥🐾🐾🐾🐾🐾🐾🐾🐾🔥🔥"
# "🐺 GREY WOLF WRAPPER 🐺"

while [[ $# -gt 0 ]]; do
    case $1 in
        -hunt)
            shift
            TARGET="$1"
            shift
            source /app/grey-wolf-hunt.sh "$TARGET" "$@"
            exit 0
            ;;
        -wolf-pack-attack)
            shift
            TARGET="$1"
            shift
            source /app/wolf-pack-attack.sh "$TARGET" "$@"
            exit 0
            ;;
        -fetch)
            shift
            TARGET="$1"
            shift
            source /app/grey-wolf-fetch.sh "$TARGET" "$@"
            exit 0
            ;;
        -howl)
            echo "Mode $1 not fully implemented yet"
            exit 0
            ;;
        *)
            echo "Usage: greyWolf -[hunt|wolf-pack-attack|fetch|howl] <target> [flags]"
            exit 1
            ;;
    esac
done
