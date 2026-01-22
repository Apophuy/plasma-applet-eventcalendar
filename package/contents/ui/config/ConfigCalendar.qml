import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../lib"

ConfigPage {
	id: page

	// cfg_* properties for KCM binding
	property bool cfg_widgetShowCalendar: true
	property string cfg_monthCurrentCustomTitleFormat: ""
	property bool cfg_monthShowBorder: false
	property bool cfg_monthShowWeekNumbers: false
	property bool cfg_monthHighlightCurrentDayWeek: true
	property int cfg_firstDayOfWeek: -1
	property string cfg_monthEventBadgeType: "theme"
	property string cfg_monthTodayStyle: "theme"
	property double cfg_monthCellRadius: 0
	property string cfg_monthDayDoubleClick: "GoogleCalWeb"
	property int cfg_monthHeightSingleColumn: 300

	ConfigCheckBox {
		configKey: 'widgetShowCalendar'
		text: i18n("Show calendar")
	}

	ConfigSection {
		ConfigRadioButtonGroup {
			id: clickDateGroup
			label: i18n("Click Date:")
			model: [
				{ value: 'scrollToAgenda', text: i18n("Scroll to event in Agenda") }
			]
		}
	}

	ConfigSection {
		ConfigRadioButtonGroup {
			id: doubleClickDateGroup
			label: i18n("Double-click on Date:")
			configKey: 'monthDayDoubleClick'
			model: [
				{ value: 'GoogleCalWeb', text: i18n("New Google Calendar Event (Web Browser)")  },
				{ value: 'DoNothing', text: i18n("Do Nothing") },
			]
		}
	}

	HeaderText {
		text: i18n("Style")
	}
	ConfigSection {
		RowLayout {
			Layout.fillWidth: true
			Label {
				text: i18n("Current Month Title:")
			}
			ConfigString {
				id: monthCurrentCustomTitleFormat
				configKey: 'monthCurrentCustomTitleFormat'
				placeholderText: i18nc("calendar title format for current month", "MMMM d, yyyy")
			}
			Label {
				text: Qt.formatDateTime(new Date(), monthCurrentCustomTitleFormat.value)
			}
		}

		ConfigCheckBox {
			configKey: 'monthShowBorder'
			text: i18n("Show Borders")
		}
		ConfigCheckBox {
			configKey: 'monthShowWeekNumbers'
			text: i18n("Show Week Numbers")
		}
		ConfigCheckBox {
			configKey: 'monthHighlightCurrentDayWeek'
			text: i18n("Highlight Current Day / Week")
		}
		RowLayout {
			Label {
				text: i18n("First day of week:")
			}
			ComboBox {
				// [-1, 0, 1, 2, 3, 4, 5, 6] // Default = -1, 0..6 = Sun..Sat
				model: ListModel {}
				textRole: "text"

				Component.onCompleted: {
					model.append({
						text: i18n("Default"),
						value: -1,
					})
					for (var i = 0; i < 7; i++) {
						model.append({
							text: Qt.locale().dayName(i),
							value: i,
						})
					}

					// The firstDayOfWeek enum starts at -1 instead of 0
					currentIndex = page.cfg_firstDayOfWeek + 1
					currentIndexChanged.connect(function(){
						page.cfg_firstDayOfWeek = currentIndex - 1
					})
				}
			}
		}
		ConfigRadioButtonGroup {
			configKey: 'monthEventBadgeType'
			label: i18n("Event Badge:")
			model: [
				{ value: 'theme', text: i18n("Theme") },
				{ value: 'dots', text: i18n("Dots (3 Maximum)") },
				{ value: 'bottomBar', text: i18n("Bottom Bar (Event Color)") },
				{ value: 'bottomBarHighlight', text: i18n("Bottom Bar (Highlight)") },
				{ value: 'count', text: i18n("Count") },
			]
		}

		ConfigSlider {
			configKey: 'monthCellRadius'
			minimumValue: 0
			maximumValue: 1
			before: i18n("Radius:")
			after: "" + Math.round(value*100) + "%"
			Layout.fillWidth: false
		}

		ConfigRadioButtonGroup {
			id: selectedStyleGroup
			label: i18n("Selected:")
			model: [
				{ value: 'default', text: i18n("Solid Color (Highlight)") },
			]
		}

		ConfigRadioButtonGroup {
			configKey: 'monthTodayStyle'
			label: i18n("Today:")
			model: [
				{ value: 'theme', text: i18n("Solid Color (Inverted)") },
				{ value: 'bigNumber', text: i18n("Big Number") },
			]
		}
	}

}
