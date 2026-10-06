import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import ".."
import "../lib"

ConfigPage {
	id: page

	property string cfg_calendarAppearanceOverrides: ""
	property string cfg_calendarList: ""
	property string cfg_calendarIdList: ""
	property string cfg_yandexAccounts: ""
	property string cfg_icalCalendarList: ""
	property bool initialized: false

	ListModel { id: calendarsModel }

	function decode(value, fallback) {
		if (!value) return fallback
		try {
			return JSON.parse(Qt.atob(value))
		} catch (error) {
			return fallback
		}
	}

	function overrideList() {
		return decode(cfg_calendarAppearanceOverrides, [])
	}

	function overrideFor(key) {
		var list = overrideList()
		for (var i = 0; i < list.length; i++) {
			if (list[i].key === key) return list[i]
		}
		return { key: key, backgroundColor: "", foregroundColor: "" }
	}

	function appendCalendar(key, provider, account, calendar, active) {
		var appearance = overrideFor(key)
		calendarsModel.append({
			calendarKey: key,
			providerName: provider,
			accountName: account || "",
			calendarName: calendar.summary || calendar.name || i18n("Calendar"),
			sourceBackgroundColor: calendar.backgroundColor || "" + Kirigami.Theme.highlightColor,
			sourceForegroundColor: calendar.foregroundColor || "" + Kirigami.Theme.textColor,
			backgroundColor: appearance.backgroundColor || "",
			foregroundColor: appearance.foregroundColor || "",
			active: active,
		})
	}

	function rebuild() {
		calendarsModel.clear()
		var googleIds = cfg_calendarIdList ? cfg_calendarIdList.split(",") : []
		var googleCalendars = decode(cfg_calendarList, [])
		for (var i = 0; i < googleCalendars.length; i++) {
			var google = googleCalendars[i]
			var selected = googleIds.indexOf(google.id) >= 0 || (google.primary && googleIds.indexOf("primary") >= 0)
			appendCalendar("GoogleCalendar:" + google.id, i18n("Google Calendar"), "", google, selected)
		}

		var accounts = decode(cfg_yandexAccounts, [])
		for (var a = 0; a < accounts.length; a++) {
			var account = accounts[a]
			var calendars = account.calendars || []
			for (var y = 0; y < calendars.length; y++) {
				var yandexActive = account.enabled !== false && calendars[y].selected !== false
				appendCalendar("YandexCalendar:" + calendars[y].id, i18n("Yandex Calendar"), account.name || account.login, calendars[y], yandexActive)
			}
		}

		var icalCalendars = decode(cfg_icalCalendarList, [])
		for (var c = 0; c < icalCalendars.length; c++) {
			var ical = icalCalendars[c]
			if (ical.url) {
				var id = ical.id || "ical:" + c
				appendCalendar("ical:" + id, i18n("iCalendar"), "", ical, ical.show !== false)
			}
		}
		initialized = true
	}

	function setOverride(key, propertyName, value) {
		var list = overrideList()
		var found = false
		for (var i = 0; i < list.length; i++) {
			if (list[i].key === key) {
				list[i][propertyName] = value
				found = true
				break
			}
		}
		if (!found) {
			var item = { key: key, backgroundColor: "", foregroundColor: "" }
			item[propertyName] = value
			list.push(item)
		}
		cfg_calendarAppearanceOverrides = Qt.btoa(JSON.stringify(list))
		for (var row = 0; row < calendarsModel.count; row++) {
			if (calendarsModel.get(row).calendarKey === key) {
				calendarsModel.setProperty(row, propertyName, value)
				break
			}
		}
	}

	function resetOverride(key) {
		var list = overrideList().filter(function(item) { return item.key !== key })
		cfg_calendarAppearanceOverrides = Qt.btoa(JSON.stringify(list))
		for (var row = 0; row < calendarsModel.count; row++) {
			if (calendarsModel.get(row).calendarKey === key) {
				calendarsModel.setProperty(row, "backgroundColor", "")
				calendarsModel.setProperty(row, "foregroundColor", "")
				break
			}
		}
	}

	Component.onCompleted: rebuild()
	onCfg_calendarListChanged: if (initialized) rebuild()
	onCfg_calendarIdListChanged: if (initialized) rebuild()
	onCfg_yandexAccountsChanged: if (initialized) rebuild()
	onCfg_icalCalendarListChanged: if (initialized) rebuild()

	HeaderText { text: i18n("Connected calendars") }

	Label {
		Layout.fillWidth: true
		Layout.preferredWidth: 0
		wrapMode: Text.Wrap
		text: i18n("Choose event and text colors independently for every connected calendar. Resetting a calendar restores the color supplied by its service.")
	}

	Label {
		visible: calendarsModel.count === 0
		text: i18n("No connected calendars.")
		opacity: 0.7
	}

	Repeater {
		model: calendarsModel
		delegate: GroupBox {
			required property int index
			property var calendarData: calendarsModel.get(index)
			Layout.fillWidth: true
			title: calendarData.calendarName
			opacity: calendarData.active ? 1 : 0.65

			ColumnLayout {
				anchors.fill: parent
				Label {
					text: calendarData.accountName
						? calendarData.providerName + " — " + calendarData.accountName
						: calendarData.providerName
					opacity: 0.7
				}
				ColumnLayout {
					Layout.fillWidth: true
					CalendarColorButton {
						Layout.fillWidth: true
						label: i18n("Event color")
						value: calendarData.backgroundColor
						fallbackColor: calendarData.sourceBackgroundColor
						onColorSelected: function(value) { page.setOverride(calendarData.calendarKey, "backgroundColor", value) }
					}
					CalendarColorButton {
						Layout.fillWidth: true
						label: i18n("Text color")
						value: calendarData.foregroundColor
						fallbackColor: calendarData.sourceForegroundColor
						onColorSelected: function(value) { page.setOverride(calendarData.calendarKey, "foregroundColor", value) }
					}
					Button {
						Layout.alignment: Qt.AlignRight
						text: i18n("Use source colors")
						icon.name: "edit-undo"
						enabled: !!calendarData.backgroundColor || !!calendarData.foregroundColor
						onClicked: page.resetOverride(calendarData.calendarKey)
					}
				}
			}
		}
	}
}
