import QtQuick
import QtQuick.Controls as QQC2

QQC2.Menu {
	id: contextMenu

	signal populate(var contextMenu)

	// Force loading of MenuItem.qml so dynamic creation *should* be synchronous.
	// It's a property since the default content property of Menu doesn't like it.
	property var menuItemComponent: Component {
		MenuItem {}
	}

	// Compatibility property
	property var content: contextMenu.contentData

	function clearMenuItems() {
		while (contextMenu.count > 0) {
			contextMenu.removeItem(contextMenu.itemAt(0))
		}
	}

	function newSeperator(parentMenu) {
		return Qt.createQmlObject("import QtQuick.Controls as QQC2; QQC2.MenuSeparator {}", parentMenu || contextMenu)
	}

	function newMenuItem(parentMenu, properties) {
		return menuItemComponent.createObject(parentMenu || contextMenu, properties || {})
	}

	function newSubMenu(parentMenu, properties) {
		var subMenu = Qt.createComponent("ContextMenu.qml").createObject(parentMenu || contextMenu)
		if (properties && properties.text) {
			subMenu.title = properties.text
		}
		return subMenu
	}

	function loadMenu() {
		contextMenu.clearMenuItems()
		populate(contextMenu)
	}

	function show(x, y) {
		loadMenu()
		if (contextMenu.count > 0) {
			contextMenu.popup(x, y)
		}
	}

	function showBelow(item) {
		loadMenu()
		if (contextMenu.count > 0) {
			contextMenu.popup(item, 0, item.height)
		}
	}
}
