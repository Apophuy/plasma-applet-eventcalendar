// Version 6 - Plasma 6 compatible
// Config pages must use cfg_* properties for configuration access

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
	id: page
	default property alias _contentChildren: content.data

	// Helper functions for Config* components to access cfg_* properties
	// Components should call findConfigPage() to get the page reference
	function getConfigValue(key) {
		var propName = "cfg_" + key
		if (typeof page[propName] !== "undefined") {
			return page[propName]
		}
		console.warn("ConfigPage: property", propName, "not found")
		return undefined
	}

	function setConfigValue(key, value) {
		var propName = "cfg_" + key
		if (typeof page[propName] !== "undefined") {
			page[propName] = value
			return true
		}
		console.warn("ConfigPage: property", propName, "not found, cannot set value")
		return false
	}

	ColumnLayout {
		id: content
		anchors.left: parent.left
		anchors.right: parent.right
	}

	property alias showAppletVersion: appletVersionLoader.active
	Loader {
		id: appletVersionLoader
		active: false
		visible: active
		source: "AppletVersion.qml"
		anchors.right: parent.right
		anchors.bottom: parent.top
	}
}
