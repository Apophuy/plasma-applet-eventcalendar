#!/bin/bash

# Migration script for Plasma 6 / Qt6 compatibility
# This script updates all QML files in the project

PROJECT_DIR="/home/ismailov/Projects/plasma-applet-eventcalendar"
UI_DIR="$PROJECT_DIR/package/contents/ui"

echo "=== Plasma 6 Migration Script ==="
echo "Processing files in: $UI_DIR"

# Find all QML files (excluding main.qml which is already updated)
QML_FILES=$(find "$UI_DIR" -name "*.qml" ! -name "main.qml")

# Also include config.qml
QML_FILES="$QML_FILES $PROJECT_DIR/package/contents/config/config.qml"

for file in $QML_FILES; do
    if [ -f "$file" ]; then
        echo "Processing: $file"

        # 1. Remove version numbers from imports
        # QtQuick, QtQuick.Controls, QtQuick.Layouts, QtQuick.Window
        sed -i 's/import QtQuick 2\.[0-9]\+/import QtQuick/g' "$file"
        sed -i 's/import QtQuick\.Controls 2\.[0-9]\+/import QtQuick.Controls/g' "$file"
        sed -i 's/import QtQuick\.Layouts 1\.[0-9]\+/import QtQuick.Layouts/g' "$file"
        sed -i 's/import QtQuick\.Window 2\.[0-9]\+/import QtQuick.Window/g' "$file"
        sed -i 's/import QtMultimedia 5\.[0-9]\+/import QtMultimedia/g' "$file"

        # 2. Update PlasmaCore import (remove version)
        sed -i 's/import org\.kde\.plasma\.core 2\.[0-9]\+ as PlasmaCore/import org.kde.plasma.core as PlasmaCore/g' "$file"

        # 3. Update PlasmaComponents 2.0 to PlasmaComponents3 (no version)
        sed -i 's/import org\.kde\.plasma\.components 2\.[0-9]\+ as PlasmaComponents/import org.kde.plasma.components as PlasmaComponents3/g' "$file"

        # 4. Update PlasmaComponents3 import (remove version if present)
        sed -i 's/import org\.kde\.plasma\.components 3\.[0-9]\+ as PlasmaComponents3/import org.kde.plasma.components as PlasmaComponents3/g' "$file"
        sed -i 's/import org\.kde\.plasma\.components 3\.0 as PlasmaComponents3/import org.kde.plasma.components as PlasmaComponents3/g' "$file"

        # 5. Update PlasmaExtras import (remove version)
        sed -i 's/import org\.kde\.plasma\.extras 2\.[0-9]\+ as PlasmaExtras/import org.kde.plasma.extras as PlasmaExtras/g' "$file"

        # 6. Update Kirigami import (remove version) and add if needed
        sed -i 's/import org\.kde\.kirigami 2\.[0-9]\+ as Kirigami/import org.kde.kirigami as Kirigami/g' "$file"

        # 7. Update KQuickControlsAddons import
        sed -i 's/import org\.kde\.kquickcontrolsaddons 2\.[0-9]\+/import org.kde.kquickcontrolsaddons/g' "$file"

        # 8. Replace PlasmaCore.Units with Kirigami.Units
        sed -i 's/PlasmaCore\.Units\./Kirigami.Units./g' "$file"

        # 9. Replace standalone units.* with Kirigami.Units.* (careful with variable names)
        # This handles: units.smallSpacing, units.largeSpacing, units.gridUnit, units.iconSizes, units.devicePixelRatio
        sed -i 's/\bunits\.smallSpacing/Kirigami.Units.smallSpacing/g' "$file"
        sed -i 's/\bunits\.largeSpacing/Kirigami.Units.largeSpacing/g' "$file"
        sed -i 's/\bunits\.gridUnit/Kirigami.Units.gridUnit/g' "$file"
        sed -i 's/\bunits\.iconSizes/Kirigami.Units.iconSizes/g' "$file"
        sed -i 's/\bunits\.devicePixelRatio/Kirigami.Units.devicePixelRatio/g' "$file"

        # 10. Replace theme.* with Kirigami.Theme.*
        sed -i 's/\btheme\.textColor/Kirigami.Theme.textColor/g' "$file"
        sed -i 's/\btheme\.highlightColor/Kirigami.Theme.highlightColor/g' "$file"
        sed -i 's/\btheme\.highlightedTextColor/Kirigami.Theme.highlightedTextColor/g' "$file"
        sed -i 's/\btheme\.backgroundColor/Kirigami.Theme.backgroundColor/g' "$file"
        sed -i 's/\btheme\.viewBackgroundColor/Kirigami.Theme.backgroundColor/g' "$file"
        sed -i 's/\btheme\.complementaryTextColor/Kirigami.Theme.textColor/g' "$file"
        sed -i 's/\btheme\.complementaryBackgroundColor/Kirigami.Theme.backgroundColor/g' "$file"
        sed -i 's/\btheme\.disabledTextColor/Kirigami.Theme.disabledTextColor/g' "$file"
        sed -i 's/\btheme\.positiveTextColor/Kirigami.Theme.positiveTextColor/g' "$file"
        sed -i 's/\btheme\.negativeTextColor/Kirigami.Theme.negativeTextColor/g' "$file"
        sed -i 's/\btheme\.neutralTextColor/Kirigami.Theme.neutralTextColor/g' "$file"
        sed -i 's/\btheme\.linkColor/Kirigami.Theme.linkColor/g' "$file"
        sed -i 's/\btheme\.visitedLinkColor/Kirigami.Theme.visitedLinkColor/g' "$file"
        sed -i 's/\btheme\.defaultFont/Kirigami.Theme.defaultFont/g' "$file"
        sed -i 's/\btheme\.smallestFont/Kirigami.Theme.smallFont/g' "$file"
        sed -i 's/\btheme\.mSize/Qt.fontMetrics/g' "$file"

        # 11. Replace PlasmaCore.IconItem with Kirigami.Icon
        sed -i 's/PlasmaCore\.IconItem/Kirigami.Icon/g' "$file"

        # 12. Replace PlasmaCore.DataSource with Plasma5Support.DataSource
        sed -i 's/PlasmaCore\.DataSource/Plasma5Support.DataSource/g' "$file"

        # 13. Replace plasmoid.configuration with Plasmoid.configuration
        sed -i 's/\bplasmoid\.configuration\./Plasmoid.configuration./g' "$file"
        sed -i 's/\bplasmoid\.configuration\b/Plasmoid.configuration/g' "$file"

        # 14. Replace plasmoid.nativeInterface with Plasmoid
        sed -i 's/\bplasmoid\.nativeInterface\./Plasmoid./g' "$file"

        # 15. Replace PlasmaExtras.Heading with Kirigami.Heading
        sed -i 's/PlasmaExtras\.Heading/Kirigami.Heading/g' "$file"

        # 16. Replace PlasmaCore.FrameSvgItem with KSvg.FrameSvgItem
        sed -i 's/PlasmaCore\.FrameSvgItem/KSvg.FrameSvgItem/g' "$file"
        sed -i 's/PlasmaCore\.SvgItem/KSvg.SvgItem/g' "$file"
        sed -i 's/PlasmaCore\.Svg/KSvg.Svg/g' "$file"

        # 17. Replace PlasmaCore.ToolTipArea with PlasmaExtras.ToolTip (needs manual review)
        # This is complex, leaving for manual review

        # 18. Replace PlasmaCore.ColorScope with Kirigami.Theme (for colorGroup/inherit)
        sed -i 's/PlasmaCore\.ColorScope/Kirigami.Theme/g' "$file"
        sed -i 's/colorGroup: PlasmaCore\.Theme\.ComplementaryColorGroup/Kirigami.Theme.inherit: false/g' "$file"

        # 19. Replace PlasmaCore.Theme.* color references
        sed -i 's/PlasmaCore\.Theme\.textColor/Kirigami.Theme.textColor/g' "$file"
        sed -i 's/PlasmaCore\.Theme\.highlightColor/Kirigami.Theme.highlightColor/g' "$file"
        sed -i 's/PlasmaCore\.Theme\.backgroundColor/Kirigami.Theme.backgroundColor/g' "$file"

    fi
