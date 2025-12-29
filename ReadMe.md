# Event Calendar

Plasmoid for a calendar+agenda with weather that syncs to Google Calendar.

**Plasma 6 / KDE Frameworks 6 / Qt 6** — Works on both Wayland and X11.

## Screenshots

![](https://i.imgur.com/qdJ71sb.jpg)
![](https://i.imgur.com/Ow8UlFj.jpg)

## Requirements

### Runtime Dependencies

| Package                    | Minimum Version | Description                                     |
| -------------------------- | --------------- | ----------------------------------------------- |
| KDE Plasma                 | 6.0             | Desktop environment                             |
| KDE Frameworks             | 6.0             | Core KDE libraries                              |
| Qt                         | 6.6+            | Qt framework                                    |
| Qt5Compat.GraphicalEffects | 6.6+            | Qt 5 compatibility module for graphical effects |

### Build/Install Dependencies

| Package         | Description                                    |
| --------------- | ---------------------------------------------- |
| `git`           | Version control (for GitHub install)           |
| `kpackagetool6` | KDE package installer (included with Plasma 6) |

### Optional Dependencies

| Package            | Description                                   |
| ------------------ | --------------------------------------------- |
| `plasma-sdk`       | For `plasmoidviewer` debugging tool           |
| `kdeplasma-addons` | Additional Plasma calendar plugins (holidays) |

### Distribution-specific packages

**Arch Linux / Manjaro:**

```bash
sudo pacman -S plasma-desktop qt6-5compat git
```

**Debian 13 (Trixie):**

```bash
# All dependencies are included with kde-plasma-desktop
sudo apt install kde-plasma-desktop git
```

**Fedora:**

```bash
sudo dnf install plasma-desktop qt6-qt5compat git kf6-kpackage
```

**Ubuntu / Kubuntu (24.04+):**

```bash
sudo apt install kde-plasma-desktop qml6-module-qt5compat-graphicaleffects git
```

**openSUSE:**

```bash
sudo zypper install plasma6-desktop qt6-qt5compat-imports git
```

## Installation

### A) Install via KDE Store

1. Right Click Panel > Panel Options > Add Widgets
2. Get New Widgets > Download New Widgets
3. Search: **Event Calendar**
4. Install
5. Right Click your current calendar widget > Alternatives
6. Select **Event Calendar**

### B) Install via GitHub

```bash
git clone https://github.com/Apophuy/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install
```

The install script uses `kpackagetool6` to install the plasmoid. If the widget is already installed, it will upgrade it automatically and restart plasmashell.

### C) Install via Package Manager

Community-maintained packages may be available:

- **Arch Linux (AUR):** `plasma6-applets-eventcalendar` (community)

> **Note:** Package availability depends on community maintainers. Check your distribution's package repository.

## Update

To update from GitHub, run the update script:

```bash
cd eventcalendar
sh ./update
```

This will run `git pull` and reinstall the widget. Plasmashell will be restarted automatically.

Alternatively, update manually:

```bash
cd eventcalendar
git pull
sh ./install --restart
```

## Uninstall

To remove the widget:

```bash
cd eventcalendar
sh ./uninstall
```

Or manually using kpackagetool6:

```bash
kpackagetool6 -t Plasma/Applet -r org.kde.plasma.eventcalendar
```

## Development / Testing

If you're testing unreleased code:

1. Uninstall any package manager version first
2. Clone and install from GitHub:

```bash
git clone https://github.com/Apophuy/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install --restart
```

For debugging, use `plasmoidviewer` from `plasma-sdk`:

```bash
plasmoidviewer -a org.kde.plasma.eventcalendar
```

When finished testing, uninstall with `sh ./uninstall` and reinstall your preferred version.

## Configure

1. Right click the Calendar > **Event Calendar Settings** > **Google Calendar**
2. Copy the Code and enter it at the given link. Keep the settings window open.
3. After the settings window says it's synced, click **Apply**.
4. Go to the **Weather** Tab > Enter your city id for OpenWeatherMap.
   - If their search can't find your city, try googling it with [site:openweathermap.org/city](https://www.google.ca/search?q=site%3Aopenweathermap.org%2Fcity+toronto).

## Troubleshooting

### Widget doesn't appear after install

- Restart plasmashell: `systemctl --user restart plasma-plasmashell.service`
- Or: `killall plasmashell && kstart plasmashell`

### Google Calendar sync issues

- Ensure you're logged in and the access token is valid
- Try logging out and logging back in via settings

### Weather not loading

- Verify your OpenWeatherMap city ID is correct
- Check your internet connection
