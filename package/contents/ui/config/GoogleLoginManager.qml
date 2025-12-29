import QtQuick

import "../lib"
import "../lib/Requests.js" as Requests

Item {
	id: session

	Logger {
		id: logger
		showDebug: Plasmoid.configuration.debugging
	}

	// Active Session
	readonly property bool isLoggedIn: !!Plasmoid.configuration.accessToken
	readonly property bool needsRelog: {
		if (Plasmoid.configuration.accessToken && Plasmoid.configuration.latestClientId != Plasmoid.configuration.sessionClientId) {
			return true
		} else if (!Plasmoid.configuration.accessToken && Plasmoid.configuration.access_token) {
			return true
		} else {
			return false
		}
	}

	// Data
	property var m_calendarList: ConfigSerializedString {
		id: m_calendarList
		configKey: 'calendarList'
		defaultValue: []
	}
	property alias calendarList: m_calendarList.value

	property var m_calendarIdList: ConfigSerializedString {
		id: m_calendarIdList
		configKey: 'calendarIdList'
		defaultValue: []

		function serialize() {
			Plasmoid.configuration[configKey] = value.join(',')
		}
		function deserialize() {
			value = configValue.split(',')
		}
	}
	property alias calendarIdList: m_calendarIdList.value

	property var m_tasklistList: ConfigSerializedString {
		id: m_tasklistList
		configKey: 'tasklistList'
		defaultValue: []
	}
	property alias tasklistList: m_tasklistList.value

	property var m_tasklistIdList: ConfigSerializedString {
		id: m_tasklistIdList
		configKey: 'tasklistIdList'
		defaultValue: []

		function serialize() {
			Plasmoid.configuration[configKey] = value.join(',')
		}
		function deserialize() {
			value = configValue.split(',')
		}
	}
	property alias tasklistIdList: m_tasklistIdList.value


	//--- Signals
	signal newAccessToken()
	signal sessionReset()
	signal error(string err)


	//---
	readonly property string authorizationCodeUrl: {
		var url = 'https://accounts.google.com/o/oauth2/v2/auth'
		url += '?scope=' + encodeURIComponent('https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/tasks')
		url += '&response_type=code'
		url += '&redirect_uri=' + encodeURIComponent('urn:ietf:wg:oauth:2.0:oob')
		url += '&client_id=' + encodeURIComponent(Plasmoid.configuration.latestClientId)
		return url
	}

	function fetchAccessToken(args) {
		var url = 'https://www.googleapis.com/oauth2/v4/token'
		Requests.post({
			url: url,
			data: {
				client_id: Plasmoid.configuration.latestClientId,
				client_secret: Plasmoid.configuration.latestClientSecret,
				code: args.authorizationCode,
				grant_type: 'authorization_code',
				redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
			},
		}, function(err, data, xhr) {
			logger.debug('/oauth2/v4/token Response', data)

			// Check for errors
			if (err) {
				handleError(err, null)
				return
			}
			try {
				data = JSON.parse(data)
			} catch (e) {
				handleError('Error parsing /oauth2/v4/token data as JSON', null)
				return
			}
			if (data && data.error) {
				handleError(err, data)
				return
			}

			// Ready
			updateAccessToken(data)
		})
	}

	function updateAccessToken(data) {
		Plasmoid.configuration.sessionClientId = Plasmoid.configuration.latestClientId
		Plasmoid.configuration.sessionClientSecret = Plasmoid.configuration.latestClientSecret
		Plasmoid.configuration.accessToken = data.access_token
		Plasmoid.configuration.accessTokenType = data.token_type
		Plasmoid.configuration.accessTokenExpiresAt = Date.now() + data.expires_in * 1000
		Plasmoid.configuration.refreshToken = data.refresh_token
		newAccessToken()
	}

	onNewAccessToken: updateData()

	function updateData() {
		updateCalendarList()
		updateTasklistList()
	}

	function updateCalendarList() {
		logger.debug('updateCalendarList')
		logger.debug('accessToken', Plasmoid.configuration.accessToken)
		fetchGCalCalendars({
			accessToken: Plasmoid.configuration.accessToken,
		}, function(err, data, xhr) {
			// Check for errors
			if (err || data.error) {
				handleError(err, data)
				return
			}
			m_calendarList.value = data.items
		})
	}

	function fetchGCalCalendars(args, callback) {
		var url = 'https://www.googleapis.com/calendar/v3/users/me/calendarList'
		Requests.getJSON({
			url: url,
			headers: {
				"Authorization": "Bearer " + args.accessToken,
			}
		}, function(err, data, xhr) {
			// console.log('fetchGCalCalendars.response', err, data, xhr && xhr.status)
			if (!err && data && data.error) {
				return callback('fetchGCalCalendars error', data, xhr)
			}
			logger.debugJSON('fetchGCalCalendars.response.data', data)
			callback(err, data, xhr)
		})
	}

	function updateTasklistList() {
		logger.debug('updateTasklistList')
		logger.debug('accessToken', Plasmoid.configuration.accessToken)
		fetchGoogleTasklistList({
			accessToken: Plasmoid.configuration.accessToken,
		}, function(err, data, xhr) {
			// Check for errors
			if (err || data.error) {
				handleError(err, data)
				return
			}
			m_tasklistList.value = data.items
		})
	}

	function fetchGoogleTasklistList(args, callback) {
		var url = 'https://www.googleapis.com/tasks/v1/users/@me/lists'
		Requests.getJSON({
			url: url,
			headers: {
				"Authorization": "Bearer " + args.accessToken,
			}
		}, function(err, data, xhr) {
			console.log('fetchGoogleTasklistList.response', err, data, xhr && xhr.status)
			if (!err && data && data.error) {
				return callback('fetchGoogleTasklistList error', data, xhr)
			}
			logger.debugJSON('fetchGoogleTasklistList.response.data', data)
			callback(err, data, xhr)
		})
	}

	function logout() {
		Plasmoid.configuration.sessionClientId = ''
		Plasmoid.configuration.sessionClientSecret = ''
		Plasmoid.configuration.accessToken = ''
		Plasmoid.configuration.accessTokenType = ''
		Plasmoid.configuration.accessTokenExpiresAt = 0
		Plasmoid.configuration.refreshToken = ''

		// Delete relevant data
		// TODO: only target google calendar data
		// TODO: Make a signal?
		Plasmoid.configuration.agendaNewEventLastCalendarId = ''
		calendarList = []
		calendarIdList = []
		tasklistList = []
		tasklistIdList = []
		sessionReset()
	}

	// https://developers.google.com/calendar/v3/errors
	function handleError(err, data) {
		if (data && data.error && data.error_description) {
			var errorMessage = '' + data.error + ' (' + data.error_description + ')'
			session.error(errorMessage)
		} else if (data && data.error && data.error.message && typeof data.error.code !== "undefined") {
			var errorMessage = '' + data.error.message + ' (' + data.error.code + ')'
			session.error(errorMessage)
		} else if (err) {
			session.error(err)
		}
	}
}
