// Version 2

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

CheckBox {
	id: configCheckBox

	property string configKey: ''
	checked: Plasmoid.configuration[configKey]
	onClicked: Plasmoid.configuration[configKey] = !Plasmoid.configuration[configKey]
}
