#!/usr/bin/env bash

# Start ML4W Welcome App
if [ ! -f $HOME/.cache/ml4w-welcome-autostart ]; then
    echo ":: Starting ML4W Welcome App ..."
    sleep 2
    flatpak run com.ml4w.welcome
else
    echo ":: Autostart of ML4W Welcome App disabled."
fi

## Ensure timezone is set to Asia/Karachi and NTP is enabled (idempotent)
# This requires privileged access. We try pkexec first (GUI), then sudo as a fallback.
if command -v timedatectl >/dev/null 2>&1; then
    current_tz=$(timedatectl show -p Timezone --value 2>/dev/null || echo "")
    if [ "${current_tz}" != "Asia/Karachi" ]; then
        echo ":: Setting timezone to Asia/Karachi ..."
        if command -v pkexec >/dev/null 2>&1; then
            pkexec timedatectl set-timezone "Asia/Karachi" || sudo timedatectl set-timezone "Asia/Karachi" || echo ":: Failed to set timezone (need root)."
        else
            sudo timedatectl set-timezone "Asia/Karachi" || echo ":: Failed to set timezone (need root)."
        fi
    else
        echo ":: Timezone already Asia/Karachi."
    fi

    # Enable NTP so the clock stays in sync
    ntp_state=$(timedatectl show -p NTPSynchronized --value 2>/dev/null || echo "no")
    if [ "${ntp_state}" != "yes" ]; then
        echo ":: Enabling NTP sync ..."
        if command -v pkexec >/dev/null 2>&1; then
            pkexec timedatectl set-ntp true || sudo timedatectl set-ntp true || echo ":: Failed to enable NTP (need root)."
        else
            sudo timedatectl set-ntp true || echo ":: Failed to enable NTP (need root)."
        fi
    else
        echo ":: NTP sync already enabled."
    fi
else
    echo ":: timedatectl not found; cannot manage timezone/time automatically."
fi
