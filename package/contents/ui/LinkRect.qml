import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "lib"

Rectangle {
	id: linkRect
	width: implicitWidth
	height: implicitHeight
	implicitWidth: childrenRect.width
	implicitHeight: childrenRect.height
	property color backgroundColor: "transparent"
	property color backgroundHoverColor: appletConfig.agendaHoverBackground
	color: enabled && hovered ? backgroundHoverColor : backgroundColor
	property string tooltipMainText
	property string tooltipSubText
	property alias acceptedButtons: mouseArea.acceptedButtons
	property bool enabled: true
	readonly property alias hovered: mouseArea.containsMouse

	signal clicked(var mouse)
	signal leftClicked(var mouse)
	signal doubleClicked(var mouse)
	signal loadContextMenu(var contextMenu)

	MouseArea {
		id: mouseArea
		anchors.fill: parent
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: linkRect.enabled && containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
		enabled: linkRect.enabled
		onClicked: (mouse) => {
			mouse.accepted = false
			linkRect.clicked(mouse)
			if (!mouse.accepted) {
				if (mouse.button == Qt.LeftButton) {
					linkRect.leftClicked(mouse)
				} else if (mouse.button == Qt.RightButton) {
					contextMenu.show(mouse.x, mouse.y)
					mouse.accepted = true
				}
			}
		}
		onDoubleClicked: (mouse) => linkRect.doubleClicked(mouse)

		PlasmaComponents3.ToolTip {
			id: tooltip
			text: {
				var result = linkRect.tooltipMainText
				if (linkRect.tooltipSubText) {
					result += (result ? "\n" : "") + linkRect.tooltipSubText
				}
				return result
			}
			visible: mouseArea.containsMouse && text
			delay: Kirigami.Units.toolTipDelay
		}
	}

	ContextMenu {
		id: contextMenu
		onPopulate: linkRect.loadContextMenu(contextMenu)
	}
}
