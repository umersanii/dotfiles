import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
	id: root

	property int implicitSize: 20
	property int lineWidth: Appearance.rounding.unsharpen
	property real value: 0
	property color colPrimary: Appearance.colors.colOnSecondaryContainer
	property color colSecondary: Appearance.colors.colSecondaryContainer
	property bool enableAnimation: true
	property int animationDuration: 800
	property var easingType: Easing.OutCubic
	property bool accountForLightBleeding: false
	default property alias contentData: contentItem.data

	implicitWidth: implicitSize
	implicitHeight: implicitSize

	CircularProgress {
		id: progress
		anchors.fill: parent
		lineWidth: root.lineWidth
		value: root.value
		colPrimary: root.colPrimary
		colSecondary: root.colSecondary
		fill: true
		fillOverflow: root.accountForLightBleeding ? 3 : 2
		enableAnimation: root.enableAnimation
		animationDuration: root.animationDuration
		easingType: root.easingType
	}

	Item {
		id: contentItem
		anchors.centerIn: parent
	}
}
