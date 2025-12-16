#!/bin/bash
# Wrapper script for hyprlock with NVIDIA workaround
# Disables screencopy to fix black screen on NVIDIA GPUs

HYPRLOCK_NO_SCREENCOPY=1 hyprlock
