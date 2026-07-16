import qs.modules.common
import QtQuick

// Weather icon composed Google Weather style: a cloud glyph in the base color
// with a small colored accent glyph (rain drop, snowflake, bolt, peeking sun)
// positioned relative to it, per Icons.weatherComposeMap. Icons without an
// entry render as a plain MaterialSymbol; entries with only a color tint the
// whole glyph (cloudless sun/moon).
Item {
    id: root
    property string icon: "cloud"
    property real iconSize: Appearance?.font.pixelSize.small ?? 16
    property real fill: 0
    property color baseColor: "white"

    readonly property var comp: Icons.weatherComposeMap[icon]
    readonly property var accent: comp?.accent

    implicitWidth: base.implicitWidth
    implicitHeight: base.implicitHeight

    component AccentSymbol: MaterialSymbol {
        text: root.accent?.icon ?? ""
        iconSize: root.iconSize * (root.accent?.size ?? 0)
        fill: root.accent?.fill ?? 1
        color: root.accent?.color ?? root.baseColor
        x: (root.accent?.cx ?? 0) * base.width - width / 2
        y: (root.accent?.cy ?? 0) * base.height - height / 2
    }

    AccentSymbol {
        visible: root.accent !== undefined && root.accent.behind === true
    }

    MaterialSymbol {
        id: base
        text: root.comp?.base ?? root.icon
        iconSize: root.iconSize
        fill: root.fill
        color: root.comp?.color ?? root.baseColor
    }

    AccentSymbol {
        visible: root.accent !== undefined && root.accent.behind !== true
    }
}
