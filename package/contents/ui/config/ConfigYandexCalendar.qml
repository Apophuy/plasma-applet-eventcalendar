import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import ".."
import "../lib"

ConfigPage {
	id: page

	property string cfg_yandexAccounts: ""
	property bool connecting: false
	property string newAccountName: ""
	property string newAccountLogin: ""

	Base64JsonListModel {
		id: accountsModel
		configKey: "yandexAccounts"
		configPage: page
	}

	ExecUtil { id: executable }

	function helperPath() {
		return executable.urlToLocalPath(Qt.resolvedUrl("../../scripts/yandex_caldav.py"))
	}

	function newAccountId() {
		return "account-" + Date.now() + "-" + Math.floor(Math.random() * 1000000)
	}

	function runConnection(account, modelIndex, reconnect) {
		messageLabel.text = reconnect
			? i18n("Enter a new Yandex application password in the dialog.")
			: i18n("Enter the Yandex application password in the dialog.")
		page.connecting = true
		executable.exec([
			"python3", helperPath(), "connect",
			"--account-id", account.id,
			"--login", account.login,
			"--title", i18n("Apophuy Calendar"),
			"--prompt", i18n("Enter the Yandex Calendar application password:"),
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			page.connecting = false
			if (exitCode !== 0) {
				messageLabel.text = (stderr || i18n("Could not connect the Yandex account.")).trim()
				return
			}
			var response
			try {
				response = JSON.parse((stdout || "").trim())
			} catch (error) {
				messageLabel.text = i18n("Yandex Calendar returned invalid data.")
				return
			}
			account.calendars = response.calendars || []
			account.enabled = true
			if (modelIndex >= 0) {
				accountsModel.setItemProperty(modelIndex, "calendars", account.calendars)
				accountsModel.setItemProperty(modelIndex, "enabled", true)
			} else {
				accountsModel.addItem(account)
				page.newAccountName = ""
				page.newAccountLogin = ""
			}
			messageLabel.text = i18np("Connected. Found %1 calendar.", "Connected. Found %1 calendars.", account.calendars.length)
		})
	}

	function addAccount() {
		if (!newAccountLogin.trim()) {
			messageLabel.text = i18n("Enter the Yandex account login.")
			return
		}
		var login = newAccountLogin.trim()
		runConnection({
			id: newAccountId(),
			name: newAccountName.trim() || login,
			login: login,
			enabled: true,
			calendars: [],
		}, -1, false)
	}

	function refreshAccount(modelIndex) {
		var account = accountsModel.base64Json.value[modelIndex]
		page.connecting = true
		messageLabel.text = i18n("Refreshing Yandex calendars…")
		executable.exec([
			"python3", helperPath(), "discover",
			"--account-id", account.id,
			"--login", account.login,
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			page.connecting = false
			if (exitCode !== 0) {
				messageLabel.text = (stderr || i18n("Could not refresh the Yandex account.")).trim()
				return
			}
			var response
			try {
				response = JSON.parse((stdout || "").trim())
			} catch (error) {
				messageLabel.text = i18n("Yandex Calendar returned invalid data.")
				return
			}
			var previous = {}
			var oldCalendars = account.calendars || []
			for (var i = 0; i < oldCalendars.length; i++) {
				previous[oldCalendars[i].id] = oldCalendars[i]
			}
			var calendars = response.calendars || []
			for (var j = 0; j < calendars.length; j++) {
				if (previous[calendars[j].id]) {
					calendars[j].selected = previous[calendars[j].id].selected !== false
				}
			}
			accountsModel.setItemProperty(modelIndex, "calendars", calendars)
			messageLabel.text = i18n("Yandex calendar list updated.")
		})
	}

	function removeAccount(modelIndex) {
		var account = accountsModel.base64Json.value[modelIndex]
		executable.exec([
			"python3", helperPath(), "forget", "--account-id", account.id,
		], function() {})
		accountsModel.removeIndex(modelIndex)
	}

	function setCalendarSelected(accountIndex, calendarIndex, selected) {
		var account = accountsModel.base64Json.value[accountIndex]
		var calendars = account.calendars.slice(0)
		calendars[calendarIndex].selected = selected
		accountsModel.setItemProperty(accountIndex, "calendars", calendars)
	}

	HeaderText { text: i18n("Yandex accounts") }

	Label {
		Layout.fillWidth: true
		Layout.preferredWidth: 0
		wrapMode: Text.Wrap
		text: i18n("Create a Yandex application password for Calendar, then add the account here. Passwords are stored in KWallet and are not saved in the widget configuration.")
	}

	LinkText {
		Layout.fillWidth: true
		text: i18n("Create an application password at <a href=\"%1\">Yandex ID</a>.", "https://id.yandex.ru/security/app-passwords")
	}

	GroupBox {
		Layout.fillWidth: true
		title: i18n("Add account")
		ColumnLayout {
			anchors.fill: parent
			TextField {
				Layout.fillWidth: true
				placeholderText: i18n("Account name")
				text: page.newAccountName
				onTextEdited: page.newAccountName = text
			}
			TextField {
				Layout.fillWidth: true
				placeholderText: i18n("Yandex login or email")
				text: page.newAccountLogin
				onTextEdited: page.newAccountLogin = text
				onAccepted: page.addAccount()
			}
			Button {
				text: i18n("Connect account")
				icon.name: "list-add-user"
				enabled: !page.connecting && !!page.newAccountLogin.trim()
				onClicked: page.addAccount()
			}
		}
	}

	Label {
		id: messageLabel
		Layout.fillWidth: true
		Layout.preferredWidth: 0
		wrapMode: Text.Wrap
		visible: !!text
	}

	BusyIndicator {
		running: page.connecting
		visible: running
		Layout.alignment: Qt.AlignHCenter
	}

	Repeater {
		model: accountsModel
		delegate: GroupBox {
			id: accountDelegate
			required property int index
			property var accountData: accountsModel.get(index)
			Layout.fillWidth: true
			title: accountData.name || accountData.login

			ColumnLayout {
				anchors.fill: parent
				CheckBox {
					text: i18n("Enable this account")
					checked: accountDelegate.accountData.enabled !== false
					onClicked: accountsModel.setItemProperty(accountDelegate.index, "enabled", checked)
				}
				Label {
					text: accountDelegate.accountData.login
					opacity: 0.7
				}
				Repeater {
					model: accountDelegate.accountData.calendars || []
					delegate: CheckBox {
						required property int index
						required property var modelData
						text: modelData.summary
						checked: modelData.selected !== false
						onClicked: page.setCalendarSelected(accountDelegate.index, index, checked)
					}
				}
				RowLayout {
					Button {
						text: i18n("Refresh")
						icon.name: "view-refresh"
						enabled: !page.connecting
						onClicked: page.refreshAccount(accountDelegate.index)
					}
					Button {
						text: i18n("Change password")
						icon.name: "document-encrypted"
						enabled: !page.connecting
						onClicked: page.runConnection(accountDelegate.accountData, accountDelegate.index, true)
					}
					Item { Layout.fillWidth: true }
					Button {
						text: i18n("Remove")
						icon.name: "edit-delete"
						onClicked: page.removeAccount(accountDelegate.index)
					}
				}
			}
		}
	}
}
