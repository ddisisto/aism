#!/bin/sh
# Agent with named pipe for communication

PIPE=/tmp/agent-pipe

# Create named pipe if it doesn't exist
if [ ! -p "$PIPE" ]; then
    mkfifo "$PIPE"
fi

cleanup() {
    echo "Agent shutting down..."
    rm -f "$PIPE"
    exit 0
}

trap cleanup SIGTERM SIGINT

echo "Agent started, listening on $PIPE"

while true; do
    if read -r line < "$PIPE"; then
        echo "Received: $line"
        case "$line" in
            "state:"*)
                echo "Transitioning to: ${line#state:}"
                ;;
            "task:"*)
                echo "Executing: ${line#task:}"
                ;;
            "shutdown")
                cleanup
                ;;
            *)
                echo "Unknown: $line"
                ;;
        esac
    fi
done