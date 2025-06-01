#!/bin/sh
# Test agent script that handles signals properly

cleanup() {
    echo "Agent shutting down gracefully..."
    exit 0
}

trap cleanup SIGTERM SIGINT

echo "Agent started, waiting for commands..."

while true; do
    if read -r line; then
        echo "Processing: $line"
        # Simulate agent processing
        case "$line" in
            "state:"*)
                echo "State transition: ${line#state:}"
                ;;
            "task:"*)
                echo "Executing task: ${line#task:}"
                ;;
            "shutdown")
                cleanup
                ;;
            *)
                echo "Unknown command: $line"
                ;;
        esac
    fi
done