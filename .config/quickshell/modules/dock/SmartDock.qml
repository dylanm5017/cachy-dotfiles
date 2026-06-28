import QtQuick
import QtQuick.Layouts
import "../.." 1.0
import "../common" 1.0
import "../../services" 1.0

Rectangle {
    id: root

    readonly property var dockEntries: CommandState.favoriteEntries.slice(0, 5)
    readonly property var dockActions: CommandState.quickActions.slice(0, 3)

    implicitWidth: dockContent.implicitWidth + 18
    implicitHeight: 58
    radius: 8
    color: SmokyPlumTheme.basePanel
    border.width: 1
    border.color: SmokyPlumTheme.borderStrong

    RowLayout {
        id: dockContent

        anchors {
            fill: parent
            leftMargin: 9
            rightMargin: 9
        }

        spacing: 7

        Repeater {
            model: root.dockEntries

            delegate: DockButton {
                required property var modelData
                required property int index

                readonly property string appName: String(modelData.name || "")
                readonly property var matchCandidates: [
                    String(modelData.startupClass || ""),
                    String(modelData.id || ""),
                    appName
                ]

                label: appName
                detail: String(modelData.genericName || "")
                marker: appName.slice(0, 2).toUpperCase()
                iconSource: String(modelData.icon || "")
                emphasized: index === 0
                running: RunningApps.isRunning(matchCandidates)
                onClicked: {
                    RunningApps.focusOrLaunch(modelData, matchCandidates)
                    CommandState.close()
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 1
            Layout.preferredHeight: 34

            color: SmokyPlumTheme.borderSubtle
        }

        Repeater {
            model: root.dockActions

            delegate: DockButton {
                required property var modelData

                label: modelData.title
                detail: modelData.detail
                marker: modelData.symbol
                emphasized: false
                onClicked: CommandState.runAction(modelData.key)
            }
        }
    }
}
