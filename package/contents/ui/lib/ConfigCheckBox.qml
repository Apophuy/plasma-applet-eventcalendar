// Version 4 - Plasma 6 compatible (uses cfg_* properties via ConfigPage)

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

CheckBox {
	id: configCheckBox

	property string configKey: ''
	readonly property var configValue: configPage && configKey
		? configPage.getConfigValue(configKey)
		: false
	checked: !!configValue

	// Find the ConfigPage ancestor
	property var configPage: null
	Component.onCompleted: {
		configPage = findConfigPage(configCheckBox)
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

	onClicked: {
		if (configPage && configKey) {
			configPage.setConfigValue(configKey, checked)
		}
	}
}
