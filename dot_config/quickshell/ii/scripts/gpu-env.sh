#!/bin/bash
# GPU acceleration environment setup
# Source this in your shell configuration to apply GPU settings

GPU_STATE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/gpu-state"

# Determine GPU mode
if [ -f "$GPU_STATE_FILE" ]; then
    GPU_MODE=$(cat "$GPU_STATE_FILE")
else
    GPU_MODE="gpu"
fi

if [ "$GPU_MODE" = "gpu" ]; then
    # Enable hardware acceleration
    export QT_QPA_PLATFORM="wayland"
    export QT_QPA_PLATFORMTHEME="kde"
    export GBM_BACKEND="nvidia-drm"
    export LIBVA_DRIVER_NAME="nvidia"
    export __VK_LAYER_NV_optimus="NVIDIA_ONLY"
    export VDPAU_DRIVER="nvidia"
else
    # Disable hardware acceleration (software rendering)
    export QT_QPA_PLATFORM="offscreen"
    unset GBM_BACKEND
    unset LIBVA_DRIVER_NAME
    unset __VK_LAYER_NV_optimus
    unset VDPAU_DRIVER
fi
