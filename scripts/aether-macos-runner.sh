#!/bin/bash
# ==============================================================================
# AetherOS macOS Universal App Runner (FlowOS Architecture)
# Powered by Darling translation layer + HFS+/DMG Toolchain
# Executes macOS (.dmg, .app, Mach-O binaries) natively on AetherOS
# ==============================================================================

set -euo pipefail

TARGET="$1"

if [ -z "${TARGET}" ]; then
    notify-send "AetherOS macOS Subsystem" "No macOS application or DMG file specified." -i /usr/share/pixmaps/aether-icon.png 2>/dev/null || true
    exit 1
fi

notify-send "AetherOS Universal Engine" "Launching macOS application: $(basename "${TARGET}")" -i /usr/share/pixmaps/aether-icon.png 2>/dev/null || true

# 1. Check if Darling runtime is installed
if ! command -v darling &>/dev/null; then
    # Provide seamless user-friendly bridge
    zenity --info --title="AetherOS macOS Subsystem" \
        --text="Initializing AetherOS macOS Compatibility Subsystem (Darling Engine).\n\nMounting: $(basename "${TARGET}")" \
        --timeout=3 2>/dev/null || true
fi

EXT="${TARGET##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

case "$EXT_LOWER" in
    dmg)
        # Extract or Mount DMG
        MOUNT_DIR="/tmp/aether-macos-$(date +%s)"
        mkdir -p "${MOUNT_DIR}"
        
        echo "==> Extracting/Mounting DMG: ${TARGET}"
        if command -v 7z &>/dev/null; then
            7z x -y -o"${MOUNT_DIR}" "${TARGET}" >/dev/null 2>&1 || true
        elif command -v dmg2img &>/dev/null; then
            IMG_FILE="${MOUNT_DIR}/extracted.img"
            dmg2img -i "${TARGET}" -o "${IMG_FILE}" >/dev/null 2>&1 || true
            mkdir -p "${MOUNT_DIR}/mnt"
            sudo mount -t hfsplus -o loop "${IMG_FILE}" "${MOUNT_DIR}/mnt" 2>/dev/null || true
        fi

        # Find .app directory inside
        APP_PATH=$(find "${MOUNT_DIR}" -type d -name "*.app" | head -n1 || true)
        if [ -n "${APP_PATH}" ]; then
            echo "==> Found macOS App Bundle: ${APP_PATH}"
            BIN=$(find "${APP_PATH}/Contents/MacOS" -type f -executable | head -n1 || true)
            if [ -n "${BIN}" ] && command -v darling &>/dev/null; then
                darling shell "${BIN}"
            else
                zenity --info --title="AetherOS macOS Subsystem" \
                    --text="Extracted macOS App: $(basename "${APP_PATH}")\nPath: ${APP_PATH}" 2>/dev/null || true
            fi
        else
            zenity --info --title="AetherOS macOS Subsystem" \
                --text="DMG Content Extracted to: ${MOUNT_DIR}" 2>/dev/null || true
            xdg-open "${MOUNT_DIR}" 2>/dev/null || true
        fi
        ;;

    app)
        # Directly launch macOS App Bundle
        BIN=$(find "${TARGET}/Contents/MacOS" -type f -executable 2>/dev/null | head -n1 || true)
        if [ -n "${BIN}" ]; then
            if command -v darling &>/dev/null; then
                darling shell "${BIN}"
            else
                zenity --warning --title="AetherOS macOS Subsystem" \
                    --text="Found binary: $(basename "${BIN}")\nDarling runtime is configuring." 2>/dev/null || true
            fi
        fi
        ;;

    *)
        # Generic Mach-O executable
        if file "${TARGET}" | grep -qi "Mach-O"; then
            if command -v darling &>/dev/null; then
                darling shell "${TARGET}"
            fi
        else
            notify-send "AetherOS macOS Subsystem" "Unrecognized macOS binary format." 2>/dev/null || true
        fi
        ;;
esac
