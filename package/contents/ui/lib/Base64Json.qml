import QtQuick

QtObject {
	property string configKey
	readonly property string configValue: Plasmoid.configuration[configKey]
	property var value: null

	onConfigValueChanged: deserialize()

	function deserialize() {
		var s = JSON.parse(Qt.atob(configValue))
		value = s
	}

	function serialize() {
		var v = Qt.btoa(JSON.stringify(value))
		Plasmoid.configuration[configKey] = v
	}
}
