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

	function clearMenuItems() {
		while (contextMenu.count > 0) {
			var subMenu = contextMenu.menuAt(0)
			if (subMenu) {
				contextMenu.removeMenu(subMenu)
				subMenu.destroy()
			} else {
				var menuItem = contextMenu.takeItem(0)
				if (menuItem) {
					menuItem.destroy()
				}
			}
		}
	}

	function newSeperator(parentMenu) {
		var targetMenu = parentMenu || contextMenu
		return Qt.createQmlObject("import QtQuick.Controls as QQC2; QQC2.MenuSeparator {}", targetMenu.contentItem)
	}

	function newMenuItem(parentMenu, properties) {
		var targetMenu = parentMenu || contextMenu
		return menuItemComponent.createObject(targetMenu.contentItem, properties || {})
	}

	function newSubMenu(parentMenu, properties) {
		var targetMenu = parentMenu || contextMenu
		var subMenu = Qt.createComponent("ContextMenu.qml").createObject(targetMenu.contentItem)
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
