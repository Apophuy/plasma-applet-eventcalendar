import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls

import ".."
import "../lib"
import "../lib/Requests.js" as Requests

Dialog {
	id: chooseCityDialog
	title: i18n("Select city")
	parent: Overlay.overlay
	modal: true
	standardButtons: Dialog.Ok | Dialog.Cancel
	closePolicy: Popup.CloseOnEscape

	implicitWidth: 500
	implicitHeight: 600
	width: parent && parent.width > 0
		? Math.min(implicitWidth, parent.width - Kirigami.Units.largeSpacing * 2)
		: implicitWidth
	height: parent && parent.height > 0
		? Math.min(implicitHeight, parent.height - Kirigami.Units.largeSpacing * 2)
		: implicitHeight
	x: parent ? Math.round((parent.width - width) / 2) : 0
	y: parent ? Math.round((parent.height - height) / 2) : 0
	property bool loadingCityList: false
	property string errorMessage: ""

	// Configuration properties passed from parent
	property bool cfg_debugging: false
	property string cfg_openWeatherMapAppId: ""

	Logger {
		id: logger
		showDebug: chooseCityDialog.cfg_debugging
	}

	ListModel { id: cityListModel }
	ListModel { id: filteredCityListModel }

	property string selectedCityId: ''

	function updateOkButton() {
		var button = standardButton(Dialog.Ok)
		if (button) {
			button.enabled = !!selectedCityId
		}
	}

	onSelectedCityIdChanged: updateOkButton()
	onOpened: {
		updateOkButton()
		cityNameInput.forceActiveFocus()
	}

	Timer {
		id: debouceApplyFilter
		interval: 1000
		onTriggered: chooseCityDialog.applyCityListSearch()
	}


	ColumnLayout {
		anchors.fill: parent
		spacing: Kirigami.Units.smallSpacing
		LinkText {
			text: i18n("Fetched from <a href=\"%1\">%1</a>", "https://openweathermap.org/find")
		}
		RowLayout {
			Layout.fillWidth: true
			Label {
				text: i18n("Search") + ":"
			}
			TextField {
				id: cityNameInput
				Layout.fillWidth: true
				text: ''
				placeholderText: i18n("Select city")
				onTextChanged: debouceApplyFilter.restart()
			}
		}

		Kirigami.InlineMessage {
			Layout.fillWidth: true
			visible: !!chooseCityDialog.errorMessage
			text: chooseCityDialog.errorMessage
			type: Kirigami.MessageType.Error
		}

		// Header row
		RowLayout {
			Layout.fillWidth: true
			spacing: Kirigami.Units.smallSpacing

			Label {
				Layout.preferredWidth: 240
				text: i18n("Name")
				font.bold: true
			}
			Label {
				Layout.preferredWidth: 100
				text: i18n("Id")
				font.bold: true
			}
			Label {
				Layout.fillWidth: true
				text: i18n("City Webpage")
				font.bold: true
			}
		}

		ScrollView {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.minimumHeight: 200

			ListView {
				id: listView
				model: filteredCityListModel
				clip: true

				delegate: ItemDelegate {
					width: listView.width
					highlighted: chooseCityDialog.selectedCityId === model.id

					contentItem: RowLayout {
						spacing: Kirigami.Units.smallSpacing

						Label {
							Layout.preferredWidth: 240
							text: model.name
							elide: Text.ElideRight
						}
						Label {
							Layout.preferredWidth: 100
							text: model.id
						}
						LinkText {
							Layout.fillWidth: true
							text: '<a href="https://openweathermap.org/city/' + model.id + '">' + i18n("Open Link") + '</a>'
						}
					}

					onClicked: {
						chooseCityDialog.selectedCityId = model.id
					}
				}

				BusyIndicator {
					anchors.centerIn: parent
					running: visible
					visible: chooseCityDialog.loadingCityList
				}
			}
		}
	}

	function clearCityList() {
		cityListModel.clear()
		filteredCityListModel.clear()
		chooseCityDialog.selectedCityId = ''
		chooseCityDialog.errorMessage = ''
	}

	function parseCityList(data) {
		for (var i = 0; i < data.list.length; i++) {
			var item = data.list[i]
			var city = {
				id: item.id,
				name: item.name + ', ' + item.sys.country,
			}
			cityListModel.append(city)
			filteredCityListModel.append(city)
		}
	}

	function applyCityListSearch() {
		searchCityList(cityNameInput.text)
	}

	function searchCityList(q) {
		logger.debug('searchCityList', q)
		clearCityList()
		if (q) {
			chooseCityDialog.loadingCityList = true
			fetchCityList({
				appId: chooseCityDialog.cfg_openWeatherMapAppId,
				q: q,
			}, function(err, data, xhr) {
				chooseCityDialog.loadingCityList = false
				if (err) {
					chooseCityDialog.errorMessage = data && data.message ? data.message : String(err)
					console.log('searchCityList.err', err, xhr && xhr.status, data)
					return
				}
				logger.debug('searchCityList.response')
				logger.debugJSON('searchCityList.response', data)

				parseCityList(data)
			})
		}
	}

	function fetchCityList(args, callback) {
		if (!args.appId) return callback('OpenWeatherMap AppId not set')

		var url = 'https://api.openweathermap.org/data/2.5/'
		url += 'find?q=' + encodeURIComponent(args.q)
		url += '&type=like'
		url += '&sort=population'
		url += '&cnt=30'
		url += '&appid=' + args.appId
		Requests.getJSON(url, callback)
	}
}
