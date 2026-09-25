import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls

import "../lib/Requests.js" as Requests
import ".."
import "../weather/WeatherCanada.js" as WeatherCanada

Dialog {
	id: chooseCityDialog
	title: i18n("Select city")

	implicitWidth: 500
	implicitHeight: 600
	width: parent && parent.width > 0 ? Math.min(implicitWidth, parent.width) : implicitWidth
	height: parent && parent.height > 0 ? Math.min(implicitHeight, parent.height) : implicitHeight
	property bool loadingCityList: false
	property bool cityListLoaded: false

	ListModel { id: emptyListModel }
	ListModel { id: cityListModel }

	// Filtered list using JavaScript
	property var filteredCityList: []
	property string filterText: ""

	function updateFilteredList() {
		var newList = []
		var filter = filterText.toLowerCase()
		for (var i = 0; i < cityListModel.count; i++) {
			var item = cityListModel.get(i)
			if (filter === "" || item.name.toLowerCase().indexOf(filter) >= 0) {
				newList.push({
					id: item.id,
					name: item.name
				})
			}
		}
		// Sort by name
		newList.sort(function(a, b) {
			return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
		})
		// Assign to trigger filteredCityListChanged signal automatically
		filteredCityList = newList
	}

	property string selectedCityId: ''
	property int currentProvinceIndex: 0
	property var provinceIdList: ['AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU', 'ON', 'PE', 'QC', 'SK', 'YT']

	Timer {
		id: debounceApplyFilter
		interval: 300
		onTriggered: {
			chooseCityDialog.filterText = cityNameInput.text
			chooseCityDialog.updateFilteredList()
		}
	}

	onVisibleChanged: {
		if (visible && !cityListLoaded && !loadingCityList) {
			loadProvinceCityList()
		}
	}


	ColumnLayout {
		anchors.fill: parent

		LinkText {
			text: i18n("Fetched from <a href=\"%1\">%1</a>", "https://weather.gc.ca/canada_e.html")
		}

		// Province tabs using TabBar
		TabBar {
			id: provinceTabBar
			Layout.fillWidth: true

			Repeater {
				model: chooseCityDialog.provinceIdList
				TabButton {
					text: modelData
					width: implicitWidth
				}
			}

			onCurrentIndexChanged: {
				chooseCityDialog.currentProvinceIndex = currentIndex
				chooseCityDialog.loadProvinceCityList()
			}
		}

		TextField {
			id: cityNameInput
			Layout.fillWidth: true
			text: ''
			placeholderText: i18n("Search")
			onTextChanged: debounceApplyFilter.restart()
		}

		// City list using ListView
		ScrollView {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.minimumHeight: 200

			ListView {
				id: cityListView
				clip: true
				model: chooseCityDialog.filteredCityList

				delegate: ItemDelegate {
					width: cityListView.width
					highlighted: chooseCityDialog.selectedCityId === modelData.id

					contentItem: RowLayout {
						spacing: Kirigami.Units.smallSpacing

						Label {
							text: modelData.name
							Layout.preferredWidth: 240
							elide: Text.ElideRight
						}
						Label {
							text: modelData.id
							Layout.preferredWidth: 100
							color: Kirigami.Theme.disabledTextColor
						}
						Label {
							Layout.fillWidth: true
							text: '<a href="https://weather.gc.ca/city/pages/' + modelData.id + '_metric_e.html">' + i18n("Open Link") + '</a>'
							linkColor: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.linkColor
							onLinkActivated: (link) => Qt.openUrlExternally(link)

							MouseArea {
								anchors.fill: parent
								acceptedButtons: Qt.NoButton
								cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
							}
						}
					}

					onClicked: {
						chooseCityDialog.selectedCityId = modelData.id
					}
				}

				Connections {
					target: chooseCityDialog
					function onFilteredCityListChanged() {
						cityListView.model = chooseCityDialog.filteredCityList
					}
				}
			}

			BusyIndicator {
				anchors.centerIn: parent
				running: visible
				visible: chooseCityDialog.loadingCityList
			}
		}
	}


	function loadCityList(provinceUrl) {
		chooseCityDialog.loadingCityList = true
		cityListModel.clear()
		filteredCityList = []

		Requests.request(provinceUrl, function(err, data) {
			if (err) {
				console.log('[eventcalendar]', 'loadCityList.err', err, data)
				chooseCityDialog.loadingCityList = false
				return
			}
			var cityList = WeatherCanada.parseProvincePage(data)
			for (var i = 0; i < cityList.length; i++) {
				cityListModel.append(cityList[i])
			}

			chooseCityDialog.updateFilteredList()

			chooseCityDialog.cityListLoaded = true
			chooseCityDialog.loadingCityList = false
		})
	}

	function loadProvinceCityList() {
		var provinceId = provinceIdList[0]
		if (currentProvinceIndex >= 0 && currentProvinceIndex < provinceIdList.length) {
			provinceId = provinceIdList[currentProvinceIndex]
		}

		var provinceUrl = 'https://weather.gc.ca/forecast/canada/index_e.html?id=' + provinceId
		loadCityList(provinceUrl)
	}
}
