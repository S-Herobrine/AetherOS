#!/usr/bin/env python3
"""
AetherOS Universal Hub (7-in-1 OS Concept Realized)
Combines Windows 11, Android 14 + GMS, NavaOS Glass, FlowOS Hybrid,
macOS Smoothness, and Ubuntu Linux Core in one unified hub.
"""

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
    padding: 14px;
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
        return f"{used} MB / {total} MB RAM Active (zRAM Compressed Swap)"
    except Exception:
        return "FlowOS Low-Memory Engine Active"


class UniversalHubWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="AetherOS 1.0 — Universal 7-in-1 OS Hub")
        self.set_default_size(900, 620)

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        root.set_margin_top(16)
        root.set_margin_bottom(16)
        root.set_margin_start(18)
        root.set_margin_end(18)
        self.set_child(root)

        # Top Banner
        banner = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        banner.add_css_class("hub-banner")

        btxt = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        btxt.set_hexpand(True)
        t = Gtk.Label(xalign=0)
        t.set_markup("<span size='x-large' weight='bold'>✨ AetherOS 1.0 — One OS. Every Ecosystem.</span>")
        s = Gtk.Label(
            label="Windows 11 UX  •  Android 14 + GMS  •  NavaOS Glass  •  FlowOS Hybrid  •  macOS  •  Ubuntu Linux",
            xalign=0,
        )
        s.add_css_class("muted")
        self.ram_lbl = Gtk.Label(label=get_ram_summary(), xalign=0)
        btxt.append(t)
        btxt.append(s)
        btxt.append(self.ram_lbl)
        banner.append(btxt)

        cc_btn = Gtk.Button(label="🎛️ Control Center")
        cc_btn.add_css_class("action-btn")
        cc_btn.connect("clicked", lambda _b: subprocess.Popen(["python3", "/usr/local/bin/aether-control-center.py"]))
        banner.append(cc_btn)

        install_btn = Gtk.Button(label="🚀 Install OS")
        install_btn.add_css_class("action-btn")
        install_btn.connect("clicked", lambda _b: subprocess.Popen(["sudo", "-E", "calamares"]))
        banner.append(install_btn)
        root.append(banner)

        # Notebook Tabs for Full Feature Showoff
        notebook = Gtk.Notebook()
        notebook.set_vexpand(True)
        root.append(notebook)

        # Tab 1: 7-in-1 Ecosystem Launchers
        tab1 = self._build_grid([
            ("🪟 Windows 11 Layer", "Wine + DXVK runtime for .exe apps, games & Explorer tabs.", "Run .EXE App", ["bash", "/usr/local/bin/aether-windows-runner.sh"]),
            ("🤖 Android 14 + GMS", "Google Play Store, Play Services, MicroG & .apk sideloader.", "Open Play Store", ["python3", "/usr/local/bin/aether-playstore.py"]),
            ("🍎 macOS Runtime", "Darling Mach-O layer for .dmg & .app compatibility tools.", "Run .DMG App", ["bash", "/usr/local/bin/aether-macos-runner.sh"]),
            ("🐧 Ubuntu 24.04 Core", "APT, Flatpak, AppImage, Bash/Zsh & AetherOS File Explorer.", "Open Files", ["python3", "/usr/local/bin/satasos-files.py"]),
            ("✨ NavaOS Liquid Glass", "Frosted glass dock, centered Start Menu & floating widgets.", "Launch Widgets", ["python3", "/usr/local/bin/apexos-widgets.py"]),
            ("⚡ FlowOS Tweaks", "Custom taskbar, theme toggle, zRAM & 4-second boot tuning.", "Open Tweaks", ["python3", "/usr/local/bin/apexos-tweaks.py"]),
        ])
        notebook.append_page(tab1, Gtk.Label(label="🌐 7-in-1 Ecosystems"))

        # Tab 2: GMS & Google Suite
        tab2 = self._build_grid([
            ("🛍️ Google Play Store", "Browse & install Android 14 apps inside Waydroid container.", "Open Play Store", ["python3", "/usr/local/bin/aether-playstore.py"]),
            ("🌐 Chrome / Web Apps", "Launch Firefox / Web Engine for Gmail, Maps, Drive & YouTube.", "Open Browser", ["firefox", "https://www.youtube.com/@ZeroToBootOfficial"]),
            ("📦 Direct APK Installer", "Sideload any Android .apk package directly from disk.", "Sideload .APK", ["sh", "-c", "FILE=$(zenity --file-selection --file-filter='*.apk' 2>/dev/null) && waydroid app install \"$FILE\""]),
            ("🔐 GMS & MicroG Bridge", "Sign-in & Play Services container configuration.", "Init Waydroid GMS", ["gnome-terminal", "--", "bash", "-c", "echo 'Run: sudo waydroid init -s GAPPS'; read"]),
        ])
        notebook.append_page(tab2, Gtk.Label(label="📱 Android & GMS"))

        # Tab 3: Gaming & Developer
        tab3 = self._build_grid([
            ("🎮 Wine / Proton Gaming", "DirectX to Vulkan (DXVK) gaming & .exe runner.", "Launch Game / .EXE", ["bash", "/usr/local/bin/aether-windows-runner.sh"]),
            ("💻 PowerShell & Bash", "Modern developer terminal with Git, Python 3 & APT.", "Open Terminal", ["gnome-terminal"]),
            ("🎛️ Control Center", "Toggle Game Mode, Dev Mode, Wi-Fi & Adaptive UI.", "Open Control Center", ["python3", "/usr/local/bin/aether-control-center.py"]),
            ("⚙️ System Settings", "Display, Network, Themes, About AetherOS 1.0.", "Open Settings", ["python3", "/usr/local/bin/satasos-settings.py"]),
        ])
        notebook.append_page(tab3, Gtk.Label(label="🎮 Gaming & Dev"))

        GLib.timeout_add_seconds(3, self.refresh_ram)

    def _build_grid(self, items):
        grid = Gtk.Grid(row_spacing=12, column_spacing=12, column_homogeneous=True)
        grid.set_margin_top(12)
        grid.set_margin_bottom(8)
        grid.set_margin_start(4)
        grid.set_margin_end(4)
        for idx, (ctitle, cdesc, cbtn, cmd) in enumerate(items):
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
        return grid

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
