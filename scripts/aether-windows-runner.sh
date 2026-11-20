#!/bin/bash
# ==============================================================================
# AetherOS Windows Universal App Runner (Wine 9.0 + DXVK / Proton Engine)
# Seamlessly executes Windows (.exe, .msi) applications natively on AetherOS
# ==============================================================================

set -euo pipefail

TARGET="$1"

if [ -z "${TARGET}" ]; then
    notify-send "AetherOS Windows Subsystem" "No Windows executable specified." -i /usr/share/pixmaps/aether-icon.png 2>/dev/null || true
    exit 1
fi

notify-send "AetherOS Universal Engine" "Launching Windows application: $(basename "${TARGET}")" -i /usr/share/pixmaps/aether-icon.png 2>/dev/null || true

export WINEARCH=win64
export WINEDEBUG=-all
export WINEPREFIX="${HOME}/.wine"

# Execute via wine
if command -v wine64 &>/dev/null; then
    wine64 "${TARGET}"
elif command -v wine &>/dev/null; then
    wine "${TARGET}"
else
    zenity --error --title="AetherOS Windows Subsystem" \
        --text="Wine engine is not available. Install wine via: sudo apt install wine" 2>/dev/null || true
fi
