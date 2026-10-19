# Cosmos Dropdown Terminal Wrapper

A COSMIC panel applet that controls [Kitty's native panel](https://sw.kovidgoyal.net/kitty/kittens/panel/). The panel button and shortcut use the same single-instance visibility toggle. This uses Kitty, not Ghostty. It does not inject input, reparent windows or modify your normal terminal configuration.

The dropdown uses the full output width and 40% of its logical height. It respects reserved panel space and overlays other windows. Hiding preserves its shell, scrollback and running programs. Exiting the shell closes that session. There is no animation or automatic hide on focus loss.

## Requirements

Runtime: COSMIC Wayland with layer-shell and output-management support, Python 3.9 or newer, `wlr-randr --json`, and Kitty/kitten with `panel --single-instance --toggle-visibility`. Kitty **0.48.2** was exercised. Older versions are not verified. Distribution package versions can be too old; use a suitable [upstream Kitty release](https://sw.kovidgoyal.net/kitty/binary/) if necessary.

Install runtime packages on the desktop host:

```sh
# Fedora
sudo dnf install kitty wlr-randr python3
# Debian
sudo apt install kitty wlr-randr python3
# Arch Linux
sudo pacman -S --needed kitty wlr-randr python
```

Build/install: current stable Rust from [rustup](https://rustup.rs), `just`, Bash, GNU coreutils/findutils, Git and native development packages. Distribution Rust can be too old. The following package examples do not mean all distributions were tested.

Fedora:

```sh
sudo dnf install git just gcc-c++ cmake pkgconf-pkg-config desktop-file-utils \
  expat-devel freetype-devel fontconfig-devel wayland-devel libxkbcommon-devel \
  libxkbcommon-x11-devel libinput-devel mesa-libEGL-devel libX11-devel \
  libXcursor-devel libXi-devel libXrandr-devel dbus-devel openssl-devel
```

Debian 13 or newer:

```sh
sudo apt update
sudo apt install git just build-essential cmake pkgconf desktop-file-utils \
  libexpat1-dev libfreetype-dev libfontconfig-dev libwayland-dev libxkbcommon-dev \
  libxkbcommon-x11-dev libinput-dev libegl1-mesa-dev libx11-dev libxcursor-dev \
  libxi-dev libxrandr-dev libdbus-1-dev libssl-dev
```

Arch Linux:

```sh
sudo pacman -S --needed git just base-devel cmake pkgconf desktop-file-utils \
  expat freetype2 fontconfig wayland libxkbcommon libxkbcommon-x11 libinput \
  mesa libglvnd libx11 libxcursor libxi libxrandr dbus openssl
```

Desktop-launch tests also need `gio`: Fedora `sudo dnf install glib2`; Debian `sudo apt install libglib2.0-bin`; Arch `sudo pacman -S --needed glib2`. `gio` is not a wrapper runtime requirement.

## Build and install

Install rustup from its linked site first. Run as your desktop user:

```sh
git clone https://github.com/petterssonjonas/cosmos-applet-dropdown-terminal-wrapper
cd cosmos-applet-dropdown-terminal-wrapper
rustup toolchain install stable
rustup override set stable
just build-release
just install
```

Use `sudo` only for system package prerequisites, never for `just build-release` or `just install`. Installation uses `~/.local/bin` and `~/.local/share`. It does not install Kitty or change panel entries, shortcuts or normal Kitty settings. Use your mapped desktop user in build containers, not root.

## Enable and use

In **COSMIC Settings → Desktop → Panel → Applets**, add **Cosmos Dropdown Terminal (Kitty)**. Reopen Settings or log in again if necessary. Close Settings, then explicitly enable **Super+§**:

```sh
just configure-shortcut
```

Only one dropdown implementation can own this shortcut. Registration preserves other actions, saves a `custom.before-dropdown` backup and refuses conflicts. `§` means XKB `section`, not a fixed physical key. For another layout, set the shortcut manually to `/home/YOUR_USER/.local/bin/cosmos-applet-dropdown-terminal-wrapper-toggle`.

The default output is the leftmost enabled output, then the topmost. It does not follow the pointer. Use `--output DP-1` for the helper and the same `COSMOS_DROPDOWN_OUTPUT=DP-1` session setting for the panel. One session exists per Wayland display/output pair. An existing Kitty panel cannot move between outputs. Geometry updates apply on the next toggle. Click inside the terminal if the compositor does not focus it automatically.

The isolated configuration is `~/.local/share/cosmos-applet-dropdown-terminal-wrapper/kitty.conf`. Logs use the private `$XDG_RUNTIME_DIR/cosmos-applet-dropdown-terminal-wrapper/` directory.

**Verification limit:** an isolated nested winit/Xvfb COSMIC session exercised Kitty 0.48.2 cold start, keyboard input, 40% geometry and shell survival after hiding. Later toggles returned success without a visible re-show. Re-show remains unverified in that environment and in a normal host session after the rename. No visibility workaround was added. Validate this behavior in your own session before relying on the wrapper.

## Migration and removal

Remove the old `cosmic-dropdown-wrapper` panel entry and shortcut. Finish jobs and exit old Kitty dropdown sessions. New application identities do not reuse old sessions. Run `just migrate` for the cutover instructions; no saved preferences need copying. Preserve manual edits to the old isolated `kitty.conf` and merge them yourself. Add the new panel entry and explicitly configure its shortcut. There are no legacy aliases. Use the old version's uninstaller, if available, to remove old registrations.

For removal, remove the panel entry and shortcut, exit the dropdown normally, then run `just uninstall`. Uninstallation does not terminate running jobs.

## License

Independent project; not an official System76 application. GPL-3.0-only; see `LICENSE`. Kitty is an external dependency, not included source. Native build guidance: [libcosmic](https://github.com/pop-os/libcosmic#dependencies). Runtime package references: [Fedora Kitty](https://packages.fedoraproject.org/pkgs/kitty/kitty/), [Debian wlr-randr](https://packages.debian.org/search?keywords=wlr-randr), [Arch Kitty](https://archlinux.org/packages/extra/x86_64/kitty/).
