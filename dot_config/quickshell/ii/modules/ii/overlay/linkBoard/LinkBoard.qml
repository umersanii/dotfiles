import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    title: Translation.tr("Links")
    showCenterButton: true

    contentItem: LinkBoardContent {
        radius: root.contentRadius
        isClickthrough: root.clickthrough
    }
}
