import QtQuick
import QtQuick.Controls
// QtQuick.Controls.Styles is deprecated in Qt6
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import ".."
import "../lib"

ConfigPage {
	id: page
	property bool loginInProgress: false

	// Required cfg_ properties for GoogleLoginManager
	property bool cfg_debugging: false
	property string cfg_accessToken: ""
	property alias cfg_accessTokenType: googleLoginManager.cfg_accessTokenType
	property alias cfg_accessTokenExpiresAt: googleLoginManager.cfg_accessTokenExpiresAt
	property alias cfg_refreshToken: googleLoginManager.cfg_refreshToken
	property string cfg_latestClientId: ""
	property string cfg_latestClientSecret: ""
	property alias cfg_sessionClientId: googleLoginManager.cfg_sessionClientId
	property alias cfg_sessionClientSecret: googleLoginManager.cfg_sessionClientSecret
	property alias cfg_calendarList: googleLoginManager.cfg_calendarList
	property alias cfg_calendarIdList: googleLoginManager.cfg_calendarIdList
	property alias cfg_tasklistList: googleLoginManager.cfg_tasklistList
	property alias cfg_tasklistIdList: googleLoginManager.cfg_tasklistIdList
	property string cfg_access_token: "" // legacy
	property alias cfg_agendaNewEventLastCalendarId: googleLoginManager.cfg_agendaNewEventLastCalendarId
	property string cfg_googleEventClickAction: "WebEventView"
	property bool cfg_googleHideGoalsDesc: true

	function alphaColor(c, a) {
		return Qt.rgba(c.r, c.g, c.b, a)
	}
	readonly property color readablePositiveTextColor: Qt.tint(Kirigami.Theme.textColor, alphaColor(Kirigami.Theme.positiveTextColor, 0.5))
	readonly property color readableNegativeTextColor: Qt.tint(Kirigami.Theme.textColor, alphaColor(Kirigami.Theme.negativeTextColor, 0.5))

	function sortByKey(key, a, b){
		if (typeof a[key] === "string") {
			return a[key].toLowerCase().localeCompare(b[key].toLowerCase())
		} else if (typeof a[key] === "number") {
			return a[key] - b[key]
		} else {
			return 0
		}
	}
	function sortArr(arr, predicate) {
		if (typeof predicate === "string") { // predicate is a key
			predicate = sortByKey.bind(null, predicate)
		}
		return arr.concat().sort(predicate)
	}

	function oauthErrorMessage(exitCode) {
		switch (exitCode) {
		case 2:
			return i18n("Google OAuth client credentials are not configured.")
		case 3:
			return i18n("Could not start the local Google login callback.")
		case 4:
			return i18n("Could not open the default web browser.")
		case 5:
			return i18n("Google login timed out. Please try again.")
		case 6:
			return i18n("Google login was cancelled or rejected.")
		default:
			return i18n("Google login failed. Please try again.")
		}
	}

	function startGoogleLogin() {
		if (!page.cfg_latestClientId) {
			messageWidget.err(oauthErrorMessage(2))
			return
		}

		messageWidget.info(i18n("Opening Google login in your web browser…"))
		page.loginInProgress = true
		var helperPath = oauthHelper.urlToLocalPath(Qt.resolvedUrl("../../scripts/google_oauth.py"))
		oauthHelper.exec([
			"python3",
			helperPath,
			"--client-id", page.cfg_latestClientId,
			"--client-secret", page.cfg_latestClientSecret,
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			page.loginInProgress = false
			if (exitCode !== 0) {
				console.warn("Google OAuth helper failed:", exitCode, stderr)
				messageWidget.err(page.oauthErrorMessage(exitCode))
				return
			}

			var tokenData
			try {
				tokenData = JSON.parse((stdout || "").trim())
			} catch (error) {
				console.warn("Could not parse Google OAuth helper response:", error)
				messageWidget.err(i18n("Google login returned an invalid response."))
				return
			}
			if (!tokenData || !tokenData.access_token) {
				messageWidget.err(i18n("Google login did not return an access token."))
				return
			}

			googleLoginManager.updateAccessToken(tokenData)
			messageWidget.success(i18n("Google Calendar is connected."))
		})
	}

	ExecUtil {
		id: oauthHelper
	}

	GoogleLoginManager {
		id: googleLoginManager

		// Bind configuration properties
		cfg_debugging: page.cfg_debugging
		cfg_accessToken: page.cfg_accessToken
		cfg_latestClientId: page.cfg_latestClientId
		cfg_latestClientSecret: page.cfg_latestClientSecret
		cfg_access_token: page.cfg_access_token

		onCfg_accessTokenChanged: page.cfg_accessToken = cfg_accessToken

		onCalendarListChanged: {
			calendarsModel.clear()
			var sortedList = sortArr(calendarList, "summary")
			for (var i = 0; i < sortedList.length; i++) {
				var item = sortedList[i]
				// console.log(JSON.stringify(item))
				var isPrimary = item.primary === true
				var isShown = calendarIdList.indexOf(item.id) >= 0 || (isPrimary && calendarIdList.indexOf('primary') >= 0)
				calendarsModel.append({
					calendarId: item.id,
					name: item.summary,
					description: item.description,
					backgroundColor: item.backgroundColor,
					foregroundColor: item.foregroundColor,
					show: isShown,
					isReadOnly: item.accessRole == "reader",
				})
				// console.log(item.summary, isShown, item.id)
			}
			calendarsModel.calendarsShownChanged()
		}

		onTasklistListChanged: {
			tasklistsModel.clear()
			var sortedList = sortArr(tasklistList, "title")
			for (var i = 0; i < sortedList.length; i++) {
				var item = sortedList[i]
				// console.log(JSON.stringify(item))
				var isShown = tasklistIdList.indexOf(item.id) >= 0
				tasklistsModel.append({
					tasklistId: item.id,
					name: item.title,
					description: '',
					backgroundColor: Kirigami.Theme.highlightColor.toString(),
					foregroundColor: Kirigami.Theme.highlightedTextColor.toString(),
					show: isShown,
					isReadOnly: false,
				})
				// console.log(item.summary, isShown, item.id)
			}
			tasklistsModel.tasklistsShownChanged()
		}

		onError: messageWidget.err(err)
	}


	HeaderText {
		text: i18n("Login")
	}
	MessageWidget {
		id: messageWidget
	}
	ColumnLayout {
		visible: googleLoginManager.isLoggedIn
		Label {
			Layout.fillWidth: true
			text: i18n("Currently Synched.")
			color: readablePositiveTextColor
			wrapMode: Text.Wrap
		}
		Button {
			text: i18n("Logout")
			onClicked: {
				googleLoginManager.logout()
				calendarsModel.clear()
			}
		}
		MessageWidget {
			visible: googleLoginManager.needsRelog
			text: i18n("Widget has been updated. Please logout and login to Google Calendar again.")
		}
	}
	ColumnLayout {
		visible: !googleLoginManager.isLoggedIn
		Label {
			Layout.fillWidth: true
			text: i18n("Sign in with Google to sync Calendar events and Tasks. The browser returns securely to this computer after approval.")
			color: readableNegativeTextColor
			wrapMode: Text.Wrap
		}
		RowLayout {
			Button {
				text: i18n("Login with Google")
				icon.name: "internet-services"
				enabled: !page.loginInProgress
				onClicked: page.startGoogleLogin()
			}
			QQC2.BusyIndicator {
				running: page.loginInProgress
				visible: running
			}
		}
	}

	RowLayout {
		Layout.fillWidth: true
		visible: googleLoginManager.isLoggedIn

		HeaderText {
			text: i18n("Calendars")
		}

		Button {
			icon.name: "view-refresh"
			text: i18n("Refresh")
			onClicked: googleLoginManager.updateCalendarList()
		}
	}
	ColumnLayout {
		spacing: Kirigami.Units.smallSpacing * 2
		Layout.fillWidth: true
		visible: googleLoginManager.isLoggedIn

		ListModel {
			id: calendarsModel

			signal calendarsShownChanged()

			onCalendarsShownChanged: {
				var calendarIdList = []
				for (var i = 0; i < calendarsModel.count; i++) {
					var item = calendarsModel.get(i)
					if (item.show) {
						calendarIdList.push(item.calendarId)
					}
				}
				googleLoginManager.calendarIdList = calendarIdList
			}
		}

		ColumnLayout {
			Layout.fillWidth: true

			Repeater {
				model: calendarsModel
				delegate: CheckBox {
					id: calendarCheckBox
					checked: model.show
					contentItem: RowLayout {
						spacing: Kirigami.Units.smallSpacing
						Item { width: calendarCheckBox.indicator.width } // Spacer for indicator
						Rectangle {
							Layout.preferredWidth: Kirigami.Units.iconSizes.small
							Layout.preferredHeight: Kirigami.Units.iconSizes.small
							color: model.backgroundColor
						}
						Label {
							text: model.name
						}
						LockIcon {
							Layout.preferredWidth: Kirigami.Units.iconSizes.small
							Layout.preferredHeight: Kirigami.Units.iconSizes.small
							visible: model.isReadOnly
						}
					}

					onClicked: {
						calendarsModel.setProperty(index, 'show', checked)
						calendarsModel.calendarsShownChanged()
					}
				}
			}
		}
	}

	RowLayout {
		Layout.fillWidth: true
		visible: googleLoginManager.isLoggedIn

		HeaderText {
			text: i18n("Tasks")

			Image {
				source: "../icons/google_tasks_96px.png"
				smooth: true
				anchors.leftMargin: parent.contentWidth + Kirigami.Units.smallSpacing
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				width: Kirigami.Units.iconSizes.smallMedium
				height: Kirigami.Units.iconSizes.smallMedium
			}
		}

		Button {
			icon.name: "view-refresh"
			text: i18n("Refresh")
			onClicked: googleLoginManager.updateTasklistList()
		}
	}
	ColumnLayout {
		spacing: Kirigami.Units.smallSpacing * 2
		Layout.fillWidth: true
		visible: googleLoginManager.isLoggedIn

		ListModel {
			id: tasklistsModel

			signal tasklistsShownChanged()

			onTasklistsShownChanged: {
				var tasklistIdList = []
				for (var i = 0; i < tasklistsModel.count; i++) {
					var item = tasklistsModel.get(i)
					if (item.show) {
						tasklistIdList.push(item.tasklistId)
					}
				}
				googleLoginManager.tasklistIdList = tasklistIdList
			}
		}

		ColumnLayout {
			Layout.fillWidth: true

			Repeater {
				model: tasklistsModel
				delegate: CheckBox {
					id: tasklistCheckBox
					checked: model.show
					contentItem: RowLayout {
						spacing: Kirigami.Units.smallSpacing
						Item { width: tasklistCheckBox.indicator.width } // Spacer for indicator
						Rectangle {
							Layout.preferredWidth: Kirigami.Units.iconSizes.small
							Layout.preferredHeight: Kirigami.Units.iconSizes.small
							color: model.backgroundColor
						}
						Label {
							text: model.name
						}
						LockIcon {
							Layout.preferredWidth: Kirigami.Units.iconSizes.small
							Layout.preferredHeight: Kirigami.Units.iconSizes.small
							visible: model.isReadOnly
						}
					}

					onClicked: {
						tasklistsModel.setProperty(index, 'show', checked)
						tasklistsModel.tasklistsShownChanged()
					}
				}
			}
		}
	}

	HeaderText {
		text: i18n("Options")
		visible: googleLoginManager.isLoggedIn
	}

	ColumnLayout {
		Layout.fillWidth: true
		visible: googleLoginManager.isLoggedIn

		ConfigRadioButtonGroup {
			id: googleEventClickAction
			label: i18n("Event Click:")
			configKey: 'googleEventClickAction'
			model: [
				{ value: 'WebEventView', text: i18n("Open Web Event View") },
				{ value: 'WebMonthView', text: i18n("Open Web Month View") },
			]
		}

		ConfigCheckBox {
			configKey: 'googleHideGoalsDesc'
			text: i18n("Hide \"This event was added from Goals in Google Calendar\" description")
		}
	}

	Component.onCompleted: {
		if (googleLoginManager.isLoggedIn) {
			googleLoginManager.calendarListChanged()
			googleLoginManager.tasklistListChanged()
		}
	}
}
