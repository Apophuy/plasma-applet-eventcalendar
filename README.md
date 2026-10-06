# Apophuy Calendar

**English** | [Русский](README_RU.md)

A Plasma calendar widget with an agenda, weather forecast, timer, and Google Calendar synchronization.

**Plasma 6 / KDE Frameworks 6 / Qt 6** — works on both Wayland and X11.

This project is a clone of [Zren's original Event Calendar widget](https://github.com/Zren/plasma-applet-eventcalendar), ported to Plasma 6 and extended with bug fixes and compatibility improvements.

## Screenshots

The screenshots below show version 1.01 with the Russian localization enabled.

### Calendar popup

![Apophuy Calendar popup with the calendar, weather forecast, agenda, and timer](docs/screenshots/event-calendar-popup.png)

### Settings

| General | Calendar | Agenda |
| :-----: | :------: | :----: |
| ![General settings](docs/screenshots/settings-general.png) | ![Calendar settings](docs/screenshots/settings-calendar.png) | ![Agenda settings](docs/screenshots/settings-agenda.png) |

## Requirements

### Minimum versions

| Component                    | Version | Description                           |
| ---------------------------- | ------- | ------------------------------------- |
| KDE Plasma                   | ≥ 6.0   | Desktop environment                   |
| KDE Frameworks               | ≥ 6.0   | Core KDE libraries                    |
| Qt                           | ≥ 6.6   | Qt framework                          |
| X-Plasma-API-Minimum-Version | 6.0     | Plasma API declared in metadata       |

### Required Qt/QML modules

- `QtQuick` (Qt 6)
- `QtQuick.Controls`
- `QtQuick.Layouts`
- `Qt5Compat.GraphicalEffects`

### Required KDE modules

- `org.kde.plasma.plasmoid`
- `org.kde.plasma.core`
- `org.kde.plasma.components`
- `org.kde.plasma.plasma5support` for `DataSource`
- `org.kde.plasma.workspace.calendar` provided by `plasma-calendar-addons`
- `org.kde.kirigami`
- `org.kde.ksvg`
- `org.kde.config`
- `org.kde.kcmutils`

> `plasma-calendar-addons` is required. Without its calendar QML module, the widget cannot start correctly and may show only an icon instead of the clock.

### Installation tools

| Package         | Purpose                                                   |
| --------------- | --------------------------------------------------------- |
| `git`           | Source control                                            |
| `python3`       | OAuth, iCalendar support, and metadata generation         |
| `gettext`       | Translation building when installing from Git            |
| `kpackagetool6` | KDE package installer included with Plasma 6              |

### Optional dependencies

| Package              | Purpose                                                   |
| -------------------- | --------------------------------------------------------- |
| `plasma-sdk`         | Tools for launching the widget from its source directory |
| `kdeplasma-addons`   | Extra calendar plugins, including holidays               |
| `plasma-nm`          | Network monitoring                                       |

### Bundled Python scripts

- `package/contents/scripts/icsjson.py` — parses iCalendar sources
- `package/contents/scripts/google_oauth.py` — Google OAuth using a local loopback callback and PKCE
- `package/contents/scripts/konsolekalendar.py` — konsolekalendar integration
- `package/contents/scripts/notification.py` — event notifications

The Python `icalendar` module is needed to read local and remote `.ics` calendars. Recurring events are expanded only for the requested date range. `RRULE`, `RDATE`, `EXDATE`, modified and cancelled `RECURRENCE-ID` instances, and `THISANDFUTURE` changes are supported.

### Distribution packages

**Arch Linux / Manjaro:**

```bash
sudo pacman -S plasma-desktop qt6-5compat git gettext plasma-nm kdeplasma-addons plasma-calendar-addons python-icalendar
```

**Debian 13 (Trixie) / Ubuntu 24.04+:**

```bash
sudo apt install kde-plasma-desktop qml6-module-qt5compat-graphicaleffects git gettext plasma-nm plasma-calendar-addons python3-icalendar
```

**Fedora:**

```bash
sudo dnf install plasma-desktop qt6-qt5compat git gettext kf6-kpackage plasma-nm plasma-calendar-addons python3-icalendar
```

**openSUSE:**

```bash
sudo zypper install plasma6-desktop qt6-qt5compat-imports git gettext plasma-nm plasma-calendar-addons python3-icalendar
```

## Installation from GitHub

```bash
git clone https://github.com/Apophuy/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install
```

The installer builds translations, generates Plasma 6 `metadata.json` from the canonical `package/metadata.desktop`, and then runs `kpackagetool6`. If the widget is already installed, it is upgraded and Plasma Shell is restarted automatically.

### Installer options

```bash
sh ./install           # Install or upgrade
sh ./install --restart # Install and force a Plasma Shell restart
sh ./install -r        # Alias for --restart
```

## Updating

```bash
cd eventcalendar
sh ./update
```

The update script pulls the latest changes, reinstalls the widget, and restarts Plasma Shell. To update manually:

```bash
cd eventcalendar
git pull
sh ./install --restart
```

## Uninstallation

```bash
cd eventcalendar
sh ./uninstall
```

Or remove the package manually:

```bash
kpackagetool6 -t Plasma/Applet -r org.kde.plasma.eventcalendar
```

## Development and debugging

To launch the current source tree in a separate window:

```bash
plasmawindowed ./package
```

Enable debugging in **Apophuy Calendar Settings → General**, then inspect the journal:

```bash
journalctl --user -f | grep eventcalendar
```

When testing a development checkout, remove any distribution-packaged version first. When finished, run `sh ./uninstall` and reinstall the version you prefer.

## Configuration

### Google Calendar

1. Right-click the widget and open **Apophuy Calendar Settings → Google Calendar**.
2. Select **Log in with Google**. Your browser opens automatically.
3. Sign in and allow Calendar and Tasks access. Return to the widget settings after the local redirect.
4. Once synchronization is confirmed, select **Apply**.

Authentication uses a loopback callback on `127.0.0.1` with PKCE. It requires `python3` and works in both Wayland and X11 sessions.

### Google Tasks

1. Open the same **Google Calendar** settings page.
2. Select the task lists you want to display.

### Weather (OpenWeatherMap)

1. Open the **Weather** settings page.
2. Enter your OpenWeatherMap city ID.
3. If the city search does not find your location, search the web for `site:openweathermap.org/city city_name`.

Weather Canada is available as an alternative for Canadian locations.

### iCalendar calendars (.ics)

1. Open the **iCalendar calendars (.ics)** settings page.
2. Add a local `.ics` file or a calendar URL.
3. The integration is read-only: imported events appear in the calendar and agenda.

### Plasma calendar plugins

The widget supports Plasma calendar plugins such as holiday events:

1. Install `kdeplasma-addons`.
2. Enable the required plugins on the **Events** settings page.
3. Plugins are usually installed under `/usr/lib/qt6/plugins/plasmacalendarplugins/` or `/usr/lib64/qt6/plugins/plasmacalendarplugins/`.

## Features

- Monthly calendar with event indicators
- Agenda for upcoming events
- Google Calendar events and Google Tasks
- Local and remote iCalendar (`.ics`) sources
- Plasma calendar plugins such as holidays
- Current weather and forecasts from OpenWeatherMap or Weather Canada
- Hourly temperature and precipitation meteogram
- Timer with configurable presets and sound
- Configurable one- or two-column layout, colors, sizing, date formats, cell borders, and corner radii
- Event and timer notifications

## Troubleshooting

### The widget does not appear after installation

Restart Plasma Shell through systemd:

```bash
systemctl --user restart plasma-plasmashell.service
```

If this service is unavailable, log out of Plasma and sign in again.

### Google Calendar does not synchronize

1. Check the network connection.
2. Sign out and sign in again on the **Google Calendar** settings page.
3. Update the widget to the latest version.

### Weather does not update

1. Check the configured city ID.
2. Check the network connection.
3. OpenWeatherMap may temporarily reject excessive requests with HTTP 429; wait before retrying.

### Problems after upgrading from Plasma 5 to Plasma 6

```bash
cd eventcalendar
sh ./uninstall
sh ./install --restart
```

## Project structure

```text
package/
├── metadata.desktop           # Canonical plugin metadata
├── metadata.json              # Generated by build/install; not tracked
├── contents/
│   ├── config/
│   │   ├── config.qml         # Settings categories
│   │   └── main.xml           # Configuration schema
│   ├── ui/
│   │   ├── main.qml           # PlasmoidItem entry point
│   │   ├── Logic.qml          # Update orchestration
│   │   ├── EventModel.qml     # Aggregated event model
│   │   ├── AgendaModel.qml    # Agenda model
│   │   ├── PopupView.qml      # Full widget view
│   │   ├── ClockView.qml      # Compact representation
│   │   ├── calendars/         # Calendar integrations
│   │   ├── weather/           # Weather providers
│   │   ├── config/            # Settings pages
│   │   └── lib/               # Shared components and helpers
│   └── scripts/               # Python integrations and notifications
└── translate/                 # Translation sources
```

## Architecture

```text
Calendar managers → EventModel → AgendaModel → UI views
```

The calendar managers integrate Google Calendar, Google Tasks, Plasma calendar plugins, and iCalendar sources. `Logic.qml` coordinates polling, event updates, and weather refreshes. Settings are stored through `Plasmoid.configuration`; `ConfigMigration.qml` migrates older configuration keys when required.

## Localization

English is the source language. The project also includes translations for Russian, German, Spanish, Finnish, French, Hebrew, Italian, Japanese, Korean, Dutch, Polish, Brazilian and European Portuguese, Slovenian, Swedish, Turkish, Ukrainian, and Simplified Chinese.

To update or test translations:

```bash
cd package/translate
sh ./merge
sh ./build
sh ./plasmoidlocaletest ru
```

## License

GPL. See the source files for details.

## Authors

- Apophuy — developer and maintainer
- GitHub: https://github.com/Apophuy/plasma-applet-eventcalendar

Thanks to all translators, contributors, and the KDE community.

Current version: **1.00** (see `package/metadata.desktop`).

See [Changelog.md](Changelog.md) for the change history.
