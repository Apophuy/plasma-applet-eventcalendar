import QtQuick
// import org.kde.plasma.networkmanagement 0.2 as PlasmaNM

QtObject {
	id: networkMonitor

	// https://invent.kde.org/plasma/plasma-nm
	// readonly property var plasmaNMStatus: PlasmaNM.NetworkStatus {
	// 	id: plasmaNMStatus
	// 	// onActiveConnectionsChanged: logger.debug('NetworkStatus.activeConnections', activeConnections)
	// 	onNetworkStatusChanged: logger.debug('NetworkStatus.networkStatus', networkStatus)
	// 	Component.onCompleted: {
	// 		// logger.debug('NetworkStatus.activeConnections', activeConnections)
	// 		logger.debug('NetworkStatus.networkStatus', networkStatus)
	// 	}
	// }
	// readonly property var plasmaNMIcon: PlasmaNM.ConnectionIcon {
	// 	id: plasmaNMIcon
	// 	onConnectingChanged: logger.debug('ConnectionIcon.connecting', connecting)
	// 	onConnectionIconChanged: logger.debug('ConnectionIcon.connectionIcon', connectionIcon)
	// 	onConnectionTooltipIconChanged: logger.debug('ConnectionIcon.connectionTooltipIcon', connectionTooltipIcon)
	// 	onNeedsPortalChanged: logger.debug('ConnectionIcon.needsPortal', needsPortal)
	// 	Component.onCompleted: {
	// 		logger.debug('ConnectionIcon.connecting', connecting)
	// 		logger.debug('ConnectionIcon.connectionIcon', connectionIcon)
	// 		logger.debug('ConnectionIcon.connectionTooltipIcon', connectionTooltipIcon)
	// 		logger.debug('ConnectionIcon.needsPortal', needsPortal)
	// 	}
	// }
	// readonly property var plasmaNMAvailableDevices: PlasmaNM.AvailableDevices {
	// 	id: plasmaNMAvailableDevices
	// 	onWiredDeviceAvailableChanged: logger.debug('AvailableDevices.wiredDeviceAvailable', wiredDeviceAvailable)
	// 	onWirelessDeviceAvailableChanged: logger.debug('AvailableDevices.wirelessDeviceAvailable', wirelessDeviceAvailable)
	// 	onModemDeviceAvailableChanged: logger.debug('AvailableDevices.modemDeviceAvailable', modemDeviceAvailable)
	// 	onBluetoothDeviceAvailableChanged: logger.debug('AvailableDevices.bluetoothDeviceAvailable', bluetoothDeviceAvailable)
	// 	Component.onCompleted: {
	// 		logger.debug('AvailableDevices.wiredDeviceAvailable', wiredDeviceAvailable)
	// 		logger.debug('AvailableDevices.wirelessDeviceAvailable', wirelessDeviceAvailable)
	// 		logger.debug('AvailableDevices.modemDeviceAvailable', modemDeviceAvailable)
	// 		logger.debug('AvailableDevices.bluetoothDeviceAvailable', bluetoothDeviceAvailable)
	// 	}
	// }



	// We need to dynamically import PlasmaNM since it's not preinstalled on every distro (Issue #212)
	// readonly property var plasmaNMStatus: Qt.createQmlObject("import org.kde.plasma.networkmanagement 0.2 as PlasmaNM; PlasmaNM.NetworkStatus {}", networkMonitor)
	readonly property Loader plasmaNMStatusLoader: Loader {
		id: plasmaNMStatusLoader
		source: "NetworkMonitorPlasmaNM.qml"
	}


	readonly property int connectivity: {
		if (plasmaNMStatusLoader.status == Loader.Ready) {
			return plasmaNMStatusLoader.item.connectivity
		} else {
			return -1
		}
	}
	readonly property bool isConnected: {
		if (plasmaNMStatusLoader.status == Loader.Error) {
			// Failed to load PlasmaNM, so treat it as connected.
			return true
		} else {
			// NetworkManager::Connectivity::Full is 4. Portal and Limited do not
			// provide reliable access to the remote APIs used by the widget.
			return connectivity >= 4
		}
	}

	onIsConnectedChanged: logger.debug('NetworkMonitor.isConnected', isConnected)
	Component.onCompleted: {
		logger.debug('NetworkMonitor.isConnected', isConnected)
	}
}
