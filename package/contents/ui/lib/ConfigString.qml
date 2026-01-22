// Version 4 - Plasma 6 compatible (uses cfg_* properties via ConfigPage)

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
	id: configString
	Layout.fillWidth: true

	property string configKey: ''
	property alias value: configString.text
	property string defaultValue: ""

	// Find the ConfigPage ancestor
	property var configPage: null
	Component.onCompleted: {
		configPage = findConfigPage(configString)
		if (configPage && configKey) {
			var val = configPage.getConfigValue(configKey)
			if (typeof val !== "undefined") {
				text = val
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

	// Watch for external changes to the config value
	readonly property var configValue: configPage && configKey ? configPage.getConfigValue(configKey) : ""
	onConfigValueChanged: {
		if (!configString.focus && value != configValue) {
			value = configValue
		}
	}

	text: ""
	onTextChanged: serializeTimer.restart()

	ToolButton {
		icon.name: "edit-clear"
		onClicked: configString.value = defaultValue

		anchors.top: parent.top
		anchors.right: parent.right
		anchors.bottom: parent.bottom

		width: height
	}

	Timer { // throttle
		id: serializeTimer
		interval: 300
		onTriggered: {
			if (configPage && configKey) {
				configPage.setConfigValue(configKey, value)
			}
		}
	}
}
