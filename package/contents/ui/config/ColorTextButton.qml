import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Button {
	id: colorTextButton
	property int customPadding: Kirigami.Units.smallSpacing
	implicitWidth: customPadding + colorTextLabel.implicitWidth + customPadding
	implicitHeight: customPadding + colorTextLabel.implicitHeight + customPadding

	property alias label: colorTextLabel.text

	Label {
		id: colorTextLabel
		anchors.centerIn: parent
		color: Kirigami.Theme.buttonTextColor
	}
}
