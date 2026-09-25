import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid

import "lib"
import "Shared.js" as Shared
import "./weather/WeatherApi.js" as WeatherApi

MouseArea {
	id: popup

	onClicked: focus = true

	property int padding: 0 // Assigned in main.qml
	// Qt Quick sizes are already expressed in device-independent pixels.
	property int spacing: 10
	property bool isDesktopContainment: false
	readonly property int topWidgetsCount: (showMeteogram ? 1 : 0) + (showTimer ? 1 : 0)

	property int topRowHeight: Plasmoid.configuration.topRowHeight
	property int bottomRowHeight: Plasmoid.configuration.bottomRowHeight
	property int singleColumnMonthViewHeight: Plasmoid.configuration.monthHeightSingleColumn
	readonly property int effectiveTimerHeight: Math.max(topRowHeight, timerView.implicitHeight)
	readonly property int effectiveTwoColumnTopHeight: showTimer ? effectiveTimerHeight : topRowHeight

	// DigitalClock LeftColumn minWidth: Kirigami.Units.gridUnit * 22
	// DigitalClock RightColumn minWidth: Kirigami.Units.gridUnit * 14
	// 14/(22+14) * 400 = 156
	// rightColumnWidth=156 looks nice but is very thin for listing events + date + weather.
	property int leftColumnWidth: Plasmoid.configuration.leftColumnWidth // Meteogram + MonthView
	property int rightColumnWidth: Plasmoid.configuration.rightColumnWidth // TimerView + AgendaView

	readonly property int twoColumnNaturalWidth: leftColumnWidth + spacing + rightColumnWidth + padding * 2
	readonly property int singleColumnNaturalWidth: leftColumnWidth + padding * 2
	readonly property int screenMargin: Kirigami.Units.gridUnit * 2
	readonly property var currentScreenGeometry: Plasmoid.screenGeometry || null
	readonly property real availableScreenWidth: currentScreenGeometry && currentScreenGeometry.width > 0
		? Math.max(Kirigami.Units.gridUnit * 14, currentScreenGeometry.width - screenMargin)
		: Number.POSITIVE_INFINITY
	readonly property real availableScreenHeight: currentScreenGeometry && currentScreenGeometry.height > 0
		? Math.max(Kirigami.Units.gridUnit * 14, currentScreenGeometry.height - screenMargin)
		: Number.POSITIVE_INFINITY
	readonly property bool bothMainWidgetsVisible: showAgenda && showCalendar
	readonly property bool calendarOnly: !showAgenda && showCalendar && !showMeteogram && !showTimer
	readonly property bool screenCanFitTwoColumns: twoColumnNaturalWidth <= availableScreenWidth
	property bool twoColumns: Plasmoid.configuration.twoColumns && bothMainWidgetsVisible
		&& (isDesktopContainment ? width <= 0 || width >= twoColumnNaturalWidth : screenCanFitTwoColumns)
	property bool singleColumn: !twoColumns
	readonly property int meteogramPreferredHeight: singleColumn && !bothMainWidgetsVisible
		? Math.round(topRowHeight * 1.5)
		: topRowHeight
	readonly property int singleColumnWidgetCount: topWidgetsCount + (showAgenda ? 1 : 0) + (showCalendar ? 1 : 0)
	readonly property int singleColumnContentHeight: (showMeteogram ? meteogramPreferredHeight : 0)
		+ (showTimer ? effectiveTimerHeight : 0)
		+ (showCalendar ? (showAgenda ? singleColumnMonthViewHeight : bottomRowHeight) : 0)
		+ (showAgenda ? bottomRowHeight : 0)
		+ Math.max(0, singleColumnWidgetCount - 1) * spacing

	Layout.minimumWidth: {
		if (twoColumns) {
			return Kirigami.Units.gridUnit * 28
		} else {
			return Kirigami.Units.gridUnit * 14
		}
	}
	Layout.preferredWidth: {
		var naturalWidth = calendarOnly ? 378 : (twoColumns ? twoColumnNaturalWidth : singleColumnNaturalWidth)
		return Math.min(naturalWidth, availableScreenWidth)
	}
	Layout.maximumWidth: isDesktopContainment ? Number.POSITIVE_INFINITY : availableScreenWidth

	Layout.minimumHeight: Kirigami.Units.gridUnit * 14
	Layout.preferredHeight: {
		var naturalHeight
		if (calendarOnly) {
			naturalHeight = 378
		} else if (singleColumn) {
			naturalHeight = singleColumnContentHeight + padding * 2
		} else { // twoColumns
			naturalHeight = bottomRowHeight // showAgenda || showCalendar
			if (showMeteogram || showTimer) {
				naturalHeight += spacing + effectiveTwoColumnTopHeight
			}
			naturalHeight += padding * 2
		}
		return Math.min(naturalHeight, availableScreenHeight)
	}
	Layout.maximumHeight: isDesktopContainment ? Number.POSITIVE_INFINITY : availableScreenHeight

	property var eventModel
	property var agendaModel

	property bool showMeteogram: Plasmoid.configuration.widgetShowMeteogram
	property bool showTimer: Plasmoid.configuration.widgetShowTimer
	property bool showAgenda: Plasmoid.configuration.widgetShowAgenda
	property bool showCalendar: Plasmoid.configuration.widgetShowCalendar
	property bool agendaScrollOnSelect: true
	property bool agendaScrollOnMonthChange: false

	property alias today: monthView.today
	property alias selectedDate: monthView.currentDate
	property alias monthViewDate: monthView.displayedDate

	Connections {
		target: monthView
		function onDateSelected(selectedDate) {
			// logger.debug('onDateSelected', selectedDate)
			scrollToSelection()
		}
	}
	function scrollToSelection() {
		if (!agendaScrollOnSelect) {
			return
		}

		if (true) {
			agendaView.scrollToDate(selectedDate)
		} else {
			agendaView.scrollToTop()
		}
	}

	onMonthViewDateChanged: {
		logger.debug('onMonthViewDateChanged', monthViewDate)
		var startOfMonth = new Date(monthViewDate)
		startOfMonth.setDate(1)
		agendaModel.currentMonth = new Date(startOfMonth)
		if (agendaScrollOnMonthChange) {
			selectedDate = startOfMonth
		}
		logic.updateEvents()
	}

	GridLayout {
		id: widgetGrid
		anchors.fill: parent
		anchors.margins: popup.padding
		columns: popup.twoColumns ? 2 : 1
		columnSpacing: popup.spacing
		rowSpacing: popup.spacing


		MeteogramView {
			id: meteogramView
			visible: showMeteogram
			Layout.column: 0
			Layout.row: 0
			Layout.columnSpan: popup.twoColumns && !timerView.visible ? 2 : 1
			Layout.fillWidth: true
			Layout.fillHeight: false
			Layout.minimumHeight: popup.topRowHeight
			Layout.preferredWidth: popup.leftColumnWidth
			Layout.preferredHeight: popup.meteogramPreferredHeight
			Layout.maximumHeight: popup.meteogramPreferredHeight
			visibleDuration: Plasmoid.configuration.meteogramHours
			showIconOutline: Plasmoid.configuration.showOutlines
			xAxisScale: 1 / hoursPerDataPoint
			xAxisLabelEvery: Math.ceil(3 / hoursPerDataPoint)
			property int hoursPerDataPoint: WeatherApi.getDataPointDuration(Plasmoid.configuration)
			rainUnits: WeatherApi.getRainUnits(Plasmoid.configuration)

			Rectangle {
				id: meteogramMessageBox
				anchors.fill: parent
				anchors.margins: Kirigami.Units.smallSpacing
				color: "transparent"
				border.color: Kirigami.Theme.backgroundColor
				border.width: 1

				readonly property string message: {
					if (!WeatherApi.weatherIsSetup(Plasmoid.configuration)) {
						return i18n("Weather not configured.\nGo to Weather in the config and set your city,\nand/or disable the meteogram to hide this area.")
					} else if (logic.lastForecastErr) {
						return i18n("Error fetching weather.") + '\n' + logic.lastForecastErr
					} else {
						return ''
					}
				}

				visible: !!message

				PlasmaComponents3.Label {
					text: meteogramMessageBox.message
					anchors.fill: parent
					fontSizeMode: Text.Fit
					wrapMode: Text.Wrap
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
				}
			}
		}

		TimerView {
			id: timerView
			visible: showTimer
			Layout.column: popup.twoColumns && meteogramView.visible ? 1 : 0
			Layout.row: popup.twoColumns ? 0 : (meteogramView.visible ? 1 : 0)
			Layout.fillWidth: true
			Layout.fillHeight: false
			Layout.minimumHeight: popup.effectiveTimerHeight
			Layout.preferredWidth: popup.rightColumnWidth
			Layout.preferredHeight: popup.effectiveTimerHeight
			Layout.maximumHeight: popup.effectiveTimerHeight
		}

		MonthView {
			id: monthView
			visible: showCalendar
			Layout.column: 0
			Layout.row: popup.twoColumns ? ((popup.showMeteogram || popup.showTimer) ? 1 : 0) : popup.topWidgetsCount
			borderOpacity: Plasmoid.configuration.monthShowBorder ? 0.25 : 0
			showWeekNumbers: Plasmoid.configuration.monthShowWeekNumbers
			highlightCurrentDayWeek: Plasmoid.configuration.monthHighlightCurrentDayWeek

			Layout.preferredWidth: popup.leftColumnWidth
			Layout.minimumHeight: popup.singleColumn && popup.bothMainWidgetsVisible
				? popup.singleColumnMonthViewHeight
				: 0
			Layout.preferredHeight: popup.calendarOnly
				? 378
				: (popup.singleColumn && popup.bothMainWidgetsVisible
					? popup.singleColumnMonthViewHeight
					: popup.bottomRowHeight)
			Layout.maximumHeight: popup.singleColumn && popup.bothMainWidgetsVisible
				? popup.singleColumnMonthViewHeight
				: Infinity
			Layout.fillWidth: true
			Layout.fillHeight: true

			// Component.onCompleted: {
			// 	today = new Date()
			// }

			function parseGCalEvents(data) {
				if (!(data && data.items)) {
					return
				}

				// Clear event data since data contains events from all calendars, and this function
				// is called every time a calendar is recieved.
				for (var i = 0; i < monthView.daysModel.count; i++) {
					var dayData = monthView.daysModel.get(i)
					monthView.daysModel.setProperty(i, 'showEventBadge', false)
					dayData.events.clear()
				}

				// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/calendar/daysmodel.h
				for (var j = 0; j < data.items.length; j++) {
					var eventItem = data.items[j]
					var eventItemStartDate = new Date(eventItem.startDateTime.getFullYear(), eventItem.startDateTime.getMonth(), eventItem.startDateTime.getDate())
					var eventItemEndDate = new Date(eventItem.endDateTime.getFullYear(), eventItem.endDateTime.getMonth(), eventItem.endDateTime.getDate())
					if (eventItem.end.date) {
						// All day events end at midnight which is technically the next day.
						eventItemEndDate.setDate(eventItemEndDate.getDate() - 1)
					}
					// logger.debug(eventItemStartDate, eventItemEndDate)
					for (var i = 0; i < monthView.daysModel.count; i++) {
						var dayData = monthView.daysModel.get(i)
						var dayDataDate = new Date(dayData.yearNumber, dayData.monthNumber - 1, dayData.dayNumber)
						if (eventItemStartDate <= dayDataDate && dayDataDate <= eventItemEndDate) {
							// logger.debug('\t', dayDataDate)
							monthView.daysModel.setProperty(i, 'showEventBadge', true)
							var events = dayData.events || []
							events.append(eventItem)
							monthView.daysModel.setProperty(i, 'events', events)
						} else if (eventItemEndDate < dayDataDate) {
							break
						}
					}
				}
			}

			onDayDoubleClicked: function(dayData) {
				var date = new Date(dayData.yearNumber, dayData.monthNumber-1, dayData.dayNumber)
				// logger.debug('Popup.monthView.onDoubleClicked', date)
				var doubleClickOption = Plasmoid.configuration.monthDayDoubleClick

				switch (doubleClickOption) {
					case 'GoogleCalWeb':
						Shared.openGoogleCalendarNewEventUrl(date)
						return
					default:
						return
				}
			}
		} // MonthView

		AgendaView {
			id: agendaView
			visible: showAgenda
			Layout.column: popup.twoColumns ? 1 : 0
			Layout.row: popup.twoColumns
				? (popup.showTimer && !popup.showMeteogram ? 0 : ((popup.showMeteogram || popup.showTimer) ? 1 : 0))
				: (popup.topWidgetsCount + (monthView.visible ? 1 : 0))
			Layout.rowSpan: popup.twoColumns && popup.showTimer && !popup.showMeteogram ? 2 : 1

			Layout.preferredWidth: popup.twoColumns ? popup.rightColumnWidth : popup.leftColumnWidth
			Layout.preferredHeight: popup.bottomRowHeight
			Layout.fillWidth: true
			Layout.fillHeight: true

			onNewEventFormOpened: function(agendaItem, calendarSelector) {
				// logger.debug('onNewEventFormOpened')
				var selectedCalendarId = ""
				if (Plasmoid.configuration.agendaNewEventRememberCalendar) {
					selectedCalendarId = Plasmoid.configuration.agendaNewEventLastCalendarId
				}
				var calendarList = eventModel.getCalendarList()
				calendarSelector.populate(calendarList, selectedCalendarId)
			}
			onSubmitNewEventForm: function(calendarId, date, text) {
				logger.debug('onSubmitNewEventForm', calendarId)
				eventModel.createEvent(calendarId, date, text)
			}

			MessageWidget {
				id: errorMessageWidget
				anchors.left: parent.left
				anchors.bottom: parent.bottom
				anchors.right: refreshButton.left
				anchors.margins: Kirigami.Units.smallSpacing
				text: logic.currentErrorMessage
			}

			PlasmaComponents3.Button {
				id: refreshButton
				icon.name: 'view-refresh'
				anchors.bottom: parent.bottom
				anchors.right: parent.right
				anchors.rightMargin: agendaView.scrollbarWidth
				onClicked: {
					logic.update()
				}

				// Timer {
				// 	running: true
				// 	repeat: true
				// 	interval: 2000
				// 	onTriggered: parent.clicked()
				// }
			}
		} // AgendaView
	} // GridLayout

	function updateMeteogram() {
		meteogramView.parseWeatherForecast(logic.currentWeatherData, logic.hourlyWeatherData)
	}

	function showError(msg) {
		errorMessageWidget.warn(msg)
	}

	function clearError() {
		errorMessageWidget.close()
	}

	Timer {
		id: updateUITimer
		interval: 100
		onTriggered: popup.updateUI()
	}
	function deferredUpdateUI() {
		updateUITimer.restart()
	}

	function updateUI() {
		// logger.debug('updateUI')
		var now = new Date()

		if (updateUITimer.running) {
			updateUITimer.running = false
		}

		agendaModel.parseGCalEvents(eventModel.eventsData)
		agendaModel.parseWeatherForecast(logic.dailyWeatherData)
		monthView.parseGCalEvents(eventModel.eventsData)
		scrollToSelection()
	}
}
