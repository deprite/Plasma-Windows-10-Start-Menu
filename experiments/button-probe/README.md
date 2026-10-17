# Plasma Button Probe

This is an independent diagnostic widget. It does not import Kicker, create a
dashboard window, advertise itself as an application launcher, or register a
global shortcut. Version 0.2 supports two standard Plasma representations:

- a large test card when placed on the desktop;
- an icon-sized compact button when placed in a panel.

Version 0.3 adds persistent public-API configuration. Open the widget's
settings, choose **Appearance**, and use **Choose…** to select any installed
theme icon. The panel button and popup test button update from the saved value.

## Test

Install the package:

```bash
cd experiments/button-probe
./install.sh
```

Then right-click an empty area of the desktop, choose **Add Widgets**, and add
**Plasma Button Probe** to the desktop. Click **Test button**.
The text should change to:

```text
Success — the button clicked once.
```

## Panel test

After the desktop test succeeds, add a second **Plasma Button Probe** instance
to the panel. It should appear as a checkmark icon rather than the large card.
Clicking the icon should open a normal Plasma popup containing a success count.

This deliberately tests only Plasma's public compact/full representation and
popup lifecycle. Do not assign a keyboard shortcut yet.

### Confirmed result

The version 0.2 compact checkmark appeared in the panel, accepted mouse clicks,
and opened its standard Plasma popup successfully during development. This
confirmed package loading, panel sizing, compact representation, pointer
handling, and the normal popup lifecycle on the test system.

### Shortcut safety

Avoid `Ctrl+Alt+Fn` combinations: Linux commonly reserves them for virtual
terminal switching, and behavior can vary by system. The probe should have no
global shortcut, and Meta should remain reserved for Plasma's stock application
launcher while testing.

Remove the widget from the desktop before uninstalling it:

```bash
./uninstall.sh
```

This probe uses the public Plasma 6 widget API only. A failure therefore points
to basic representation or packaging behavior rather than the start screen's
private dashboard integration.
