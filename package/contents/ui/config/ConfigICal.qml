import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import ".."
import "../lib"

ConfigPage {
	id: page

	// cfg_* properties for KCM binding
	property string cfg_icalCalendarList: ""

	Base64JsonListModel {
		id: calendarsModel
		configKey: 'icalCalendarList'
		configPage: page

		function addCalendar() {
			addItem({
				id: 'ical-' + Date.now() + '-' + Math.floor(Math.random() * 1000000),
				url: '',
				name: i18n('Calendar'),
				backgroundColor: '' + Kirigami.Theme.highlightColor,
				foregroundColor: '',
				show: true,
				isReadOnly: true,
			})
		}
	}

	RowLayout {
		HeaderText {
			text: i18n("Calendars")
		}
		Button {
			icon.name: "resource-calendar-insert"
			text: i18n("Add Calendar")
			onClicked: calendarsModel.addCalendar()
		}
	}

	Label {
		Layout.fillWidth: true
		Layout.preferredWidth: 0
		wrapMode: Text.Wrap
		text: i18n("Add read-only calendars from local .ics files or web links. Changes made in the source calendar will appear here after the next update.")
	}

	ColumnLayout {
		Layout.fillWidth: true
		spacing: 20 // x4 the default spacing (5px)

		Repeater {
			model: calendarsModel
			delegate: RowLayout {
				spacing: 0

				CheckBox {
					Layout.preferredHeight: labelTextField.height
					Layout.preferredWidth: height
					Layout.alignment: Qt.AlignTop
					checked: show

					onClicked: calendarsModel.setItemProperty(index, 'show', checked)
				}
				ColumnLayout {
					RowLayout {
						Rectangle {
							Layout.preferredHeight: labelTextField.height
							Layout.preferredWidth: height
							color: model.backgroundColor
						}
						TextField {
							id: labelTextField
							Layout.fillWidth: true
							text: model.name
							placeholderText: i18n("Calendar Label")
							onTextEdited: calendarsModel.setItemProperty(index, 'name', text)
						}
						Button {
							icon.name: "trash-empty"
							onClicked: calendarsModel.removeIndex(index)
						}
					}
					RowLayout {
						TextField {
							id: calendarUrlField
							Layout.fillWidth: true
							text: model.url
							placeholderText: i18n("Local .ics file or web link")
							onTextEdited: calendarsModel.setItemProperty(index, 'url', text)
						}

						Button {
							icon.name: "folder-open"
							text: i18n("Browse")
							onClicked: {
								filePicker.open()
							}

							FileDialog {
								id: filePicker

								nameFilters: [ i18n("iCalendar (*.ics)") ]

								onAccepted: {
									calendarsModel.setItemProperty(index, 'url', selectedFile.toString())
								}
							}
						}
					}
				}
			}
		}
	}
}
