#!/bin/bash
# "🔥🔥🐾🐾🐾🐾🐾🔥🔥"
# "🐺 GREY WOLF WRAPPER 🐺"

if [ $# -lt 2 ] || [[ "$1" != -* ]]; then
    echo "Usage: greyWolf -[hunt|fetch|howl] <target> [flags]"
    echo "Example: greyWolf -fetch onant.com -s -j -v"
    exit 1
fi

MODE="$1"
TARGET="$2"
shift 2

case "$MODE" in
    -hunt) ./grey-wolf-hunt.sh "$TARGET" "$@" ;;
    -fetch) ./grey-wolf-fetch.sh "$TARGET" "$@" ;;
    -howl) ./grey-wolf-howl.sh "$TARGET" "$@" ;;
    *) echo "Unknown mode: $MODE. Use -hunt, -fetch, or -howl."; exit 1 ;;
esac
