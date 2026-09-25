import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import ".."
import "../lib"

ConfigPage {
	id: page

	// cfg_* properties for KCM binding
	property bool cfg_widgetShowAgenda: true
	property int cfg_agendaFontSize: 0
	property bool cfg_agendaWeatherShowIcon: true
	property int cfg_agendaWeatherIconHeight: 24
	property bool cfg_agendaWeatherShowText: false
	property bool cfg_agendaWeatherOnRight: false
	property bool cfg_agendaBreakupMultiDayEvents: false
	property bool cfg_agendaNewEventRememberCalendar: true
	property string cfg_agendaInProgressColor: ""
	property int cfg_agendaDaySpacing: 20
	property int cfg_agendaEventSpacing: 10
	property int cfg_agendaMaxDescriptionLines: 5
	property bool cfg_agendaShowEventDescription: true
	property bool cfg_agendaShowEventHangoutLink: true
	property bool cfg_agendaCondensedAllDayEvent: true
	property bool cfg_showOutlines: true

	property int indentWidth: 24

	ConfigCheckBox {
		configKey: 'widgetShowAgenda'
		text: i18n("Show agenda")
	}

	ConfigSection {
		ConfigSpinBox {
			configKey: 'agendaFontSize'
			before: i18n("Font Size:")
			suffix: i18n("px")
			after: i18n(" (0px = <b>System Settings > Fonts > General</b>)")
		}
	}

	ConfigSection {
		RowLayout {
			ConfigCheckBox {
				configKey: 'agendaWeatherShowIcon'
				checked: true
				text: i18n("Weather Icon")
			}
			ConfigSlider {
				configKey: 'agendaWeatherIconHeight'
				minimumValue: 12
				maximumValue: 48
				stepSize: 1
				after: '' + value + i18n("px")
				Layout.fillWidth: false
			}
		}

		RowLayout {
			Text { width: indentWidth } // Indent
			ConfigCheckBox {
				configKey: 'showOutlines'
				text: i18n("Icon Outline")
			}
		}

		ConfigCheckBox {
			configKey: 'agendaWeatherShowText'
			text: i18n("Weather Text")
		}

		ConfigRadioButtonGroup {
			configKey: 'agendaWeatherOnRight'
			label: i18n("Position:")
			model: [
				{ value: false, text: i18n("Left") },
				{ value: true, text: i18n("Right") },
			]
		}

		ConfigRadioButtonGroup {
			id: clickWeatherGroup
			label: i18n("Click Weather:")
			model: [
				{ value: 'openForecast', text: i18n("Open City Forecast In Browser") },
			]
		}
	}

	ConfigSection {
		ConfigRadioButtonGroup {
			id: clickDateGroup
			label: i18n("Click Date:")
			model: [
				{ value: 'browser', text: i18n("Open New Event In Browser"), enabled: false },
				{ value: 'form', text: i18n("Open New Event Form") },
			]
		}
	}

	ConfigSection {
		RowLayout {
			ConfigCheckBox {
				configKey: 'agendaShowEventDescription'
				text: i18n("Event description")
			}
			// ConfigSpinBox {
			// 	configKey: 'agendaMaxDescriptionLines'
			// 	after: i18n("lines")
			// }
		}
		ConfigCheckBox {
			configKey: 'agendaCondensedAllDayEvent'
			text: i18n("Hide 'All Day' text")
		}
		ConfigCheckBox {
			configKey: 'agendaShowEventHangoutLink'
			text: i18n("Google Hangouts link")
		}
		ConfigRadioButtonGroup {
			id: clickEventGroup
			label: i18n("Click Event:")
			model: [
				{ value: 'browser', text: i18n("Open Event In Browser") },
			]
		}
	}


	ConfigSection {
		ConfigRadioButtonGroup {
			configKey: 'agendaBreakupMultiDayEvents'
			label: i18n("Show multi-day events:")
			model: [
				{ value: true, text: i18n("On all days") },
				{ value: false, text: i18n("Only on the first and current day") },
			]
		}
	}

	ConfigSection {
		ConfigCheckBox {
			configKey: 'agendaNewEventRememberCalendar'
			text: i18n("Remember selected calendar in New Event Form")
		}
	}

	ConfigSection {
		title: i18n("Current Month")

		CheckBox {
			enabled: false
			checked: true
			text: i18n("Always show next 14 days")
		}
		CheckBox {
			enabled: false
			checked: false
			text: i18n("Hide completed events")
		}
		CheckBox {
			enabled: false
			checked: true
			text: i18n("Show all events of the current day (including completed events)")
		}
	}

	AppletConfig { id: config }
	ColorGrid {
		title: i18n("Colors")

		ConfigColor {
			configKey: 'agendaInProgressColor'
			label: i18n("In Progress")
			defaultColor: config.agendaInProgressColorDefault
		}
	}

	ConfigSection {
		ConfigSpinBox {
			configKey: 'agendaDaySpacing'
			before: i18n("Day Spacing:")
			suffix: i18n("px")
		}
		ConfigSpinBox {
			configKey: 'agendaEventSpacing'
			before: i18n("Event Spacing:")
			suffix: i18n("px")
		}
	}

}
