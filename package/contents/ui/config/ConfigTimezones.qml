import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.private.digitalclock as DigitalClock

import ".."
import "../lib"

// Mostly copied from digitalclock - updated for Qt 6
ConfigPage {
	id: page

	// cfg_* properties for KCM binding
	property var cfg_selectedTimeZones: []
	property bool cfg_displayTimezoneAsCode: true

	function translatedLabel(sourceText, localTranslation) {
		return localTranslation === sourceText
			? i18nd("plasma_applet_org.kde.plasma.digitalclock", sourceText)
			: localTranslation
	}

	DigitalClock.TimeZoneModel {
		id: timeZoneModel

		selectedTimeZones: page.cfg_selectedTimeZones
		onSelectedTimeZonesChanged: page.cfg_selectedTimeZones = selectedTimeZones
	}

	MessageWidget {
		id: messageWidget
	}

	TextField {
		id: filter
		Layout.fillWidth: true
		placeholderText: page.translatedLabel("Search Time Zones", i18n("Search Time Zones"))
	}

	// Header row
	RowLayout {
		Layout.fillWidth: true
		spacing: 10

		Label {
			text: page.translatedLabel("City", i18n("City"))
			Layout.preferredWidth: 150
			font.bold: true
		}
		Label {
			text: page.translatedLabel("Region", i18n("Region"))
			Layout.preferredWidth: 150
			font.bold: true
		}
		Label {
			text: page.translatedLabel("Comment", i18n("Comment"))
			Layout.fillWidth: true
			font.bold: true
		}
		Label {
			text: i18n("Tooltip")
			Layout.preferredWidth: 80
			font.bold: true
			horizontalAlignment: Text.AlignHCenter
		}
	}

	Rectangle {
		Layout.fillWidth: true
		Layout.preferredHeight: 1
		color: "gray"
	}

	ListView {
		id: timeZoneView
		Layout.fillWidth: true
		Layout.fillHeight: true
		clip: true

		model: DigitalClock.TimeZoneFilterProxy {
			sourceModel: timeZoneModel
			filterString: filter.text
		}

		delegate: RowLayout {
			width: timeZoneView.width
			height: 30
			spacing: 10

			Label {
				text: model.city || ""
				Layout.preferredWidth: 150
				elide: Text.ElideRight
			}
			Label {
				text: model.region === "Local"
					? page.translatedLabel("Local", i18n("Local"))
					: model.region || ""
				Layout.preferredWidth: 150
				elide: Text.ElideRight
			}
			Label {
				text: model.comment || ""
				Layout.fillWidth: true
				elide: Text.ElideRight
			}
			CheckBox {
				id: checkBox
				Layout.preferredWidth: 80
				Layout.alignment: Qt.AlignHCenter
				checked: model.checked

				function setValue(checked) {
					if (!checked && model.region == "Local") {
						messageWidget.warn(i18n("Cannot deselect Local time from the tooltip"))
					} else {
						model.checked = checked
					}
					checkBox.checked = Qt.binding(function(){ return model.checked })
				}

				onClicked: checkBox.setValue(checked)
			}
		}

		ScrollBar.vertical: ScrollBar {}
	}


	ButtonGroup { id: timezoneDisplayType }
	RowLayout {
		Label {
			text: page.translatedLabel("Display time zone as:", i18n("Display time zone as:"))
		}

		RadioButton {
			id: timezoneCityRadio
			text: page.translatedLabel("Time zone city", i18n("Time zone city"))
			ButtonGroup.group: timezoneDisplayType
			checked: !page.cfg_displayTimezoneAsCode
			onClicked: page.cfg_displayTimezoneAsCode = false
		}

		RadioButton {
			id: timezoneCodeRadio
			text: page.translatedLabel("Time zone code", i18n("Time zone code"))
			ButtonGroup.group: timezoneDisplayType
			checked: page.cfg_displayTimezoneAsCode
			onClicked: page.cfg_displayTimezoneAsCode = true
		}
	}
}
