// Version 5 - Plasma 6 compatible (uses cfg_* properties via ConfigPage)

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
	id: configSpinBox

	property string configKey: ''
	property var configValue: 0
	property alias from: spinBox.from
	property alias to: spinBox.to
	property alias stepSize: spinBox.stepSize
	property alias value: spinBox.value
	property string suffix: ""
	property string prefix: ""

	// Legacy aliases for compatibility
	property alias minimumValue: spinBox.from
	property alias maximumValue: spinBox.to

	property alias before: labelBefore.text
	property alias after: labelAfter.text

	// Find the ConfigPage ancestor
	property var configPage: null
	Component.onCompleted: {
		configPage = findConfigPage(configSpinBox)
		if (configPage && configKey) {
			var val = configPage.getConfigValue(configKey)
			if (typeof val !== "undefined") {
				configValue = val
				spinBox.value = val
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

	Label {
		id: labelBefore
		text: ""
		visible: text
	}

	SpinBox {
		id: spinBox

		value: configSpinBox.configValue
		onValueModified: serializeTimer.start()
		to: 2147483647
		from: 0
		editable: true

		textFromValue: function(value, locale) {
			return configSpinBox.prefix + value + configSpinBox.suffix
		}

		valueFromText: function(text, locale) {
			var s = text
			if (configSpinBox.prefix && s.startsWith(configSpinBox.prefix)) {
				s = s.substring(configSpinBox.prefix.length)
			}
			if (configSpinBox.suffix && s.endsWith(configSpinBox.suffix)) {
				s = s.substring(0, s.length - configSpinBox.suffix.length)
			}
			return parseInt(s) || 0
		}
	}

	Label {
		id: labelAfter
		text: ""
		visible: text
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
