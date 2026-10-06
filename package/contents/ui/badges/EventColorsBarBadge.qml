import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Item {
	id: eventColorsBarColor

	Item {
		anchors.left: eventColorsBarColor.left
		anchors.right: eventColorsBarColor.right
		anchors.bottom: eventColorsBarColor.bottom
		height: Math.min(parent.height / 3, Math.max(1, dayStyle.calendarBars.length) * parent.height / 8)
		
		property bool usePadding: !Plasmoid.configuration.monthShowBorder
		anchors.leftMargin: usePadding ? parent.width/8 : 0
		anchors.rightMargin: usePadding ? parent.width/8 : 0
		anchors.bottomMargin: usePadding ? parent.height/16 : 0

		Column {
			anchors.fill: parent
			spacing: 0

			Repeater {
				model: dayStyle.useHightlightColor
					? [{ color: "" + Kirigami.Theme.highlightColor }]
					: dayStyle.calendarBars

				Rectangle {
					width: parent.width
					height: parent.height / Math.max(1, dayStyle.calendarBars.length)
					color: modelData.color

					Rectangle {
						anchors.fill: parent
						color: "transparent"
						border.width: 1
						border.color: Kirigami.Theme.backgroundColor
						opacity: 0.5
					}
				}
				
			}
		}
	}
}
