import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3

import "lib"
import "LocaleFuncs.js" as LocaleFuncs

Item {
	id: timerView

	property bool isSetTimerViewVisible: false

	implicitHeight: timerButtonView.height

	ColumnLayout {
		id: timerButtonView
		anchors.left: parent.left
		anchors.right: parent.right
		spacing: 4
		opacity: timerView.isSetTimerViewVisible ? 0 : 1
		visible: opacity > 0
		Behavior on opacity {
			NumberAnimation { duration: 200 }
		}

		onWidthChanged: {
			// console.log('timerButtonView.width', width)
			bottomRow.updatePresetVisibilities()
		}


		RowLayout {
			id: topRow
			spacing: 10
			property int contentsWidth: timerLabel.width + topRow.spacing + toggleButtonColumn.Layout.preferredWidth
			property bool contentsFit: timerButtonView.width >= contentsWidth

			PlasmaComponents3.ToolButton {
				id: timerLabel
				text: "0:00"
				icon.name: {
					if (timerModel.secondsLeft === 0) {
						return 'chronometer'
					} else if (timerModel.running) {
						return 'chronometer-pause'
					} else {
						return 'chronometer-start'
					}
				}
				icon.width: Kirigami.Units.iconSizes.large
				icon.height: Kirigami.Units.iconSizes.large
				font.pointSize: -1
				font.pixelSize: appletConfig.timerClockFontHeight
				Layout.alignment: Qt.AlignVCenter
				property string tooltip: {
					var s = ""
					if (timerModel.secondsLeft > 0) {
						if (timerModel.running) {
							s += i18n("Pause Timer")
						} else {
							s += i18n("Start Timer")
						}
						s += "\n"
					}
					s += i18n("Scroll to add to duration")
					return s
				}
				QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
				QQC2.ToolTip.text: tooltip
				QQC2.ToolTip.visible: hovered

				onClicked: {
					if (timerModel.running) {
						timerModel.pause()
					} else if (timerModel.secondsLeft > 0) {
						timerModel.runTimer()
					} else { // timerModel.secondsLeft == 0
						// ignore
					}
				}

				MouseArea {
					acceptedButtons: Qt.RightButton
					anchors.fill: parent

					// onClicked: (mouse) => contextMenu.show(mouse.x, mouse.y)
					onClicked: (mouse) => contextMenu.showBelow(timerLabel)
				}

				MouseArea {
					anchors.fill: parent
					acceptedButtons: Qt.MiddleButton

					onWheel: (wheel) => {
						var delta = wheel.angleDelta.y || wheel.angleDelta.x
						if (delta > 0) {
							timerModel.increaseDuration()
							timerModel.pause()
						} else if (delta < 0) {
							timerModel.decreaseDuration()
							timerModel.pause()
						}
					}
				}
			}

			ColumnLayout {
				id: toggleButtonColumn
				Layout.alignment: Qt.AlignBottom
				Layout.minimumWidth: sizingButton.height
				Layout.preferredWidth: sizingButton.implicitWidth

				PlasmaComponents3.ToolButton {
					id: sizingButton
					text: "Test"
					visible: false
				}

				PlasmaComponents3.ToolButton {
					id: timerRepeatsButton
					readonly property bool isChecked: Plasmoid.configuration.timerRepeats // New property to avoid checked=pressed theming.
					icon.name: isChecked ? 'media-playlist-repeat' : 'process-stop'
					text: topRow.contentsFit ? i18n("Repeat") : ""
					onClicked: {
						Plasmoid.configuration.timerRepeats = !isChecked
					}

					PlasmaComponents3.ToolTip.visible: hovered && !topRow.contentsFit
					PlasmaComponents3.ToolTip.text: i18n("Repeat")
					PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
				}

				PlasmaComponents3.ToolButton {
					id: timerSfxEnabledButton
					readonly property bool isChecked: Plasmoid.configuration.timerSfxEnabled // New property to avoid checked=pressed theming.
					icon.name: isChecked ? 'audio-volume-high' : 'dialog-cancel'
					text: topRow.contentsFit ? i18n("Sound") : ""
					onClicked: {
						Plasmoid.configuration.timerSfxEnabled = !isChecked
					}

					PlasmaComponents3.ToolTip.visible: hovered && !topRow.contentsFit
					PlasmaComponents3.ToolTip.text: i18n("Sound")
					PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
				}
			}

		}

		RowLayout {
			id: bottomRow
			spacing: 2

			// onWidthChanged: console.log('row.width', width)

			Repeater {
				id: defaultTimerRepeater
				model: timerModel.defaultTimers

				TimerPresetButton {
					text: LocaleFuncs.durationShortFormat(modelData.seconds)
					onClicked: timerModel.setDurationAndStart(modelData.seconds)
				}
			}

			function updatePresetVisibilities() {
				var availableWidth = timerButtonView.width
				var w = 0
				for (var i = 0; i < defaultTimerRepeater.count; i++) {
					var item = defaultTimerRepeater.itemAt(i)
					var itemWidth = item.width
					if (i > 0) {
						itemWidth += bottomRow.spacing
					}
					if (w + itemWidth <= availableWidth) {
						item.visible = true
					} else {
						item.visible = false
					}
					w += itemWidth
					// console.log('updatePresetVisibilities', i, item.Layout.minimumWidth, item.visible, itemWidth, availableWidth)
				}
			}
		}
	}

	Loader {
		id: setTimerViewLoader
		anchors.fill: parent
		source: "TimerInputView.qml"
		active: timerView.isSetTimerViewVisible
		opacity: timerView.isSetTimerViewVisible ? 1 : 0
		visible: opacity > 0
		Behavior on opacity {
			NumberAnimation { duration: 200 }
		}
	}


	Component.onCompleted: {
		timerView.forceActiveFocus()
	}

	Connections {
		target: timerModel
		function onSecondsLeftChanged() {
			timerLabel.text = timerModel.formatTimer(timerModel.secondsLeft)
		}
	}


	ContextMenu {
		id: contextMenu

		onPopulate: function(menu) {
			// Repeat
			var menuItem = menu.newMenuItem()
			menuItem.icon.name = Plasmoid.configuration.timerRepeats ? 'media-playlist-repeat' : 'process-stop'
			menuItem.text = i18n("Repeat")
			menuItem.triggered.connect(function() {
				timerRepeatsButton.clicked()
			})
			menu.addItem(menuItem)

			// Sound
			menuItem = menu.newMenuItem()
			menuItem.icon.name = Plasmoid.configuration.timerSfxEnabled ? 'audio-volume-high' : 'process-stop'
			menuItem.text = i18n("Sound")
			menuItem.triggered.connect(function() {
				timerSfxEnabledButton.clicked()
			})
			menu.addItem(menuItem)

			menu.addItem(menu.newSeperator())

			// Set Timer
			menuItem = menu.newMenuItem()
			menuItem.icon.name = 'chronometer'
			menuItem.text = i18n("Set Timer")
			menuItem.triggered.connect(function() {
				timerView.isSetTimerViewVisible = true
			})
			menu.addItem(menuItem)

			menu.addItem(menu.newSeperator())

			for (var i = 0; i < timerModel.defaultTimers.length; i++) {
				var presetItem = timerModel.defaultTimers[i]

				menuItem = menu.newMenuItem()
				menuItem.icon.name = 'chronometer'
				menuItem.text = LocaleFuncs.durationShortFormat(presetItem.seconds)
				menuItem.triggered.connect(timerModel.setDurationAndStart.bind(timerModel, presetItem.seconds))
				menu.addItem(menuItem)
			}
		}
	}
}
