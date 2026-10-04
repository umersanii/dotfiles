import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    title: Translation.tr("Tasks")
    showCenterButton: true

    contentItem: TasksContent {
        radius: root.contentRadius
        isClickthrough: root.clickthrough
    }
}
