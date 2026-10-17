# Plasma Windows 10 Start Menu

A Windows 10-inspired, full-screen, tile-based application launcher for KDE
Plasma 6.

This project recreates the practical layout of the Windows 10 Start menu while
using Plasma's application model, search, session controls, and visual style.
It is an independent community project and is not affiliated with or endorsed
by Microsoft.

## Features

- Full-screen launcher with a configurable translucent background
- Search powered by Plasma's application runner
- Alphabetical application drawer
- Persistent, reorderable tile groups
- Configurable group column counts and application tiles
- Drag-and-drop tile and group organization
- Optional Home, Pictures, and System Settings shortcuts
- User actions for locking, switching users, and logging out
- Power actions for sleep, restart, and shutdown
- Shared launcher layouts across multiple screens
- Plasma panel button and native Meta-key launcher integration

## Compatibility

The widget requires **KDE Plasma 6**. It is intended to be distribution
independent, but has currently been tested only on Kubuntu with Plasma 6.6.6.
Reports from other Plasma distributions and releases are welcome.

The implementation uses some private Plasma QML APIs. These may change between
Plasma releases, so compatibility with future versions cannot be guaranteed.

## Installation

Clone the repository and run:

```bash
./tools/install.sh
```

The installer creates a backup of relevant Plasma configuration files before
installing or upgrading the widget. It prints the backup location when it
finishes.

Enter panel edit mode, select **Add Widgets**, and add **Plasma Start Screen**.
Keep Plasma's stock application launcher available until you have confirmed
that the new widget opens and closes correctly on your system.

The widget advertises Plasma's standard launcher capability, allowing Plasma's
global Meta-key action to activate it. A separate Meta shortcut should not be
assigned to each widget instance.

## Development preview

After installation, launch a windowed preview with:

```bash
plasmawindowed org.kde.plasma.win10start
```

## Uninstallation

```bash
./tools/uninstall.sh
```

## Recovery

If Plasma becomes unstable after installing the widget, switch to a text
console, sign in, and run:

```bash
./tools/recover.sh PATH_TO_BACKUP_DIRECTORY
```

Use the backup directory printed by the installer. The recovery script stops
Plasma Shell, moves the installed widget to a timestamped disabled directory,
restores the available configuration files, and attempts to restart Plasma
Shell. The widget is quarantined rather than deleted.

## Contributing

Bug reports and merge or pull requests are welcome. When reporting a problem,
please include your Linux distribution, Plasma version, installation method,
and any relevant Plasma Shell log output. Do not include passwords, tokens, or
other private information.

## License

Copyright © 2026 Flo S.

This project is free software licensed under the GNU General Public License,
version 3 or (at your option) any later version. See [LICENSE](LICENSE).

Windows is a trademark of the Microsoft group of companies. All other
trademarks are the property of their respective owners. This project is not
affiliated with or endorsed by Microsoft.
