import QtQuick
import org.kde.plasma.configuration
import org.kde.plasma.calendar as PlasmaCalendar
import org.kde.plasma.plasmoid

import "../ui/calendars/PlasmaCalendarUtils.js" as PlasmaCalendarUtils

ConfigModel {
	id: configModel

	ConfigCategory {
		name: i18n("General")
		icon: "clock"
		source: "config/ConfigGeneral.qml"
	}
	// ConfigCategory {
	// 	name: i18n("Clock")
	// 	icon: "clock"
	// 	source: "config/ConfigClock.qml"
	// }
	ConfigCategory {
		name: i18n("Layout")
		icon: "grid-rectangular"
		source: "config/ConfigLayout.qml"
	}
	ConfigCategory {
		name: i18n("Timezones")
		icon: "preferences-system-time"
		source: "config/ConfigTimezones.qml"
	}
	ConfigCategory {
		name: i18n("Calendar")
		icon: "view-calendar"
		source: "config/ConfigCalendar.qml"
	}
	ConfigCategory {
		name: i18n("Agenda")
		icon: "view-calendar-agenda"
		source: "config/ConfigAgenda.qml"
	}
	ConfigCategory {
		name: i18n("Events")
		icon: "view-calendar-week"
		source: "config/ConfigEvents.qml"
	}
	ConfigCategory {
		name: i18n("ICalendar (.ics)")
		icon: "text-calendar"
		source: "config/ConfigICal.qml"
		visible: Plasmoid.configuration.debugging
	}
	ConfigCategory {
		name: i18n("Google Calendar")
		icon: Plasmoid.file("", "icons/google_calendar_96px.png")
		source: "config/ConfigGoogleCalendar.qml"
	}
	ConfigCategory {
		name: i18n("Weather")
		icon: "weather-clear"
		source: "config/ConfigWeather.qml"
	}
	ConfigCategory {
		name: i18n("Advanced")
		icon: "applications-development"
		source: "lib/ConfigAdvanced.qml"
		visible: Plasmoid.configuration.debugging
	}

	property Instantiator __eventPlugins: Instantiator {
		model: PlasmaCalendar.EventPluginsManager.model
		delegate: ConfigCategory {
			name: model.display
			icon: model.decoration
			source: model.configUi
			readonly property string pluginFilename: PlasmaCalendarUtils.getPluginFilename(model.pluginPath)
			visible: Plasmoid.configuration.enabledCalendarPlugins.indexOf(pluginFilename) > -1
		}

		onObjectAdded: (index, object) => configModel.appendCategory(object)
		onObjectRemoved: (index, object) => configModel.removeCategory(object)
	}
}
