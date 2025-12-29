# Event Calendar Plasmoid - AI Instructions

## Project Overview

KDE Plasma widget (plasmoid) providing calendar+agenda with weather, syncing to Google Calendar. Built with **QML/Qt 6** for **Plasma 6** (KDE Frameworks 6). Works on both **Wayland** and **X11**.

## Architecture

### Entry Point & Core

- [main.qml](../package/contents/ui/main.qml) - Root `PlasmoidItem` component, initializes all models and managers
- `Plasmoid.configuration.*` - All settings from [main.xml](../package/contents/config/main.xml)
- [metadata.json](../package/metadata.json) - Plugin metadata (Plasma 6 uses JSON, not .desktop)

### Data Flow

```
CalendarManagers → EventModel → AgendaModel → UI Views
     ↓
GoogleCalendarManager, PlasmaCalendarManager, ICalManager
```

- **CalendarManager** ([calendars/CalendarManager.qml](../package/contents/ui/calendars/CalendarManager.qml)) - Base class with signals: `refresh`, `calendarFetched`, `eventAdded/Removed/Updated`, `error`
- **EventModel** ([EventModel.qml](../package/contents/ui/EventModel.qml)) - Aggregates all calendar managers, merges events
- **AgendaModel** ([AgendaModel.qml](../package/contents/ui/AgendaModel.qml)) - Transforms events for agenda view display
- **Logic** ([Logic.qml](../package/contents/ui/Logic.qml)) - Orchestrates updates, polling, weather fetching

### Key Directories

- `package/contents/ui/` - Main QML components
- `package/contents/ui/calendars/` - Calendar backend integrations (Google, Plasma, ICal)
- `package/contents/ui/weather/` - Weather APIs (OpenWeatherMap, WeatherCanada)
- `package/contents/ui/config/` - Settings UI panels
- `package/contents/ui/lib/` - Reusable components (`Logger`, `Requests.js`, `Async.js`, config helpers)
- `package/contents/config/` - Configuration schema (`main.xml`) and categories (`config.qml`)

## Plasma 6 / Qt 6 Conventions

### Import Style (no version numbers)

```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support  // for DataSource
import org.kde.ksvg as KSvg  // for SVG theming
import org.kde.kcmutils as KCMUtils  // for config pages
```

### Key API Changes from Plasma 5

| Plasma 5                          | Plasma 6                                   |
| --------------------------------- | ------------------------------------------ |
| `Item { }` as root                | `PlasmoidItem { }` as root                 |
| `Plasmoid.toolTipItem:`           | `toolTipItem:` (direct property)           |
| `Plasmoid.compactRepresentation:` | `compactRepresentation:` (direct property) |
| `plasmoid.expanded`               | `root.expanded`                            |
| `plasmoid.configuration.*`        | `Plasmoid.configuration.*`                 |
| `PlasmaCore.Units.*`              | `Kirigami.Units.*`                         |
| `PlasmaCore.IconItem`             | `Kirigami.Icon`                            |
| `PlasmaCore.DataSource`           | `Plasma5Support.DataSource`                |
| `PlasmaCore.Svg/FrameSvgItem`     | `KSvg.Svg/FrameSvgItem`                    |
| `theme.textColor`                 | `Kirigami.Theme.textColor`                 |
| `units.gridUnit`                  | `Kirigami.Units.gridUnit`                  |
| `onClicked: { }`                  | `onClicked: (mouse) => { }`                |

### Contextual Actions (declarative style)

```qml
Plasmoid.contextualActions: [
    PlasmaCore.Action {
        text: i18n("Action Name")
        icon.name: "icon-name"
        onTriggered: doSomething()
    }
]
```

## Development Workflow

### Install/Test (Plasma 6)

```bash
sh ./install           # Install widget (restarts plasmashell if already installed)
sh ./install --restart # Force restart plasmashell
sh ./uninstall         # Remove widget
sh ./update            # git pull + reinstall
```

Uses `kpackagetool6` for installation.

### Debugging

- Enable `Plasmoid.configuration.debugging` to show debug logs
- Use `logger.debug()` from the global `Logger` component
- Test with `plasmoidviewer` (from `plasma-sdk` package)
- For Wayland: `plasmoidviewer -a org.kde.plasma.eventcalendar`

### Translations

```bash
cd package/translate
sh ./merge  # Update template.pot from i18n() calls
sh ./build  # Compile .po → .mo files
sh ./plasmoidlocaletest  # Test with plasmoidviewer
```

## Code Patterns

### Configuration Access

```qml
// Read config (capital P for attached property)
Plasmoid.configuration.widgetShowAgenda
// Write config
Plasmoid.configuration.agendaNewEventLastCalendarId = calendarId
```

### HTTP Requests

Use `lib/Requests.js` for API calls:

```qml
import "./lib/Requests.js" as Requests
Requests.getJSON(url, callback)
```

### Async Operations

Use `lib/Async.js` for parallel/series tasks (see `GoogleCalendarManager.qml`)

### i18n

Always wrap user-visible strings: `i18n("Text")` or `i18n("Hello %1", name)`

### Configuration Migration

Add migrations in [ConfigMigration.qml](../package/contents/ui/ConfigMigration.qml) when renaming config keys. Use version flags like `v72Migration`.

## Important Files

- [metadata.json](../package/metadata.json) - Plugin metadata, version, requires `X-Plasma-API-Minimum-Version: 6.0`
- [main.xml](../package/contents/config/main.xml) - All configuration options with defaults
- [Shared.js](../package/contents/ui/Shared.js) - Shared utility functions
- [ErrorType.js](../package/contents/ui/ErrorType.js) - Error type constants

## Conventions

- Use camelCase for config keys (migrated from snake_case in v71)
- Calendar managers emit signals, EventModel listens and aggregates
- Weather data flows: `Logic.updateWeather()` → `WeatherApi.js` → `dailyWeatherData`/`hourlyWeatherData`
- Font icons for weather via `weathericons-regular-webfont.ttf`
- Root component must be `PlasmoidItem` (not `Item`)
- No version numbers in QML imports
