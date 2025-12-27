#!/bin/bash
# Get NVIDIA GPU temperature using nvidia-smi

if ! command -v nvidia-smi &> /dev/null; then
    echo "N/A"
    exit 1
fi

temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null)

if [ -z "$temp" ]; then
    echo "N/A"
    exit 1
fi

echo "${temp}°C"
