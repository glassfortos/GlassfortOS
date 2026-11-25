#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Glassfort live and installation medium (archiso profile, based on archiso's
# releng profile). UEFI only: Glassfort needs UEFI (docs/02-system.md).
# shellcheck disable=SC2034

iso_name="glassfort"
iso_label="GLASSFORT_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Glassfort project <https://github.com/glassfortos/GlassfortOS>"
iso_application="Glassfort live and installation medium"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="glassfort"
buildmodes=('iso')
bootmodes=('uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers.d/10-live"]="0:0:440"
  ["/root"]="0:0:750"
)
