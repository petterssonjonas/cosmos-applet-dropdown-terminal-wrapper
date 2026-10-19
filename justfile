import 'recipes/common.just'

name := 'cosmos-applet-dropdown-terminal-wrapper'
appid := 'dev.jp.CosmosAppletDropdownTerminalWrapper'
launcher-id := 'dev.jp.CosmosDropdownTerminalWrapper'
toggle := name + '-toggle'
shortcut := name + '-shortcut'
profile := 'release'
prefix := env('HOME') / '.local'
rootdir := ''
cargo-target-dir := env('CARGO_TARGET_DIR', 'target')
base-dir := absolute_path(clean(rootdir / prefix))

[default]
default: build-release

build-debug:
    cargo build --locked --target-dir {{quote(cargo-target-dir)}}
    cargo build --locked --manifest-path shortcut/Cargo.toml --target-dir {{quote(absolute_path(cargo-target-dir))}}

build-release:
    cargo build --release --locked --target-dir {{quote(cargo-target-dir)}}
    cargo build --release --locked --manifest-path shortcut/Cargo.toml --target-dir {{quote(absolute_path(cargo-target-dir))}}

check:
    cargo clippy --all-targets --locked --target-dir {{quote(cargo-target-dir)}} -- -D warnings
    cargo clippy --all-targets --locked --manifest-path shortcut/Cargo.toml --target-dir {{quote(absolute_path(cargo-target-dir))}} -- -D warnings

test:
    cargo test --locked --target-dir {{quote(cargo-target-dir)}}
    cargo test --locked --manifest-path shortcut/Cargo.toml --target-dir {{quote(absolute_path(cargo-target-dir))}}
    python3 -m unittest discover -s tests -v

# Directly run Kitty's native dropdown; the panel hosts the separate applet binary.
[positional-arguments]
run *args:
    python3 {{quote('bin' / toggle)}} "$@"

# Build separately. Install files only, without changing shortcuts or panel layout.
install:
    @just --justfile {{quote(justfile())}} _install-file {{quote(cargo-target-dir / profile / name)}} {{quote(base-dir / 'bin' / name)}} 0755
    @just --justfile {{quote(justfile())}} _install-file {{quote(cargo-target-dir / profile / shortcut)}} {{quote(base-dir / 'bin' / shortcut)}} 0755
    @just --justfile {{quote(justfile())}} _install-file {{quote('bin' / toggle)}} {{quote(base-dir / 'bin' / toggle)}} 0755
    @just --justfile {{quote(justfile())}} _install-file resources/kitty.conf {{quote(base-dir / 'share' / name / 'kitty.conf')}} 0644
    @just --justfile {{quote(justfile())}} _install-desktop resources/app.desktop {{quote(base-dir / 'share/applications' / appid + '.desktop')}} {{quote(absolute_path(prefix / 'bin' / name))}}
    @just --justfile {{quote(justfile())}} _install-desktop resources/launcher.desktop {{quote(base-dir / 'share/applications' / launcher-id + '.desktop')}} {{quote(absolute_path(prefix / 'bin' / toggle))}}

# Running Kitty sessions, user preferences and shortcuts are retained.
uninstall:
    rm -f -- {{quote(base-dir / 'bin' / name)}} {{quote(base-dir / 'bin' / shortcut)}} {{quote(base-dir / 'bin' / toggle)}} {{quote(base-dir / 'share' / name / 'kitty.conf')}} {{quote(base-dir / 'share/applications' / appid + '.desktop')}} {{quote(base-dir / 'share/applications' / launcher-id + '.desktop')}}

# Explicit opt-in. Close COSMIC Settings first; conflicting bindings are refused.
configure-shortcut:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ -z {{quote(rootdir)}} && $EUID != 0 ]] || { printf '%s\n' 'Configure shortcuts as the desktop user, without staging.' >&2; exit 1; }
    {{quote(absolute_path(prefix / 'bin' / shortcut))}} {{quote(quote(absolute_path(prefix / 'bin' / toggle)))}}

# No persisted settings are stored outside the installed, isolated Kitty config.
migrate:
    @printf '%s\n' 'No persistent app preferences to copy. Preserve any manually edited old kitty.conf before installing. Close old Kitty dropdown sessions after saving jobs; replace the old panel entry and shortcut in COSMIC Settings, then run just configure-shortcut.'
