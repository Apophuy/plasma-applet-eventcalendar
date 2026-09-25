// Version 7 - Plasma 6 compatible (uses cfg_* properties via ConfigPage)

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import org.kde.kirigami as Kirigami

RowLayout {
	id: configColor
	spacing: 2
	// Layout.fillWidth: true
	Layout.maximumWidth: 300

	property alias label: label.text
	property alias labelColor: label.color
	property alias horizontalAlignment: label.horizontalAlignment
	// showAlphaChannel removed in Qt 6 ColorDialog - use options instead
	property bool showAlphaChannel: true
	property color buttonOutlineColor: {
		if (valueColor.r + valueColor.g + valueColor.b > 0.5) {
			return "#BB000000" // Black outline
		} else {
			return "#BBFFFFFF" // White outline
		}
	}

	property TextField textField: textField
	property ColorDialog dialog: dialog

	property string configKey: ''
	property string defaultColor: ''
	property string value: ""

	readonly property color defaultColorValue: defaultColor
	readonly property color valueColor: {
		if (value == '' && defaultColor) {
			return defaultColor
		} else if (value == '') {
			return "#000000"
		} else {
			return value
		}
	}

	// Find the ConfigPage ancestor
	property var configPage: null
	Component.onCompleted: {
		configPage = findConfigPage(configColor)
		if (configPage && configKey) {
			var val = configPage.getConfigValue(configKey)
			if (typeof val !== "undefined") {
				value = val
				textField.text = val
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

	onValueChanged: {
		if (!textField.activeFocus) {
			textField.text = configColor.value
		}
		if (configPage && configKey) {
			if (value == defaultColorValue) {
				configPage.setConfigValue(configKey, "")
			} else {
				configPage.setConfigValue(configKey, value)
			}
		}
	}

	function setValue(newColor) {
		textField.text = newColor
	}

	Label {
		id: label
		text: "Label"
		Layout.fillWidth: horizontalAlignment == Text.AlignRight
		horizontalAlignment: Text.AlignLeft
	}

	MouseArea {
		id: mouseArea
		Layout.preferredWidth: textField.height
		Layout.preferredHeight: textField.height
		hoverEnabled: true

		onClicked: dialog.open()

		Rectangle {
			anchors.fill: parent
			color: configColor.valueColor
			border.width: 2
			border.color: parent.containsMouse ? Kirigami.Theme.highlightColor : buttonOutlineColor
		}
	}

	TextField {
		id: textField
		placeholderText: defaultColor ? defaultColor : "#AARRGGBB"
		Layout.fillWidth: label.horizontalAlignment == Text.AlignLeft
		onTextChanged: {
			// Make sure the text is:
			//   Empty (use default)
			//   or #123 or #112233 or #11223344 before applying the color.
			if (text.length === 0
				|| (text.indexOf('#') === 0 && (text.length == 4 || text.length == 7 || text.length == 9))
			) {
				configColor.value = text
			}
		}
	}

	ColorDialog {
		id: dialog
		modality: Qt.WindowModal
		title: configColor.label
		options: ColorDialog.ShowAlphaChannel
		selectedColor: configColor.valueColor
		onAccepted: {
			configColor.value = selectedColor
		}
	}
}
