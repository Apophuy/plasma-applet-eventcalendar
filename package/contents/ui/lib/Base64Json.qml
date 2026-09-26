import QtQuick
import org.kde.plasma.plasmoid

QtObject {
	id: base64Json
	property string configKey
	property var value: null
	property string configValue: ""

	// ConfigPage reference - must be set by parent
	property var configPage: null

	Component.onCompleted: loadConfig()
	onConfigPageChanged: loadConfig()

	function loadConfig() {
		if (!configKey) {
			return
		}
		var val
		if (configPage) {
			val = configPage.getConfigValue(configKey)
		} else {
			val = Plasmoid.configuration[configKey]
		}
		configValue = typeof val === "undefined" ? "" : val
		deserialize()
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
		} else if (configKey) {
			Plasmoid.configuration[configKey] = v
		}
		configValue = v
	}
}
