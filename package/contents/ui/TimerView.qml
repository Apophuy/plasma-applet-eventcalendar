import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3

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
			spacing: 10 * Kirigami.Units.devicePixelRatio
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

					PlasmaExtras.ToolTip {
						anchors.fill: parent
						enabled: !topRow.contentsFit
						mainText: i18n("Repeat")
					}
				}

				PlasmaComponents3.ToolButton {
					id: timerSfxEnabledButton
					readonly property bool isChecked: Plasmoid.configuration.timerSfxEnabled // New property to avoid checked=pressed theming.
					icon.name: isChecked ? 'audio-volume-high' : 'dialog-cancel'
					text: topRow.contentsFit ? i18n("Sound") : ""
					onClicked: {
						Plasmoid.configuration.timerSfxEnabled = !isChecked
					}

					PlasmaExtras.ToolTip {
						anchors.fill: parent
						enabled: !topRow.contentsFit
						mainText: i18n("Sound")
					}
				}
			}

		}

		RowLayout {
			id: bottomRow
			spacing: Math.floor(2 * Kirigami.Units.devicePixelRatio)

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
		onSecondsLeftChanged: {
			timerLabel.text = timerModel.formatTimer(timerModel.secondsLeft)
		}
	}


	// Context menu using QtQuick.Controls Menu for Plasma 6
	QQC2.Menu {
		id: contextMenu

		function clearMenuItems() {
			while (contextMenu.count > 0) {
				contextMenu.removeItem(contextMenu.itemAt(0))
			}
		}

		function newSeperator() {
			return Qt.createQmlObject("import QtQuick.Controls as QQC2; QQC2.MenuSeparator {}", contextMenu)
		}
		function newMenuItem() {
			return Qt.createQmlObject("import QtQuick.Controls as QQC2; QQC2.MenuItem {}", contextMenu)
		}

		function loadDynamicActions() {
			contextMenu.clearMenuItems()

			// Repeat
			var menuItem = newMenuItem()
			menuItem.icon.name = Plasmoid.configuration.timerRepeats ? 'media-playlist-repeat' : 'process-stop'
			menuItem.text = i18n("Repeat")
			menuItem.triggered.connect(function() {
				timerRepeatsButton.clicked()
			})
			contextMenu.addItem(menuItem)

			// Sound
			menuItem = newMenuItem()
			menuItem.icon.name = Plasmoid.configuration.timerSfxEnabled ? 'audio-volume-high' : 'process-stop'
			menuItem.text = i18n("Sound")
			menuItem.triggered.connect(function() {
				timerSfxEnabledButton.clicked()
			})
			contextMenu.addItem(menuItem)

			//
			contextMenu.addItem(newSeperator())

			// Set Timer
			menuItem = newMenuItem()
			menuItem.icon.name = 'chronometer'
			menuItem.text = i18n("Set Timer")
			menuItem.triggered.connect(function() {
				timerView.isSetTimerViewVisible = true
			})
			contextMenu.addItem(menuItem)

			//
			contextMenu.addItem(newSeperator())

			for (var i = 0; i < timerModel.defaultTimers.length; i++) {
				var presetItem = timerModel.defaultTimers[i]

				menuItem = newMenuItem()
				menuItem.icon.name = 'chronometer'
				menuItem.text = LocaleFuncs.durationShortFormat(presetItem.seconds)
				menuItem.triggered.connect(timerModel.setDurationAndStart.bind(timerModel, presetItem.seconds))
				contextMenu.addItem(menuItem)
			}

		}

		function show(x, y) {
			loadDynamicActions()
			contextMenu.popup(x, y)
		}

		function showBelow(item) {
			loadDynamicActions()
			contextMenu.popup(item, 0, item.height)
		}
	}
}
