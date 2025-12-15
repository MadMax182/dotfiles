#!/bin/bash

MODE=$1
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
LAPTOP_CONF="$USER_HOME/.config/hypr/config/laptop.conf"

if [[ -z "$MODE" ]]; then
    echo "Usage: gpu-mode <integrated|hybrid|nvidia>"
    echo "Current mode: $(envycontrol -q)"
    exit 1
fi

if [[ "$MODE" == "integrated" ]]; then
    sed -i 's|environment/nvidia.conf|environment/amd.conf|' "$LAPTOP_CONF"
    sudo envycontrol -s integrated
    echo "Switched to integrated mode. Please reboot."
elif [[ "$MODE" == "hybrid" ]]; then
    sed -i 's|environment/amd.conf|environment/nvidia.conf|' "$LAPTOP_CONF"
    sudo envycontrol -s hybrid
    echo "Switched to hybrid mode. Please reboot."
elif [[ "$MODE" == "nvidia" ]]; then
    sed -i 's|environment/amd.conf|environment/nvidia.conf|' "$LAPTOP_CONF"
    sudo envycontrol -s nvidia
    echo "Switched to nvidia mode. Please reboot."
else
    echo "Unknown mode: $MODE"
    echo "Valid modes: integrated, hybrid, nvidia"
    exit 1
fi
