#!/bin/bash
# Check GPU power status

echo "=== GPU Power Status ==="
echo ""

echo "NVIDIA Runtime Status:"
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status 2>/dev/null || echo "  Not available"
echo ""

echo "NVIDIA Power Control:"
cat /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null || echo "  Not available"
echo ""

echo "NVIDIA D3cold Allowed:"
cat /sys/bus/pci/devices/0000:01:00.0/d3cold_allowed 2>/dev/null || echo "  Not available"
echo ""

echo "NVIDIA Driver Power Info:"
cat /proc/driver/nvidia/gpus/0000:01:00.0/power 2>/dev/null || echo "  Not available"
echo ""

echo "nvidia-powerd Status:"
systemctl is-active nvidia-powerd 2>/dev/null || echo "  Not running"
echo ""

echo "AMD iGPU Runtime Status:"
cat /sys/bus/pci/devices/0000:06:00.0/power/runtime_status 2>/dev/null || echo "  Not available"
echo ""

echo "Current Power Draw (if available):"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=power.draw --format=csv,noheader 2>/dev/null || echo "  nvidia-smi not available"
fi
