#!/usr/bin/env bash
#
# AruviOS RV32 — Manual Command Sender
#
# Send commands to a running AruviOS instance via named pipe.
#
# Usage: ./send_command.sh <pipe_path> <command>
# Example: ./send_command.sh /tmp/aruvios_serial_12345 help
#

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <pipe_path> <command>"
    echo "Example: $0 /tmp/aruvios_serial_12345 help"
    exit 1
fi

PIPE="$1"
COMMAND="$2"

if [[ ! -p "$PIPE" ]]; then
    echo "ERROR: Pipe $PIPE does not exist or is not a named pipe"
    echo "Make sure AruviOS is running with ./start.sh"
    exit 1
fi

echo "Sending command: $COMMAND"
echo "$COMMAND" > "$PIPE"