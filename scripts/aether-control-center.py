#!/usr/bin/env python3
"""
AetherOS Universal Control Center & Quick Settings
Combines macOS Control Center, Android Quick Settings, NavaOS Liquid Glass,
and FlowOS Gaming / Developer / Privacy Modes.
"""

import subprocess
import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, Gio

CSS = b"""
window {
    background-color: rgba(14, 12, 28, 0.94);
    color: #ffffff;
    border-radius: 20px;
}
.cc-card {
    background-color: rgba(255, 255, 255, 0.06);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 16px;
    padding: 12px;
}
.cc-pill-active {
    background-color: #4F86F7;
    color: #ffffff;
    font-weight: 700;
    border-radius: 14px;
    padding: 10px;
}
.cc-pill {
    background-color: rgba(255, 255, 255, 0.08);
    color: #ffffff;
    border-radius: 14px;
    padding: 10px;
}
.muted {
    color: #a4a0b8;
}
"""


class ControlCenterWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="AetherOS Control Center")
        self.set_default_size(400, 560)
        self.set_resizable(False)

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        root.set_margin_top(16)
        root.set_margin_bottom(16)
        root.set_margin_start(16)
        root.set_margin_end(16)
        self.set_child(root)

        hdr = Gtk.Label(xalign=0)
        hdr.set_markup("<span size='large' weight='bold'>🎛️ AetherOS Control Center</span>")
        root.append(hdr)

        self.status = Gtk.Label(label="Mode: Desktop • Liquid Glass Active", xalign=0)
        self.status.add_css_class("muted")
        root.append(self.status)

        # Quick Connectivity Toggles (Android + macOS style)
        conn_grid = Gtk.Grid(row_spacing=10, column_spacing=10, column_homogeneous=True)
        toggles = [
            ("📶 Wi-Fi\nConnected", True, "Wi-Fi Connected (AetherOS-5G)"),
            ("🔵 Bluetooth\nReady", True, "Bluetooth Discoverable"),
            ("🎮 Game Mode\nDXVK Boost", False, "Game Mode Enabled (High Performance)"),
            ("🛠️ Dev Mode\nBash / Git", True, "Developer Tools Active"),
        ]
        for i, (label, active, msg) in enumerate(toggles):
            btn = Gtk.ToggleButton(label=label)
            btn.set_active(active)
            btn.add_css_class("cc-pill-active" if active else "cc-pill")
            btn.connect("toggled", self.on_toggle, msg)
            conn_grid.attach(btn, i % 2, i // 2, 1, 1)
        root.append(conn_grid)

        # Adaptive Interface Mode (Desktop / Tablet / Mobile)
        adapt_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        adapt_box.add_css_class("cc-card")
        albl = Gtk.Label(xalign=0)
        albl.set_markup("<b>📱 Adaptive Form Factor</b>")
        adapt_box.append(albl)
        mode_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8, homogeneous=True)
        for m in ("🖥️ Desktop", "📱 Tablet", "📲 Mobile"):
            b = Gtk.Button(label=m)
            b.add_css_class("cc-pill")
            b.connect("clicked", lambda _b, mode=m: self.status.set_text(f"Switched UI Profile → {mode}"))
            mode_row.append(b)
        adapt_box.append(mode_row)
        root.append(adapt_box)

        # Privacy & Security Dashboard
        priv_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        priv_box.add_css_class("cc-card")
        plbl = Gtk.Label(xalign=0)
        plbl.set_markup("<b>🛡️ Privacy & Security Dashboard</b>")
        pinfo = Gtk.Label(
            label="• App Sandboxing: Active (Waydroid LXC + Wine Prefix)\n"
                  "• Telemetry: 0% (Zero Cloud Tracking)\n"
                  "• Memory Engine: zRAM Compression Active",
            xalign=0,
            wrap=True,
        )
        pinfo.add_css_class("muted")
        priv_box.append(plbl)
        priv_box.append(pinfo)
        root.append(priv_box)

        # Quick System Actions
        act_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8, homogeneous=True)
        actions = [
            ("🔒 Lock", ["sh", "-c", "dm-tool lock || light-locker-command -l || true"]),
            ("⚙️ Settings", ["python3", "/usr/local/bin/satasos-settings.py"]),
            ("🔍 Search", ["sh", "-c", "rofi -show drun -theme /etc/xdg/rofi/aetheros-start.rasi -show-icons"]),
        ]
        for label, cmd in actions:
            b = Gtk.Button(label=label)
            b.add_css_class("cc-pill")
            b.connect("clicked", lambda _b, c=cmd: subprocess.Popen(c))
            act_row.append(b)
        root.append(act_row)

    def on_toggle(self, btn, msg):
        if btn.get_active():
            btn.remove_css_class("cc-pill")
            btn.add_css_class("cc-pill-active")
            self.status.set_text(msg)
        else:
            btn.remove_css_class("cc-pill-active")
            btn.add_css_class("cc-pill")
            self.status.set_text("Toggled Off")


class ControlCenterApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="org.aetheros.controlcenter", flags=Gio.ApplicationFlags.FLAGS_NONE)

    def do_activate(self):
        win = self.props.active_window or ControlCenterWindow(self)
        win.present()


if __name__ == "__main__":
    app = ControlCenterApp()
    app.run(None)
