import QtQuick

import "../lib/Requests.js" as Requests

CalendarManager {
	id: debugCalendarManager

	calendarManagerId: "DebugGoogleCalendar"

	function fetchDebugGoogleSession() {
		if (Plasmoid.configuration.accessToken) {
			return
		}
		// Steal accessToken from our current user's config.
		fetchCurrentUserConfig(function(err, metadata) {
			Plasmoid.configuration.sessionClientId = metadata['sessionClientId']
			Plasmoid.configuration.sessionClientSecret = metadata['sessionClientSecret']
			Plasmoid.configuration.accessToken = metadata['accessToken']
			Plasmoid.configuration.refreshToken = metadata['refreshToken']
			Plasmoid.configuration.accessToken = metadata['accessToken']
			Plasmoid.configuration.accessTokenType = metadata['accessTokenType']
			Plasmoid.configuration.accessTokenExpiresAt = metadata['accessTokenExpiresAt']
			Plasmoid.configuration.calendarIdList = metadata['calendarIdList']
			Plasmoid.configuration.calendarList = metadata['calendarList']
			Plasmoid.configuration.tasklistIdList = metadata['tasklistIdList']
			Plasmoid.configuration.tasklistList = metadata['tasklistList']
			Plasmoid.configuration.agendaNewEventLastCalendarId = metadata['agendaNewEventLastCalendarId']
		})
	}

	function fetchCurrentUserConfig(callback) {
		var url = 'file:///home/chris/.config/plasma-org.kde.plasma.desktop-appletsrc'
		Requests.getFile(url, function(err, data) {
			if (err) {
				return callback(err)
			}

			var metadata = Requests.parseMetadata(data)
			callback(null, metadata)
		})
	}

	onFetchAllCalendars: {
		fetchDebugGoogleSession()
	}
}
