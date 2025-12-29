// Version 2

import QtQuick
import QtQuick.Controls 1.0
import QtQuick.Layouts

import ".."

CheckBox {
	id: configCheckBox

	property string configKey: ''
	checked: Plasmoid.configuration[configKey]
	onClicked: Plasmoid.configuration[configKey] = !Plasmoid.configuration[configKey]
}
