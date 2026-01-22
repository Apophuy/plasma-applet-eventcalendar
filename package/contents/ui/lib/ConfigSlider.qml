// Version 4 - Plasma 6 compatible (uses cfg_* properties via ConfigPage)

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
	id: configSlider

	property string configKey: ''
	property var configValue: 0
	property alias from: slider.from
	property alias to: slider.to
	property alias stepSize: slider.stepSize
	property alias value: slider.value
	property bool live: false

	// Legacy aliases for compatibility
	property alias minimumValue: slider.from
	property alias maximumValue: slider.to

	property alias before: labelBefore.text
	property alias after: labelAfter.text

	Layout.fillWidth: true

	// Find the ConfigPage ancestor
	property var configPage: null
	Component.onCompleted: {
		configPage = findConfigPage(configSlider)
		if (configPage && configKey) {
			var val = configPage.getConfigValue(configKey)
			if (typeof val !== "undefined") {
				configValue = val
				slider.value = val
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

	Slider {
		id: slider
		Layout.fillWidth: configSlider.Layout.fillWidth

		value: configSlider.configValue
		onMoved: serializeTimer.start()
		to: 2147483647
		from: 0
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
