# GPU Hardware Acceleration Toggle

This QuickShell setup provides a safe GPU hardware acceleration toggle for your system with NVIDIA RTX 3070 Ti and AMD Radeon 680M.

## Features

✓ **QuickShell Widget** - Visual GPU toggle in the system bar  
✓ **Keyboard Shortcut** - Press `Super+G` to toggle (configurable)  
✓ **Persistent State** - Your preference is saved and restored on restart  
✓ **Safe Toggling** - No system crashes, fully reversible  
✓ **Shell Integration** - Automatic environment variable setup  

## Usage

### 1. **QuickShell Widget** (Easiest)
- Look at the system bar on the right side
- You'll see a small icon showing **⚡** (GPU enabled) or **C** (CPU rendering)
- Click to toggle between modes
- A tooltip shows the current status

### 2. **Keyboard Shortcut**
- Press `Super+G` to toggle GPU acceleration
- Status notification will appear

### 3. **Command Line**
Use the `gpu-toggle` utility:

```bash
# Enable GPU acceleration
gpu-toggle gpu

# Disable GPU acceleration (CPU software rendering)
gpu-toggle cpu

# Check current status
gpu-toggle status
# or just: gpu-toggle
```

## How It Works

- **GPU Mode (⚡)**: Hardware acceleration enabled
  - Better performance for most applications
  - Lower CPU usage
  - Better for gaming and heavy rendering
  
- **CPU Mode (C)**: Software rendering
  - More compatible with some applications
  - Useful for troubleshooting GPU issues
  - Lower power consumption on battery

## What Changes

When you toggle GPU mode, the system updates environment variables:

**GPU Enabled:**
```
QT_QPA_PLATFORM="wayland"
GBM_BACKEND="nvidia-drm"
LIBVA_DRIVER_NAME="nvidia"
__VK_LAYER_NV_optimus="NVIDIA_ONLY"
VDPAU_DRIVER="nvidia"
```

**CPU Rendering:**
```
QT_QPA_PLATFORM="offscreen"
(drivers unset)
```

## Important Notes

⚠️ **Changes Apply to New Applications**
- The toggle changes the GPU mode for applications launched *after* the toggle
- Already-running applications won't be affected
- Close and reopen applications to apply the changes

⚠️ **QuickShell Restart**
- After toggling, you may want to restart QuickShell to refresh the dashboard
- Command: `qs -r` or `killall quickshell && qs -c ii`

## Keyboard Shortcut Configuration

The default shortcut is `Super+G`. To change it, edit:
`~/.config/quickshell/ii/shell.qml`

Find the line:
```qml
GlobalShortcut {
    name: "gpuToggle"
```

And modify the key binding (see QuickShell documentation for key syntax).

## Troubleshooting

**Apps not responding to GPU toggle?**
- Close and reopen the applications
- Check current status with `gpu-toggle status`

**Visual glitches after toggle?**
- Restart the affected application
- Optionally restart QuickShell: `qs -r`

**Want to verify settings applied?**
- Check the state file: `cat ~/.config/gpu-state`
- Check environment: `echo $GBM_BACKEND`

## Files

- **Service**: `~/.config/quickshell/ii/services/GPU.qml`
- **Widget**: `~/.config/quickshell/ii/modules/common/GPUToggle.qml`
- **State File**: `~/.config/gpu-state`
- **Shell Script**: `~/.config/quickshell/ii/scripts/gpu-env.sh`
- **Toggle Utility**: `~/.config/quickshell/ii/scripts/gpu-toggle`
