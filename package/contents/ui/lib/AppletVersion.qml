import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Item {
	implicitWidth: label.implicitWidth
	implicitHeight: label.implicitHeight

	property string version: Plasmoid.metaData.version || "?"

	Label {
		id: label
		text: i18n("<b>Version:</b> %1", version)
	}
}
