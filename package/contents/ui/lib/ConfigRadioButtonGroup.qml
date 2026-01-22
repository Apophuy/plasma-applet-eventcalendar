// Version 6 - Plasma 6 compatible (uses cfg_* properties via ConfigPage)

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/*
** Example:
**
ConfigRadioButtonGroup {
	configKey: "appDescription"
	model: [
		{ value: "a", text: i18n("A") },
		{ value: "b", text: i18n("B") },
		{ value: "c", text: i18n("C") },
	]
}
*/

RowLayout {
	id: configRadioButtonGroup
	Layout.fillWidth: true
	default property alias _contentChildren: content.data
	property alias label: label.text

	ButtonGroup { id: radioButtonGroup }

	property string configKey: ''
	property var configValue: ""

	property alias model: buttonRepeater.model

	// Find the ConfigPage ancestor
	property var configPage: null
	Component.onCompleted: {
		configPage = findConfigPage(configRadioButtonGroup)
		if (configPage && configKey) {
			var val = configPage.getConfigValue(configKey)
			if (typeof val !== "undefined") {
				configValue = val
			}
		}
	}

	// Helper function to find ConfigPage
	function findConfigPage(item) {
		var p = item
		while (p) {
			if (p.getConfigValue && p.setConfigValue) {
				return p
			}
			p = p.parent
		}
		return null
	}

	//---
	Label {
		id: label
		visible: !!text
		Layout.alignment: Qt.AlignTop | Qt.AlignLeft
	}
	ColumnLayout {
		id: content

		Repeater {
			id: buttonRepeater
			RadioButton {
				visible: typeof modelData.visible !== "undefined" ? modelData.visible : true
				enabled: typeof modelData.enabled !== "undefined" ? modelData.enabled : true
				text: modelData.text
				checked: modelData.value === configRadioButtonGroup.configValue
				ButtonGroup.group: radioButtonGroup
				onClicked: {
					focus = true
					if (configRadioButtonGroup.configPage && configRadioButtonGroup.configKey) {
						configRadioButtonGroup.configPage.setConfigValue(configRadioButtonGroup.configKey, modelData.value)
						configRadioButtonGroup.configValue = modelData.value
					}
				}
			}
		}
	}
}
