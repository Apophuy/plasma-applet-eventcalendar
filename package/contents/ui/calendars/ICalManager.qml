import QtQuick
import org.kde.plasma.core as PlasmaCore

import "../lib"
import "../ErrorType.js" as ErrorType

CalendarManager {
	id: icalManager

	calendarManagerId: "ical"
	ExecUtil { id: executable }

	property var calendarList: []

	function isEnabled(calendarData) {
		return calendarData && calendarData.url && calendarData.show !== false
	}

	function displayName(calendarData) {
		return calendarData.name || i18n("iCalendar")
	}
	function calendarId(calendarData, index) {
		return calendarData.id || "ical:" + index
	}

	function getCalendarList() {
		var result = []
		for (var i = 0; i < calendarList.length; i++) {
			var calendarData = calendarList[i]
			if (!isEnabled(calendarData)) {
				continue
			}
			result.push({
				id: calendarId(calendarData, i),
				summary: displayName(calendarData),
				backgroundColor: calendarData.backgroundColor,
				accessRole: "reader",
				isTasklist: false,
			})
		}
		return result
	}

	function getCalendar(calendarId) {
		for (var i = 0; i < calendarList.length; i++) {
			var calendarData = calendarList[i]
			if (icalManager.calendarId(calendarData, i) === calendarId) {
				return calendarData
			}
		}
		return null
	}

	function fetchEvents(calendarData, startTime, endTime, callback) {
		logger.debug('ical.fetchEvents', displayName(calendarData))
		var startDate = startTime.getFullYear() + '-' + (startTime.getMonth()+1) + '-' + startTime.getDate()
		var endDate = endTime.getFullYear() + '-' + (endTime.getMonth()+1) + '-' + endTime.getDate()
		var cmd = [
			'python3',
			executable.urlToLocalPath(Qt.resolvedUrl("../../scripts/icsjson.py")),
			'--url', calendarData.url,
			'query', startDate, endDate,
		]
		executable.exec(cmd, function(cmd, exitCode, exitStatus, stdout, stderr) {
			if (exitCode) {
				return callback({
					exitCode: exitCode,
					message: stderr.trim(),
				})
			}
			var data
			try {
				data = JSON.parse(stdout)
			} catch (err) {
				return callback({
					exitCode: 5,
					message: 'Invalid iCalendar response: ' + err,
				})
			}
			// console.log(cmd)
			// console.log(str)
			callback(null, data)
		})
	}

	function fetchCalendar(calendarId, calendarData) {
		icalManager.asyncRequests += 1
		fetchEvents(calendarData, dateMin, dateMax, function(err, data) {
			if (err) {
				var calendarName = displayName(calendarData)
				if (err.exitCode === 3) {
					icalManager.error(i18n("Could not load iCalendar “%1”. Install the Python “icalendar” module.", calendarName), ErrorType.ClientError)
				} else {
					icalManager.error(i18n("Could not load iCalendar “%1”.", calendarName), ErrorType.UnknownError)
				}
				icalManager.asyncRequestsDone += 1
				return
			}
			setCalendarData(calendarId, data)
			icalManager.asyncRequestsDone += 1
		})
	}

	onFetchAllCalendars: {
		for (var i = 0; i < calendarList.length; i++) {
			var calendarData = calendarList[i]
			if (isEnabled(calendarData)) {
				fetchCalendar(calendarId(calendarData, i), calendarData)
			}
		}
	}

	onCalendarParsing: function(calendarId, data) {
		var calendar = getCalendar(calendarId)
		if (!calendar) {
			return
		}
		parseEventList(calendar, data.items)
	}

	function parseEvent(calendar, event) {
		event.backgroundColor = calendar.backgroundColor
		event.canEdit = false
	}

	function parseEventList(calendar, eventList) {
		eventList.forEach(function(event) {
			parseEvent(calendar, event)
		})
	}

	// onCalendarFetched: {
	// 	console.log(calendarId, data)
	// }

	// Component.onCompleted: {
	// 	var startTime = new Date(2017, 07-1, 01)
	// 	var endTime = new Date(2017, 07-1, 31)
	// 	dateMin = startTime
	// 	dateMax = endTime
	// 	fetchAllCalendars()
	// }
}
