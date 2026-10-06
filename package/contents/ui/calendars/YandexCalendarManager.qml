import QtQuick
import org.kde.plasma.plasmoid

import "../lib"
import "../ErrorType.js" as ErrorType

CalendarManager {
	id: yandexCalendarManager

	calendarManagerId: "YandexCalendar"

	ExecUtil { id: executable }

	readonly property var accounts: {
		if (!Plasmoid.configuration.yandexAccounts) {
			return []
		}
		try {
			return JSON.parse(Qt.atob(Plasmoid.configuration.yandexAccounts))
		} catch (error) {
			return []
		}
	}

	function enabledAccounts() {
		return accounts.filter(function(account) {
			return account.enabled !== false && account.login && Array.isArray(account.calendars)
		})
	}

	function selectedCalendars(account) {
		return account.calendars.filter(function(calendar) {
			return calendar.selected !== false
		})
	}

	function getCalendarList() {
		var result = []
		var list = enabledAccounts()
		for (var i = 0; i < list.length; i++) {
			var account = list[i]
			var calendars = selectedCalendars(account)
			for (var j = 0; j < calendars.length; j++) {
				var calendar = Object.assign({}, calendars[j])
				calendar.accountId = account.id
				calendar.accountName = account.name || account.login
				calendar.providerName = i18n("Yandex Calendar")
				calendar.isTasklist = false
				result.push(calendar)
			}
		}
		return result
	}

	function getCalendar(calendarId) {
		var list = getCalendarList()
		for (var i = 0; i < list.length; i++) {
			if (list[i].id === calendarId) {
				return list[i]
			}
		}
		return null
	}

	function dateString(date) {
		return date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate()
	}

	function helperPath() {
		return executable.urlToLocalPath(Qt.resolvedUrl("../../scripts/yandex_caldav.py"))
	}

	function fetchAccount(account) {
		var calendars = selectedCalendars(account)
		if (calendars.length === 0) {
			return
		}
		yandexCalendarManager.asyncRequests += 1
		var encodedCalendars = Qt.btoa(JSON.stringify(calendars))
		executable.exec([
			"python3", helperPath(), "query",
			"--account-id", account.id,
			"--login", account.login,
			"--calendars", encodedCalendars,
			"--start", dateString(dateMin),
			"--end", dateString(dateMax),
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			if (exitCode !== 0) {
				if (exitCode === 3) {
					yandexCalendarManager.error(
						i18n("Could not update Yandex Calendar account “%1”. Install the Python “icalendar” module.", account.name || account.login),
						ErrorType.ClientError
					)
					yandexCalendarManager.asyncRequestsDone += 1
					return
				}
				yandexCalendarManager.error(
					i18n("Could not update Yandex Calendar account “%1”: %2", account.name || account.login, (stderr || "").trim()),
					exitCode === 2 ? ErrorType.ClientError : ErrorType.UnknownError
				)
				yandexCalendarManager.asyncRequestsDone += 1
				return
			}
			var response
			try {
				response = JSON.parse((stdout || "").trim())
			} catch (error) {
				yandexCalendarManager.error(i18n("Yandex Calendar returned invalid data."), ErrorType.UnknownError)
				yandexCalendarManager.asyncRequestsDone += 1
				return
			}
			var byCalendar = {}
			for (var i = 0; i < calendars.length; i++) {
				byCalendar[calendars[i].id] = { items: [] }
			}
			var items = response.items || []
			for (var j = 0; j < items.length; j++) {
				var item = items[j]
				if (byCalendar[item.calendarId]) {
					byCalendar[item.calendarId].items.push(item)
				}
			}
			for (var calendarId in byCalendar) {
				setCalendarData(calendarId, byCalendar[calendarId])
			}
			yandexCalendarManager.asyncRequestsDone += 1
		})
	}

	onFetchAllCalendars: {
		var list = enabledAccounts()
		for (var i = 0; i < list.length; i++) {
			fetchAccount(list[i])
		}
	}

	onCalendarParsing: function(calendarId, data) {
		var calendar = getCalendar(calendarId)
		if (!calendar) {
			return
		}
		for (var i = 0; i < data.items.length; i++) {
			var event = data.items[i]
			event.description = event.description || ""
			event.backgroundColor = calendar.backgroundColor
			event.foregroundColor = calendar.foregroundColor || ""
			event.canEdit = false
		}
	}
}
