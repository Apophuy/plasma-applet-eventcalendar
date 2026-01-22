import QtQuick

// NOTE: This component is deprecated in Plasma 6.
// Configuration pages cannot access Plasmoid.configuration directly.
// Use cfg_* properties passed from the parent ConfigPage instead.

QtObject {
	id: obj
	property string configKey: ''
	property string configValue: '' // Must be set externally
	property var value: null
	property var defaultValue: ({}) // Empty Map

	function serialize() {
		// No-op in Plasma 6 - parent must handle this
		console.warn("ConfigSerializedString is deprecated in Plasma 6")
	}

	function deserialize() {
		value = configValue ? JSON.parse(Qt.atob(configValue)) : defaultValue
	}

	onConfigKeyChanged: deserialize()
	onConfigValueChanged: deserialize()
	onValueChanged: {
		if (value === null) {
			return // 99% of the time this is unintended
		}
		serialize()
	}
}
