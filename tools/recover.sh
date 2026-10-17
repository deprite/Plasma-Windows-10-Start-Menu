#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! -d "$1" ]]; then
    echo "Usage: $0 BACKUP_DIRECTORY" >&2
    echo "Pass the backup path printed by tools/install.sh." >&2
    exit 2
fi

backup_dir="$(cd -- "$1" && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
package_dir="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/org.kde.plasma.win10start"
disabled_dir="${package_dir}.disabled-$(date +%Y%m%d-%H%M%S)"

systemctl --user stop plasma-plasmashell.service 2>/dev/null || true

if [[ -d "$package_dir" ]]; then
    mv -- "$package_dir" "$disabled_dir"
    echo "Quarantined the widget at: $disabled_dir"
fi

restored=false
for config_file in plasma-org.kde.plasma.desktop-appletsrc kglobalshortcutsrc plasma-start-screen-layout.ini; do
    if [[ -f "$backup_dir/$config_file" ]]; then
        cp -a -- "$backup_dir/$config_file" "$config_dir/$config_file"
        restored=true
    fi
done

if [[ "$restored" != true ]]; then
    echo "The backup contains no Plasma configuration files." >&2
    exit 1
fi

systemctl --user start plasma-plasmashell.service 2>/dev/null || true
echo "Plasma configuration restored. Reboot if the shell did not restart."
