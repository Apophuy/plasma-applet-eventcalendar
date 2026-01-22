import QtQuick

QtObject {
	id: base64Json
	property string configKey
	property var value: null
	property string configValue: ""

	// ConfigPage reference - must be set by parent
	property var configPage: null

	Component.onCompleted: {
		if (configPage && configKey) {
			var val = configPage.getConfigValue(configKey)
			if (typeof val !== "undefined") {
				configValue = val
				deserialize()
			}
		}
	}

	onConfigValueChanged: deserialize()

	function deserialize() {
		if (!configValue) {
			value = null
			return
		}
		try {
			var s = JSON.parse(Qt.atob(configValue))
			value = s
		} catch (e) {
			value = null
		}
	}

	function serialize() {
		var v = Qt.btoa(JSON.stringify(value))
		if (configPage && configKey) {
			configPage.setConfigValue(configKey, v)
			configValue = v
		}
	}
}
