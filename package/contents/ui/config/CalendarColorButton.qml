import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Button {
	id: root

	property string label
	property string value
	property string fallbackColor
	readonly property color displayColor: value || fallbackColor || Kirigami.Theme.textColor
	signal colorSelected(string colorValue)

	contentItem: RowLayout {
		spacing: Kirigami.Units.smallSpacing
		Rectangle {
			Layout.preferredWidth: Kirigami.Units.iconSizes.small
			Layout.preferredHeight: Kirigami.Units.iconSizes.small
			color: root.displayColor
			border.width: 1
			border.color: Kirigami.Theme.textColor
		}
		Label {
			text: root.label
			Layout.fillWidth: true
		}
	}

	onClicked: dialog.open()

	ColorDialog {
		id: dialog
		title: root.label
		selectedColor: root.displayColor
		onAccepted: root.colorSelected("" + selectedColor)
	}
}
