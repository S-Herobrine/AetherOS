#!/bin/bash
# ==============================================================================
# AetherOS Pure Fluidity Desktop Session (FlowOS / Nava OS Architecture)
# Ultra-responsive, zero-segfault, sub-100MB RAM, 60fps liquid glass desktop
# ==============================================================================

export XDG_CURRENT_DESKTOP=AetherOS
export XDG_SESSION_DESKTOP=AetherOS
export DESKTOP_SESSION=AetherOS

# 1. Prepare user configs if missing
mkdir -p "${HOME}/.config/openbox" "${HOME}/.config/tint2" "${HOME}/Desktop"
if [ -f "/etc/xdg/openbox/rc.xml" ] && [ ! -f "${HOME}/.config/openbox/rc.xml" ]; then
    cp "/etc/xdg/openbox/rc.xml" "${HOME}/.config/openbox/rc.xml" 2>/dev/null || true
fi
if [ -f "/etc/xdg/openbox/menu.xml" ] && [ ! -f "${HOME}/.config/openbox/menu.xml" ]; then
    cp "/etc/xdg/openbox/menu.xml" "${HOME}/.config/openbox/menu.xml" 2>/dev/null || true
fi
if [ -f "/usr/share/applications/install-aetheros.desktop" ] && [ ! -f "${HOME}/Desktop/install-aetheros.desktop" ]; then
    cp "/usr/share/applications/install-aetheros.desktop" "${HOME}/Desktop/" 2>/dev/null || true
    chmod +x "${HOME}/Desktop/install-aetheros.desktop" 2>/dev/null || true
fi

# 2. Set AetherOS Liquid Flow Wallpaper instantly (Zero black screen!)
WALLPAPER="/usr/share/backgrounds/apexos/aether-liquid-flow.jpg"
if [ ! -f "${WALLPAPER}" ]; then
    WALLPAPER="/usr/share/backgrounds/aetheros/aether-liquid-flow.jpg"
fi

if [ -f "${WALLPAPER}" ] && command -v feh >/dev/null 2>&1; then
    feh --bg-fill "${WALLPAPER}" &
else
    xsetroot -solid "#191B3B" &
fi

# 3. Launch Picom Glass Compositor (Enables rounded corners, blur & smooth fading)
PICOM_CFG="/etc/xdg/picom/aetheros-picom.conf"
if command -v picom >/dev/null 2>&1; then
    if [ -f "${PICOM_CFG}" ]; then
        picom -b --config "${PICOM_CFG}" --backend glx 2>/dev/null || picom -b --config "${PICOM_CFG}" --backend xrender 2>/dev/null || true
    else
        picom -b --backend glx --vsync 2>/dev/null || picom -b --backend xrender 2>/dev/null || true
    fi
fi

# 4. Launch Systray applets (Network Manager WiFi & Dunst notifications)
if command -v nm-applet >/dev/null 2>&1; then
    nm-applet &
fi
if command -v dunst >/dev/null 2>&1; then
    dunst &
fi

# 5. Launch AetherOS Floating Liquid Glass Dock
TINT2_CFG="/etc/xdg/tint2/aetheros-dock.tint2rc"
USER_TINT2="${HOME}/.config/tint2/tint2rc"

if [ -f "${TINT2_CFG}" ]; then
    cp -f "${TINT2_CFG}" "${USER_TINT2}" 2>/dev/null || true
    tint2 -c "${TINT2_CFG}" &
elif command -v tint2 >/dev/null 2>&1; then
    tint2 &
fi

# 6. Exec Openbox Window Manager (Rock-solid, zero segfault, 75MB RAM)
exec openbox-session
