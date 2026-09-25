import QtQuick

import "../lib"
import "../lib/Requests.js" as Requests

Item {
	id: session

	// Configuration properties - must be bound from parent
	property bool cfg_debugging: false
	property string cfg_accessToken: ""
	property string cfg_accessTokenType: ""
	property double cfg_accessTokenExpiresAt: 0
	property string cfg_refreshToken: ""
	property string cfg_latestClientId: ""
	property string cfg_latestClientSecret: ""
	property string cfg_sessionClientId: ""
	property string cfg_sessionClientSecret: ""
	property string cfg_calendarList: ""
	property string cfg_calendarIdList: ""
	property string cfg_tasklistList: ""
	property string cfg_tasklistIdList: ""
	property string cfg_access_token: "" // legacy
	property string cfg_agendaNewEventLastCalendarId: ""

	Logger {
		id: logger
		showDebug: session.cfg_debugging
	}

	// Active Session
	readonly property bool isLoggedIn: !!cfg_accessToken
	readonly property bool needsRelog: {
		if (cfg_accessToken && cfg_latestClientId != cfg_sessionClientId) {
			return true
		} else if (!cfg_accessToken && cfg_access_token) {
			return true
		} else {
			return false
		}
	}

	// Data - calendar list
	property var calendarListValue: {
		if (cfg_calendarList) {
			try {
				return JSON.parse(Qt.atob(cfg_calendarList))
			} catch (e) {
				return []
			}
		}
		return []
	}

	property var calendarList: calendarListValue

	function setCalendarListValue(value) {
		cfg_calendarList = Qt.btoa(JSON.stringify(value || []))
	}

	// Data - calendar id list
	property var calendarIdListValue: cfg_calendarIdList ? cfg_calendarIdList.split(',') : []

	property var calendarIdList: calendarIdListValue

	onCalendarIdListChanged: {
		var serialized = (calendarIdList || []).join(',')
		if (cfg_calendarIdList !== serialized) {
			cfg_calendarIdList = serialized
		}
	}
	onCfg_calendarIdListChanged: {
		var serialized = (calendarIdList || []).join(',')
		if (serialized !== cfg_calendarIdList) {
			calendarIdList = cfg_calendarIdList ? cfg_calendarIdList.split(',') : []
		}
	}

	// Data - tasklist list
	property var tasklistListValue: {
		if (cfg_tasklistList) {
			try {
				return JSON.parse(Qt.atob(cfg_tasklistList))
			} catch (e) {
				return []
			}
		}
		return []
	}

	property var tasklistList: tasklistListValue

	function setTasklistListValue(value) {
		cfg_tasklistList = Qt.btoa(JSON.stringify(value || []))
		// Signal emitted automatically when cfg_tasklistList changes
	}

	// Data - tasklist id list
	property var tasklistIdListValue: cfg_tasklistIdList ? cfg_tasklistIdList.split(',') : []

	property var tasklistIdList: tasklistIdListValue

	onTasklistIdListChanged: {
		var serialized = (tasklistIdList || []).join(',')
		if (cfg_tasklistIdList !== serialized) {
			cfg_tasklistIdList = serialized
		}
	}
	onCfg_tasklistIdListChanged: {
		var serialized = (tasklistIdList || []).join(',')
		if (serialized !== cfg_tasklistIdList) {
			tasklistIdList = cfg_tasklistIdList ? cfg_tasklistIdList.split(',') : []
		}
	}


	//--- Signals
	signal newAccessToken()
	signal sessionReset()
	signal error(string err)


	function updateAccessToken(data) {
		cfg_sessionClientId = cfg_latestClientId
		cfg_sessionClientSecret = cfg_latestClientSecret
		cfg_accessToken = data.access_token || ''
		cfg_accessTokenType = data.token_type || 'Bearer'
		cfg_accessTokenExpiresAt = Date.now() + (data.expires_in || 0) * 1000
		if (data.refresh_token) {
			cfg_refreshToken = data.refresh_token
		}
		newAccessToken()
	}

	onNewAccessToken: updateData()

	function updateData() {
		updateCalendarList()
		updateTasklistList()
	}

	function updateCalendarList() {
		logger.debug('updateCalendarList')
		fetchGCalCalendars({
			accessToken: cfg_accessToken,
		}, function(err, data, xhr) {
			// Check for errors
			if (err || !data || data.error) {
				handleError(err, data)
				return
			}
			setCalendarListValue(data.items || [])
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
		fetchGoogleTasklistList({
			accessToken: cfg_accessToken,
		}, function(err, data, xhr) {
			// Check for errors
			if (err || !data || data.error) {
				handleError(err, data)
				return
			}
			setTasklistListValue(data.items || [])
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
			if (!err && data && data.error) {
				return callback('fetchGoogleTasklistList error', data, xhr)
			}
			logger.debugJSON('fetchGoogleTasklistList.response.data', data)
			callback(err, data, xhr)
		})
	}

	function logout() {
		cfg_sessionClientId = ''
		cfg_sessionClientSecret = ''
		cfg_accessToken = ''
		cfg_accessTokenType = ''
		cfg_accessTokenExpiresAt = 0
		cfg_refreshToken = ''

		// Delete relevant data
		cfg_agendaNewEventLastCalendarId = ''
		setCalendarListValue([])
		calendarIdList = []
		setTasklistListValue([])
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
