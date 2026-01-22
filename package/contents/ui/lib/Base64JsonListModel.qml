import QtQuick

ListModel {
	id: listModel
	property alias configKey: base64Json.configKey

	// ConfigPage reference - will be found automatically
	property var configPage: null
	Component.onCompleted: {
		configPage = findConfigPage(listModel)
		base64Json.configPage = configPage
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

	property int oldCount: count
	property QtObject base64Json: Base64Json {
		id: base64Json
		value: []
		onValueChanged: {
			listModel.clear()
			if (value !== null) {
				for (var i = 0; i < value.length; i++) {
					var item = value[i]
					listModel.append(item)
				}
			}
		}
	}

	function addItem(obj) {
		append(obj)
		base64Json.value.push(obj)
		serialize()
	}

	function removeIndex(index) {
		remove(index)
		base64Json.value.splice(index, 1)
		serialize()
	}

	function setItemProperty(index, key, value) {
		setProperty(index, key, value)
		base64Json.value[index][key] = value
		serialize()
	}

	function serialize() {
		if (throttle > 0) {
			serializeTimer.restart()
		} else {
			base64Json.serialize()
		}
	}

	property alias throttle: serializeTimer.interval
	property Timer serializeTimer: Timer {
		id: serializeTimer
		interval: 200
		onTriggered: {
			base64Json.serialize()
		}
	}
}