done

echo ""
echo "=== Adding missing imports ==="

# Add Kirigami import where needed but missing
for file in $QML_FILES; do
    if [ -f "$file" ]; then
        # Check if file uses Kirigami but doesn't have the import
        if grep -q "Kirigami\." "$file" && ! grep -q "import org.kde.kirigami" "$file"; then
            echo "Adding Kirigami import to: $file"
            # Add after the first QtQuick import
            sed -i '/^import QtQuick$/a import org.kde.kirigami as Kirigami' "$file"
            sed -i '/^import QtQuick\.Layouts$/a import org.kde.kirigami as Kirigami' "$file"
        fi

        # Check if file uses Plasma5Support but doesn't have the import
        if grep -q "Plasma5Support\." "$file" && ! grep -q "import org.kde.plasma.plasma5support" "$file"; then
            echo "Adding Plasma5Support import to: $file"
            sed -i '/^import org.kde.plasma.core/a import org.kde.plasma.plasma5support as Plasma5Support' "$file"
        fi

        # Check if file uses KSvg but doesn't have the import
        if grep -q "KSvg\." "$file" && ! grep -q "import org.kde.ksvg" "$file"; then
            echo "Adding KSvg import to: $file"
            sed -i '/^import org.kde.plasma.core/a import org.kde.ksvg as KSvg' "$file"
        fi
    fi
done

echo ""
echo "=== Migration complete ==="
echo "Please review the changes and test the widget."
echo ""
echo "Files that may need manual review:"
grep -l "PlasmaCore\.ToolTipArea" $QML_FILES 2>/dev/null || echo "  (none found)"
echo ""
echo "Files still using PlasmaCore:"
grep -l "PlasmaCore\." $QML_FILES 2>/dev/null | head -10 || echo "  (none found)"
