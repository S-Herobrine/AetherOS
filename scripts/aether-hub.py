#!/usr/bin/env python3
"""
AetherOS Universal Hub (6-in-1 Control Center)
Unifies Windows (.exe), Android 14 (.apk), macOS (.dmg), Linux (.deb),
NavaOS Liquid Glass Aesthetics, and FlowOS Performance Engine.
"""

import os
import subprocess
import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, Gio, GLib

CSS = b"""
window {
    background-color: #0b0a18;
    color: #ffffff;
}
.hub-banner {
    background: linear-gradient(135deg, rgba(79, 134, 247, 0.25), rgba(124, 58, 237, 0.25));
    border: 1px solid rgba(255, 255, 255, 0.14);
    border-radius: 20px;
    padding: 18px;
}
.hub-card {
    background-color: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 16px;
    padding: 16px;
}
.hub-card:hover {
    background-color: rgba(79, 134, 247, 0.14);
    border-color: rgba(79, 134, 247, 0.50);
}
.action-btn {
    background-color: #4F86F7;
    color: #ffffff;
    font-weight: 700;
    border-radius: 999px;
    padding: 7px 14px;
}
.muted {
    color: #a4a0b8;
}
"""


def get_ram_summary():
    try:
        mem = {}
        with open("/proc/meminfo", "r") as f:
            for line in f:
                k, v = line.split(":", 1)
                mem[k.strip()] = int(v.strip().split()[0])
        total = mem.get("MemTotal", 1) // 1024
        avail = mem.get("MemAvailable", 1) // 1024
        used = max(0, total - avail)
        return f"{used} MB / {total} MB RAM Active (zRAM Enabled)"
    except Exception:
        return "FlowOS Low-Memory Engine Active"


class UniversalHubWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="AetherOS Universal Hub")
        self.set_default_size(840, 560)

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        root.set_margin_top(16)
        root.set_margin_bottom(16)
        root.set_margin_start(18)
        root.set_margin_end(18)
        self.set_child(root)

        # Header Banner
        banner = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        banner.add_css_class("hub-banner")

        btxt = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        btxt.set_hexpand(True)
        t = Gtk.Label(xalign=0)
        t.set_markup("<span size='x-large' weight='bold'>✨ AetherOS 1.0 — Universal 6-in-1 Hub</span>")
        s = Gtk.Label(label="Windows 11 UX  •  Android 14 Play Store  •  macOS Runner  •  Ubuntu Linux  •  NavaOS Glass  •  FlowOS Speed", xalign=0)
        s.add_css_class("muted")
        self.ram_lbl = Gtk.Label(label=get_ram_summary(), xalign=0)
        btxt.append(t)
        btxt.append(s)
        btxt.append(self.ram_lbl)
        banner.append(btxt)

        install_btn = Gtk.Button(label="🚀 Install AetherOS")
        install_btn.add_css_class("action-btn")
        install_btn.connect("clicked", lambda _b: subprocess.Popen(["sudo", "-E", "calamares"]))
        banner.append(install_btn)
        root.append(banner)

        # 6-in-1 Cards Grid
        grid = Gtk.Grid(row_spacing=12, column_spacing=12, column_homogeneous=True, row_homogeneous=True)
        grid.set_vexpand(True)

        cards = [
            ("🪟 Windows Apps (.exe)", "Run Windows software & games via Wine + DXVK.", "Open .EXE Runner", ["bash", "/usr/local/bin/aether-windows-runner.sh"]),
            ("🤖 Google Play & Android 14", "Launch Android 14 apps, Play Store & .APK files.", "Open Play Store", ["python3", "/usr/local/bin/aether-playstore.py"]),
            ("🍎 macOS Runner (.dmg)", "Run macOS .dmg / .app packages via Darling layer.", "Open .DMG Runner", ["bash", "/usr/local/bin/aether-macos-runner.sh"]),
            ("🐧 Linux Core & Files", "Ubuntu 24.04 LTS + AetherOS File Explorer.", "Open AetherOS Files", ["python3", "/usr/local/bin/satasos-files.py"]),
            ("✨ NavaOS Liquid Widgets", "Live floating CPU, RAM, Clock & Note widgets.", "Launch Widgets", ["python3", "/usr/local/bin/apexos-widgets.py"]),
            ("⚡ FlowOS Tweaks & Settings", "Customize glass theme, dock, fonts & performance.", "Open Settings", ["python3", "/usr/local/bin/satasos-settings.py"]),
        ]

        for idx, (ctitle, cdesc, cbtn, cmd) in enumerate(cards):
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            box.add_css_class("hub-card")
            lbl_t = Gtk.Label(xalign=0)
            lbl_t.set_markup(f"<span size='large' weight='bold'>{ctitle}</span>")
            lbl_d = Gtk.Label(label=cdesc, xalign=0, wrap=True)
            lbl_d.add_css_class("muted")
            lbl_d.set_vexpand(True)
            btn = Gtk.Button(label=cbtn)
            btn.add_css_class("action-btn")
            btn.connect("clicked", lambda _b, command=cmd: subprocess.Popen(command))
            box.append(lbl_t)
            box.append(lbl_d)
            box.append(btn)
            grid.attach(box, idx % 3, idx // 3, 1, 1)

        root.append(grid)
        GLib.timeout_add_seconds(3, self.refresh_ram)

    def refresh_ram(self):
        self.ram_lbl.set_text(get_ram_summary())
        return True


class UniversalHubApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="org.aetheros.hub", flags=Gio.ApplicationFlags.FLAGS_NONE)

    def do_activate(self):
        win = self.props.active_window or UniversalHubWindow(self)
        win.present()


if __name__ == "__main__":
    app = UniversalHubApp()
    app.run(None)
