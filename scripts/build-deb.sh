#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2025-2026 <Nitrux Latinoamericana S.C. <hello@nxos.org>>


# -- Exit on errors.

set -euo pipefail

# -- Prepare source.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
PACKAGE_VERSION="${PACKAGE_VERSION:-0.0.1}"
TARGET_ARCH="${TARGET_ARCH:-$(dpkg --print-architecture)}"

# -- Download Source

git clone --depth 1 --branch "${MAUIKIT_SYSTEM_BRANCH}" https://github.com/Nitrux/mauikit-system-src.git "$repo_root/mauikit-system-src"
source_dir="$repo_root/mauikit-system-src"

# -- Configure build.

build_dir="$repo_root/build"
meson_dir="$build_dir/meson"
stage_dir="$build_dir/package"
rm -rf "$meson_dir" "$stage_dir"
mkdir -p "$build_dir"

meson_args=(--prefix=/usr --buildtype=release)
if [ "$(dpkg-architecture -qDEB_HOST_ARCH)" = "amd64" ]; then
    meson_args+=("-Dcpp_args=-march=x86-64-v3")
fi

# -- Compile Source

meson setup "$meson_dir" "$source_dir" "${meson_args[@]}"
meson compile -C "$meson_dir" -j "$(nproc)"

# -- Install source to DESTDIR.

DESTDIR="$stage_dir" meson install -C "$meson_dir"

# -- Create DEBIAN control file.

mkdir -p "$stage_dir/DEBIAN"
cat > "$stage_dir/DEBIAN/control" <<CONTROL
Package: mauikit-system
Version: ${PACKAGE_VERSION}
Section: libs
Priority: optional
Architecture: ${TARGET_ARCH}
Maintainer: uri_herrera@nxos.org
Provides: mauikit-system
Depends: libc6,libkf6bluezqt6,libkf6configcore6,libkf6coreaddons6,libkf6i18n6,libkf6idletime6,libkf6kiogui6,libkf6modemmanagerqt6,libkf6networkmanagerqt6,libkf6notifications6,libkf6service6,libkf6solid6,libnm0,libpipewire-0.3-0t64|libpipewire-0.3-0,libqcoro6core0t64|libqcoro6core0,libqcoro6dbus0t64|libqcoro6dbus0,libqt6core6t64,libqt6dbus6,libqt6gui6,libqt6keychain1,libqt6qml6,libqt6quick6,mauikit (>= 4.0.4),qml6-module-org-kde-bluezqt
Description: mauikit-system
 mauikit-system
CONTROL

# -- Create .deb.

dpkg-deb --build --root-owner-group "$stage_dir" "$build_dir/mauikit-system_${PACKAGE_VERSION}_${TARGET_ARCH}.deb"
