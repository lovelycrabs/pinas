#!/usr/bin/env bash

set -euo pipefail

cur_dir=$(dirname $0)

usage() {
    cat <<'EOF'
Usage:
  install.sh -b <rpi5|rock2a|rock5c|rock4d>
  install.sh --board <rpi5|rock2a|rock5c|rock4d>
  install.sh --board=<rpi5|rock2a|rock5c|rock4d>
EOF
}

board="rpi5"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--board)
            if [[ $# -lt 2 ]]; then
                echo "Error: $1 requires an argument" >&2
                usage >&2
                exit 2
            fi
            board="$2"
            shift 2
            ;;
        --board=*)
            board="${1#*=}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

case "$board" in
    rpi5)
        echo "Running rpi5 install"
        # Add rpi5-specific commands here, for example:
        bash  ${cur_dir}/scripts/install-rpi5.sh
        ;;
    rock2a)
        echo "Running rock2a install"
        bash "${cur_dir}/scripts/install-rock2a.sh"
        ;;
    rock5c)
        echo "Running rock5c install"
        # Add rock5c-specific commands here, for example:
        bash  ${cur_dir}/scripts/install-rock5c.sh
        ;;
    rock4d)
        echo "Running rock4d install"
        # Add rock4d-specific commands here, for example:
        bash  ${cur_dir}/scripts/install-rock4d.sh
        ;;
    *)
        echo "Error: unsupported board: $board" >&2
        echo "Available values: rpi5, rock2a, rock5c, rock4d" >&2
        exit 2
        ;;
esac
echo "Install dispay service for board: $board"

echo "Install script completed successfully for board: $board"
