import QtQuick
import org.kde.plasma.plasmoid

import "./calendars"
import "./ErrorType.js" as ErrorType

CalendarManager {
	id: eventModel

	property var calendarManagerList: []
	property var calendarPluginMap: ({}) // Empty Map
	property var eventsData: { "items": [] }
	readonly property var appearanceOverrideMap: {
		var map = {}
		var encoded = Plasmoid.configuration.calendarAppearanceOverrides
		if (!encoded) return map
		try {
			var list = JSON.parse(Qt.atob(encoded))
			for (var i = 0; i < list.length; i++) {
				map[list[i].key] = list[i]
			}
		} catch (error) {
			return {}
		}
		return map
	}

	Component.onCompleted: {
		bindSignals(googleCalendarManager)
		bindSignals(googleTasksManager)
		bindSignals(yandexCalendarManager)
		bindSignals(plasmaCalendarManager)
		bindSignals(icalManager)
		// bindSignals(debugCalendarManager)
		// bindSignals(debugGoogleCalendarManager)
	}

	//---
	function fetchingDataListener() { eventModel.asyncRequests += 1 }
	function allDataFetchedListener() { eventModel.asyncRequestsDone += 1 }
	function calendarFetchedListener(calendarManager, calendarId, data) {
		var storageKey = calendarManager.calendarManagerId + ":" + calendarId
		eventModel.eventsByCalendar[storageKey] = data
		eventModel.calendarPluginMap[calendarId] = calendarManager
		eventModel.calendarFetched(calendarId, data)
	}
	function eventAddedListener(calendarId, data) {
		eventModel.mergeEvents()
		eventModel.eventAdded(calendarId, data)
	}
	function eventCreatedListener(calendarId, data) {
		eventModel.eventCreated(calendarId, data)
	}
	function eventRemovedListener(calendarId, eventId, data) {
		eventModel.mergeEvents()
		eventModel.eventRemoved(calendarId, eventId, data)
	}
	function eventDeletedListener(calendarId, eventId, data) {
		eventModel.eventDeleted(calendarId, eventId, data)
	}
	function eventUpdatedListener(calendarId, eventId, data) {
		eventModel.mergeEvents()
		eventModel.eventUpdated(calendarId, eventId, data)
	}

	function bindSignals(calendarManager) {
		logger.debug('bindSignals', calendarManager)
		calendarManager.fetchingData.connect(fetchingDataListener)
		calendarManager.allDataFetched.connect(allDataFetchedListener)
		calendarManager.calendarFetched.connect(function(calendarId, data) {
			eventModel.calendarFetchedListener(calendarManager, calendarId, data)
		})

		calendarManager.eventAdded.connect(eventAddedListener)
		calendarManager.eventCreated.connect(eventCreatedListener)
		calendarManager.eventRemoved.connect(eventRemovedListener)
		calendarManager.eventDeleted.connect(eventDeletedListener)
		calendarManager.eventUpdated.connect(eventUpdatedListener)
		calendarManager.refresh.connect(deferredUpdate.restart)

		calendarManager.error.connect(error)

		calendarManagerList.push(calendarManager)
	}

	function getCalendarManager(calendarId) {
		return eventModel.calendarPluginMap[calendarId]
	}

	//---
	ICalManager {
		id: icalManager
		calendarList: Array.isArray(appletConfig.icalCalendarList.value)
			? appletConfig.icalCalendarList.value
			: []
	}

	DebugCalendarManager { id: debugCalendarManager }
	DebugGoogleCalendarManager { id: debugGoogleCalendarManager }

	GoogleApiSession {
		id: googleApiSession
	}
	Connections {
		target: googleApiSession
		function onAccessTokenError(msg) {
			eventModel.error(msg, ErrorType.ClientError)
		}
	}
	GoogleCalendarManager {
		id: googleCalendarManager
		session: googleApiSession
	}
	GoogleTasksManager {
		id: googleTasksManager
		session: googleApiSession
	}
	YandexCalendarManager {
		id: yandexCalendarManager
	}

	PlasmaCalendarManager {
		id: plasmaCalendarManager
	}

	//---
	property var deferredUpdate: Timer {
		id: deferredUpdate
		interval: 200
		onTriggered: eventModel.update()
	}
	function update() {
		fetchAll()
	}

	onFetchAllCalendars: {
		for (var i = 0; i < calendarManagerList.length; i++) {
			var calendarManager = calendarManagerList[i]
			calendarManager.fetchAll(dateMin, dateMax)
		}
	}

	onAllDataFetched: mergeEvents()

	function mergeEvents() {
		logger.debug('eventModel.mergeEvents')
		delete eventModel.eventsData
		eventModel.eventsData = { items: [] }
		for (var calendarId in eventModel.eventsByCalendar) {
			var items = eventModel.eventsByCalendar[calendarId].items
			for (var i = 0; i < items.length; i++) {
				applyAppearance(items[i])
			}
			eventModel.eventsData.items = eventModel.eventsData.items.concat(items)
		}
	}

	function appearanceFor(calendarKey) {
		return appearanceOverrideMap[calendarKey] || null
	}

	function applyAppearance(event) {
		event.calendarKey = event.calendarKey || event.calendarManagerId + ":" + event.calendarId
		if (typeof event.sourceBackgroundColor === "undefined") {
			event.sourceBackgroundColor = event.backgroundColor || ""
		}
		if (typeof event.sourceForegroundColor === "undefined") {
			event.sourceForegroundColor = event.foregroundColor || ""
		}
		var appearance = appearanceFor(event.calendarKey)
		event.backgroundColor = appearance && appearance.backgroundColor
			? appearance.backgroundColor
			: event.sourceBackgroundColor
		event.foregroundColor = appearance && appearance.foregroundColor
			? appearance.foregroundColor
			: event.sourceForegroundColor
	}

	//--- CalendarManager: Event
	function createEvent(calendarId, date, text) {
		if (Plasmoid.configuration.agendaNewEventRememberCalendar) {
			Plasmoid.configuration.agendaNewEventLastCalendarId = calendarId
		}

		var calendarManager = getCalendarManager(calendarId)
		if (calendarManager) {
			calendarManager.createEvent(calendarId, date, text)
		} else {
			logger.log('Could not createEvent. Could not find calendarManager for calendarId = ', calendarId)
		}
	}

	function deleteEvent(calendarId, eventId) {
		var calendarManager = getCalendarManager(calendarId)
		if (calendarManager) {
			calendarManager.deleteEvent(calendarId, eventId)
		} else {
			logger.log('Could not deleteEvent. Could not find calendarManager for calendarId = ', calendarId)
		}
	}

	function setEventProperty(calendarId, eventId, key, value) {
		logger.debug('eventModel.setEventProperty', calendarId, eventId, key, value)
		var calendarManager = getCalendarManager(calendarId)
		if (calendarManager) {
			calendarManager.setEventProperty(calendarId, eventId, key, value)
		} else {
			logger.log('Could not setEventProperty. Could not find calendarManager for calendarId = ', calendarId)
		}
	}

	function setEventProperties(calendarId, eventId, args) {
		logger.debugJSON('eventModel.setEventProperties', calendarId, eventId, args)
		var calendarManager = getCalendarManager(calendarId)
		if (calendarManager) {
			calendarManager.setEventProperties(calendarId, eventId, args)
		} else {
			logger.log('Could not setEventProperties. Could not find calendarManager for calendarId = ', calendarId)
		}
	}

	//--- CalendarManager: Calendar
	function getCalendarList() {
		var calendarList = []
		for (var i = 0; i < calendarManagerList.length; i++) {
			var calendarManager = calendarManagerList[i]
			var list = calendarManager.getCalendarList()
			// logger.debugJSON(calendarManager.toString(), list)
			for (var j = 0; j < list.length; j++) {
				var calendar = Object.assign({}, list[j])
				calendar.calendarManagerId = calendarManager.calendarManagerId
				calendar.calendarKey = calendarManager.calendarManagerId + ":" + calendar.id
				var appearance = appearanceFor(calendar.calendarKey)
				if (appearance && appearance.backgroundColor) calendar.backgroundColor = appearance.backgroundColor
				if (appearance && appearance.foregroundColor) calendar.foregroundColor = appearance.foregroundColor
				calendarList.push(calendar)
			}
		}
		return calendarList
	}
}
