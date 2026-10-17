#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/plasma-start-screen/backups"
backup_dir="$backup_root/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$backup_dir"
for config_file in plasma-org.kde.plasma.desktop-appletsrc kglobalshortcutsrc plasma-start-screen-layout.ini; do
    source_path="${XDG_CONFIG_HOME:-$HOME/.config}/$config_file"
    if [[ -f "$source_path" ]]; then
        cp -a "$source_path" "$backup_dir/"
    fi
done

kpackagetool6 --type Plasma/Applet --upgrade "$project_dir" \
    || kpackagetool6 --type Plasma/Applet --install "$project_dir"

echo "Installed Plasma Start Screen. Add it from Plasma's widget picker."
echo "Plasma configuration backup: $backup_dir"
echo "Keep the stock launcher until click and shortcut activation are stable."
