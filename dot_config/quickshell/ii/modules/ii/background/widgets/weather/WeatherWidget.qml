import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "weather"

    implicitHeight: backgroundShape.implicitHeight
    implicitWidth: backgroundShape.implicitWidth

    StyledDropShadow {
        target: backgroundShape
    }

    MaterialShape {
        id: backgroundShape
        anchors.fill: parent
        shape: MaterialShape.Shape.Pill
        color: Appearance.colors.colPrimaryContainer
        implicitSize: 210

        StyledText {
            textFormat: Text.StyledText
            font {
                pixelSize: 66
                family: Appearance.font.family.expressive
                weight: Font.Medium
            }
            color: Appearance.colors.colPrimary
            text: (Weather.data?.temp.substring(0,Weather.data?.temp.length - 2) ?? "--") + "<span style=\"vertical-align:super;font-size:55%\">°</span>"
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 26
                topMargin: 38
            }
        }

        WeatherSymbol {
            iconSize: 58
            baseColor: Appearance.colors.colOnPrimaryContainer
            icon: Icons.getWeatherIcon(Weather.data.wCode, Weather.data.isDay) ?? "cloud"
            anchors {
                left: parent.left
                bottom: parent.bottom

                leftMargin: 26
                bottomMargin: 32
            }
        }
    }
}
