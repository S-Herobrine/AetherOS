#!/usr/bin/env python3
"""
AetherOS Play Store & Android 14 Subsystem Hub
Browse, sideload (.apk), and manage Android 14 apps powered by Waydroid.
"""

import os
import subprocess
import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, Gio, GLib

CSS = b"""
window {
    background-color: #0e0c1e;
    color: #ffffff;
}
.store-header {
    background: linear-gradient(135deg, rgba(61, 220, 132, 0.16), rgba(79, 134, 247, 0.16));
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 18px;
    padding: 18px;
}
.app-card {
    background-color: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.10);
    border-radius: 16px;
    padding: 14px;
}
.app-card:hover {
    background-color: rgba(79, 134, 247, 0.14);
    border-color: rgba(79, 134, 247, 0.45);
}
.install-btn {
    background-color: #3DDC84;
    color: #09130d;
    font-weight: 700;
    border-radius: 999px;
    padding: 6px 14px;
}
.sideload-btn {
    background-color: #4F86F7;
    color: #ffffff;
    font-weight: 700;
    border-radius: 999px;
    padding: 8px 16px;
}
.muted {
    color: #a4a0b8;
}
"""

FEATURED_APPS = [
    ("YouTube", "Video & Streaming • Android 14", "com.google.android.youtube", "🎬"),
    ("WhatsApp Messenger", "Messaging • Waydroid LXC", "com.whatsapp", "💬"),
    ("TikTok", "Short Video • 60 FPS GPU", "com.zhiliaoapp.musically", "🎵"),
    ("Instagram", "Social • Native Touch/Mouse", "com.instagram.android", "📸"),
    ("Spotify", "Music & Podcasts", "com.spotify.music", "🎧"),
    ("Subway Surfers", "Arcade Game • Hardware Accel", "com.kiloo.subwaysurf", "🎮"),
]


class PlayStoreWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="AetherOS Play Store (Android 14)")
        self.set_default_size(820, 560)

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

        # Top Hero Banner
        hero = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        hero.add_css_class("store-header")

        hero_text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        hero_text.set_hexpand(True)
        title = Gtk.Label(label="Google Play & Android 14 Subsystem", xalign=0)
        title.set_markup("<span size='x-large' weight='bold'>🤖 AetherOS Play Store</span>")
        sub = Gtk.Label(label="Powered by Waydroid LXC • MicroG & Play Services Ready • Direct APK Sideloading", xalign=0)
        sub.add_css_class("muted")
        hero_text.append(title)
        hero_text.append(sub)
        hero.append(hero_text)

        sideload_btn = Gtk.Button(label="📦 Sideload .APK")
        sideload_btn.add_css_class("sideload-btn")
        sideload_btn.connect("clicked", self.on_sideload)
        hero.append(sideload_btn)

        init_btn = Gtk.Button(label="⚡ Start Android 14")
        init_btn.add_css_class("install-btn")
        init_btn.connect("clicked", self.on_start_waydroid)
        hero.append(init_btn)

        root.append(hero)

        # Status Bar
        self.status_label = Gtk.Label(label="Status: Android 14 Subsystem Ready (Click an app or Sideload .APK)", xalign=0)
        self.status_label.add_css_class("muted")
        root.append(self.status_label)

        # Search Bar
        search = Gtk.SearchEntry(placeholder_text="Search Android 14 apps & games...")
        search.connect("search-changed", self.on_search)
        root.append(search)

        # Apps Grid
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        self.flow = Gtk.FlowBox()
        self.flow.set_valign(Gtk.Align.START)
        self.flow.set_max_children_per_line(3)
        self.flow.set_min_children_per_line(2)
        self.flow.set_selection_mode(Gtk.SelectionMode.NONE)
        self.flow.set_row_spacing(12)
        self.flow.set_column_spacing(12)
        scrolled.set_child(self.flow)
        root.append(scrolled)

        self.populate_apps("")

    def populate_apps(self, query):
        child = self.flow.get_first_child()
        while child:
            nxt = child.get_next_sibling()
            self.flow.remove(child)
            child = nxt

        q = query.strip().lower()
        for name, desc, pkg, icon in FEATURED_APPS:
            if q and q not in name.lower() and q not in desc.lower():
                continue
            card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            card.add_css_class("app-card")
            card.set_size_request(230, 120)

            top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            ico = Gtk.Label(label=f"<span size='xx-large'>{icon}</span>", use_markup=True)
            info = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            info.set_hexpand(True)
            lbl_name = Gtk.Label(label=name, xalign=0)
            lbl_name.set_markup(f"<b>{name}</b>")
            lbl_desc = Gtk.Label(label=desc, xalign=0)
            lbl_desc.add_css_class("muted")
            info.append(lbl_name)
            info.append(lbl_desc)
            top.append(ico)
            top.append(info)
            card.append(top)

            btn = Gtk.Button(label="Launch / Install")
            btn.add_css_class("install-btn")
            btn.connect("clicked", self.on_launch_pkg, name, pkg)
            card.append(btn)

            self.flow.append(card)

    def on_search(self, entry):
        self.populate_apps(entry.get_text())

    def on_start_waydroid(self, _btn):
        self.status_label.set_text("Starting Android 14 Waydroid session...")
        if os.system("which waydroid >/dev/null 2>&1") == 0:
            subprocess.Popen(["waydroid", "show-full-ui"])
        else:
            self.status_label.set_text("Waydroid container starting — install an Android image via 'sudo waydroid init -s GAPPS' when online.")

    def on_launch_pkg(self, _btn, name, pkg):
        self.status_label.set_text(f"Launching {name} ({pkg}) inside Android 14 container...")
        if os.system("which waydroid >/dev/null 2>&1") == 0:
            subprocess.Popen(["waydroid", "app", "launch", pkg])
        else:
            self.status_label.set_text(f"{name}: Run 'sudo waydroid init -s GAPPS' with internet to fetch Google Play Store & {name}.")

    def on_sideload(self, _btn):
        self.status_label.set_text("Opening APK Sideloader...")
        subprocess.Popen([
            "sh", "-c",
            "FILE=$(zenity --file-selection --title='Select Android .APK to Install' --file-filter='*.apk' 2>/dev/null) && [ -n \"$FILE\" ] && waydroid app install \"$FILE\""
        ])


class PlayStoreApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="org.aetheros.playstore", flags=Gio.ApplicationFlags.FLAGS_NONE)

    def do_activate(self):
        win = self.props.active_window or PlayStoreWindow(self)
        win.present()


if __name__ == "__main__":
    app = PlayStoreApp()
    app.run(None)
