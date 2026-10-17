#!/usr/bin/env bash
set -euo pipefail

package_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if kpackagetool6 --type Plasma/Applet --list | grep -Fxq org.kde.plasma.buttonprobe; then
    kpackagetool6 --type Plasma/Applet --upgrade "$package_dir"
else
    kpackagetool6 --type Plasma/Applet --install "$package_dir"
fi

echo "Installed Plasma Button Probe. Add it to the desktop from Add Widgets."
