import QtQuick
import org.kde.plasma.plasmoid
import "./ErrorType.js" as ErrorType
import "./weather/WeatherApi.js" as WeatherApi

Item {
	property var popup: null

	//--- Weather
	property var dailyWeatherData: { "list": [] }
	property var hourlyWeatherData: { "list": [] }
	property var currentWeatherData: null
	property var lastForecastAt: null
	property var lastForecastErr: null


	//--- Main
	Component.onCompleted: {
		pollTimer.start()
	}


	//--- Update
	Timer {
		id: pollTimer

		repeat: true
		triggeredOnStart: true
		interval: Plasmoid.configuration.eventsPollInterval * 60000
		onTriggered: logic.update()
	}

	function update() {
		logger.debug('update')
		logic.updateData()
	}

	function updateData() {
		logger.debug('updateData')
		logic.updateEvents()
		logic.updateWeather()
	}



	//--- Events
	function updateEvents() {
		updateEventsTimer.restart()
	}
	Timer {
		id: updateEventsTimer
		interval: 200
		onTriggered: logic.deferredUpdateEvents()
	}
	function deferredUpdateEvents() {
		var range = agendaModel.getDateRange(agendaModel.currentMonth)
		// console.log('   first', monthView.firstDisplayedDate())
		// console.log('    last', monthView.lastDisplayedDate())

		agendaModel.visibleDateMin = range.min
		agendaModel.visibleDateMax = range.max
		eventModel.fetchAll(range.min, range.max)
	}


	//--- Weather
	function updateWeather(force) {
		if (WeatherApi.weatherIsSetup(Plasmoid.configuration)) {
			// update every hour
			var shouldUpdate = false
			if (lastForecastAt) {
				var now = new Date()
				var currentHour = now.getHours()
				var lastUpdateHour = new Date(lastForecastAt).getHours()
				var beenOverAnHour = now.valueOf() - lastForecastAt >= 60 * 60 * 1000
				if (lastUpdateHour != currentHour || beenOverAnHour) {
					shouldUpdate = true
				}
			} else {
				shouldUpdate = true
			}

			if (force || shouldUpdate) {
				updateWeatherTimer.restart()
			}
		}
	}
	Timer {
		id: updateWeatherTimer
		interval: 100
		onTriggered: logic.deferredUpdateWeather()
	}
	function deferredUpdateWeather() {
		logic.updateDailyWeather()

		if (Plasmoid.configuration.widgetShowMeteogram) {
			logic.updateHourlyWeather()
		}
	}

	function resetWeatherData() {
		logic.dailyWeatherData = { "list": [] }
		logic.hourlyWeatherData = { "list": [] }
		logic.currentWeatherData = null
	}

	function resetWeatherAndUpdate() {
		logic.resetWeatherData()
		logic.updateWeather(true)
	}

	function handleWeatherError(funcName, err, data, xhr) {
		logger.log(funcName + '.err', err, xhr && xhr.status, data)
		if (xhr && xhr.status === 0) { // Error making connection
			var msg = i18n("Could not connect")
			var errorMessage = i18n("HTTP Error %1: %2", xhr.status, msg)
			errorMessage += '\n' + i18n("Will try again soon.")
			logic.lastForecastErr = errorMessage
		} else if (xhr && xhr.status == 429) {
			lastForecastAt = Date.now() // If there's an error, don't bother the API for another hour.
			var msg = i18n("Weather API limit reached")
			var errorMessage = i18n("HTTP Error %1: %2", xhr.status, msg)
			errorMessage += '\n' + i18n("Will try again soon.")
			logic.lastForecastErr = errorMessage
		} else {
			lastForecastAt = Date.now() // If there's an error, don't bother the API for another hour.
			logic.lastForecastErr = err
		}
	}

	function updateDailyWeather() {
		logger.debug('updateDailyWeather', lastForecastAt, Date.now())
		WeatherApi.updateDailyWeather(Plasmoid.configuration, function(err, data, xhr) {
			if (err) return handleWeatherError('updateDailyWeather', err, data, xhr)
			logger.debugJSON('updateDailyWeather.response', data)

			logic.lastForecastAt = Date.now()
			logic.lastForecastErr = null
			logic.dailyWeatherData = data
			if (popup) popup.updateUI()
		})
	}

	function updateHourlyWeather() {
		logger.debug('updateHourlyWeather', lastForecastAt, Date.now())
		WeatherApi.updateHourlyWeather(Plasmoid.configuration, function(err, data, xhr) {
			if (err) return handleWeatherError('updateHourlyWeather', err, data, xhr)
			logger.debugJSON('updateHourlyWeather.response', data)

			logic.lastForecastAt = Date.now()
			logic.lastForecastErr = null
			logic.hourlyWeatherData = data
			logic.currentWeatherData = data.list[0]
			if (popup) popup.updateMeteogram()
		})
	}

	//---
	Connections {
		target: Plasmoid.configuration

		//--- Events
		function onAccessTokenChanged() { logic.updateEvents() }
		function onCalendarIdListChanged() { logic.updateEvents() }
		function onEnabledCalendarPluginsChanged() { logic.updateEvents() }
		function onTasklistIdListChanged() { logic.updateEvents() }
		function onGoogleEventClickActionChanged() { logic.updateEvents() }

		//--- Weather
		function onWeatherServiceChanged() { logic.resetWeatherAndUpdate() }
		function onOpenWeatherMapAppIdChanged() { logic.resetWeatherAndUpdate() }
		function onOpenWeatherMapCityIdChanged() { logic.resetWeatherAndUpdate() }
		function onWeatherCanadaCityIdChanged() { logic.resetWeatherAndUpdate() }
		function onWeatherUnitsChanged() { logic.updateWeather(true) }
		function onWidgetShowMeteogramChanged() {
			if (Plasmoid.configuration.widgetShowMeteogram) {
				logic.updateHourlyWeather()
			}
		}

		//--- UI
		function onAgendaBreakupMultiDayEventsChanged() { if (popup) popup.updateUI() }
		function onMeteogramHoursChanged() { if (popup) popup.updateMeteogram() }
	}

	//---
	Connections {
		target: appletConfig
		function onClock24hChanged() { if (popup) popup.updateUI() }
	}

	//---
	property int currentErrorType: ErrorType.UnknownError
	property string currentErrorMessage: {
		if (Plasmoid.configuration.accessToken && Plasmoid.configuration.latestClientId != Plasmoid.configuration.sessionClientId) {
			return i18n("Widget has been updated. Please logout and login to Google Calendar again.")
		} else if (!Plasmoid.configuration.accessToken && Plasmoid.configuration.access_token) {
			return i18n("Logged out of Google. Please login again.")
		} else {
			return ""
		}
	}
	function clearError() {
		currentErrorType = ErrorType.NoError
		if (popup) popup.clearError()
	}
	Connections {
		target: eventModel
		function onError(msg, errorType) {
			logic.currentErrorMessage = msg
			logic.currentErrorType = errorType
			if (popup) popup.showError(logic.currentErrorMessage)
		}
	}

	//---
	Connections {
		target: eventModel
		function onCalendarFetched(calendarId, data) {
			logger.debug('onCalendarFetched', calendarId)
			// logger.debug('onCalendarFetched', calendarId, JSON.stringify(data, null, '\t'))
			if (popup) popup.deferredUpdateUI()
		}
		function onAllDataFetched() {
			logger.debug('onAllDataFetched')
			if (popup) popup.deferredUpdateUI()
		}
		function onEventCreated(calendarId, data) {
			logger.logJSON('onEventCreated', calendarId, data)
			if (popup) popup.deferredUpdateUI()
		}
		function onEventUpdated(calendarId, eventId, data) {
			logger.logJSON('onEventUpdated', calendarId, eventId, data)
			if (popup) popup.deferredUpdateUI()
		}
		function onEventDeleted(calendarId, eventId, data) {
			logger.logJSON('onEventDeleted', calendarId, eventId, data)
			if (popup) popup.deferredUpdateUI()
		}
	}

	//---
	Connections {
		target: networkMonitor
		function onIsConnectedChanged() {
			if (networkMonitor.isConnected) {
				if (logic.currentErrorType == ErrorType.NetworkError) {
					logic.clearError()
				}
				logic.update()
			}
		}
	}
}
