import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.workspace.calendar as PlasmaCalendar

import "../lib"
import "../calendars/PlasmaCalendarUtils.js" as PlasmaCalendarUtils

ConfigPage {
	id: page

	// cfg_* properties for KCM binding
	property bool cfg_debugging: false
	property var cfg_enabledCalendarPlugins: []
	property int cfg_eventsPollInterval: 20
	property int cfg_eventReminderMinutesBefore: 15
	property bool cfg_eventReminderNotificationEnabled: true
	property bool cfg_eventReminderSfxEnabled: false
	property string cfg_eventReminderSfxPath: ""
	property bool cfg_eventStartingNotificationEnabled: true
	property bool cfg_eventStartingSfxEnabled: true
	property string cfg_eventStartingSfxPath: ""

	// In Plasma 6, EventPluginsManager is no longer a singleton
	PlasmaCalendar.EventPluginsManager {
		id: eventPluginsManager
	}

	HeaderText {
		text: i18n("Event Calendar Plugins")
	}

	ConfigSection {
		CheckBox {
			text: i18n("ICalendar (.ics)")
			checked: true
			enabled: false
			visible: page.cfg_debugging
		}
		CheckBox {
			text: i18n("Google Calendar")
			checked: true
			enabled: false
		}
	}


	HeaderText {
		text: i18n("Plasma Calendar Plugins")
	}

	// From digitalclock's configCalendar.qml
	signal configurationChanged()
	ConfigSection {
		Repeater {
			id: calendarPluginsRepeater
			model: eventPluginsManager.model
			delegate: CheckBox {
				text: model.display
				checked: model.checked
				onClicked: {
					model.checked = checked // needed for model's setData to be called
					// page.configurationChanged()
					page.saveConfig()
				}
			}
		}
	}
	function saveConfig() {
		page.cfg_enabledCalendarPlugins = PlasmaCalendarUtils.pluginPathToFilenameList(eventPluginsManager.enabledPlugins)
	}
	Component.onCompleted: {
		PlasmaCalendarUtils.populateEnabledPluginsByFilename(eventPluginsManager, page.cfg_enabledCalendarPlugins)
	}

	HeaderText {
		text: i18n("Misc")
	}
	ColumnLayout {

		ConfigSpinBox {
			configKey: 'eventsPollInterval'
			before: i18n("Refresh events every: ")
			suffix: i18nc("Polling interval in minutes", "min")
			minimumValue: 5
			maximumValue: 90
		}
	}

	HeaderText {
		text: i18n("Notifications")
	}

	ConfigSection {
		ConfigNotification {
			label: i18n("Event Reminder")
			notificationEnabledKey: 'eventReminderNotificationEnabled'
			sfxEnabledKey: 'eventReminderSfxEnabled'
			sfxPathKey: 'eventReminderSfxPath'
			sfxPathDefaultValue: '/usr/share/sounds/Oxygen-Im-Nudge.ogg'

			RowLayout {
				spacing: 0
				Item { implicitWidth: parent.parent.indentWidth } // indent
				ConfigSpinBox {
					configKey: 'eventReminderMinutesBefore'
					suffix: i18nc("Polling interval in minutes", "min")
					minimumValue: 1
				}
			}
		}
	}

	ConfigSection {
		ConfigNotification {
			label: i18n("Event Starting")
			notificationEnabledKey: 'eventStartingNotificationEnabled'
			sfxEnabledKey: 'eventStartingSfxEnabled'
			sfxPathKey: 'eventStartingSfxPath'
			sfxPathDefaultValue: '/usr/share/sounds/Oxygen-Im-Nudge.ogg'
		}
	}

}
