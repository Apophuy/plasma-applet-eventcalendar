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

	width: 500
	height: 600
	property bool loadingCityList: false

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

	Timer {
		id: debouceApplyFilter
		interval: 1000
		onTriggered: chooseCityDialog.applyCityListSearch()
	}


	ColumnLayout {
		anchors.fill: parent
		LinkText {
			text: i18n("Fetched from <a href=\"%1\">%1</a>", "https://openweathermap.org/find")
		}
		TextField {
			id: cityNameInput
			Layout.fillWidth: true
			text: ''
			placeholderText: i18n("Search")
			onTextChanged: debouceApplyFilter.restart()
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
				if (err) return console.log('searchCityList.err', err, xhr && xhr.status, data)
				logger.debug('searchCityList.response')
				logger.debugJSON('searchCityList.response', data)

				parseCityList(data)

				chooseCityDialog.loadingCityList = false
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
