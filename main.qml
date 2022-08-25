import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

import "qt5-qml-sortlistmodel"
import "qt5-qml-promises"

Window {
    id: app

    width: 640
    height: 480
    visible: true
    title: qsTr("ArcGIS Online Search")

    Page {
        anchors.fill: parent

        header: Frame {
            background: Rectangle {
                color: "#e0e0e0"
            }

            RowLayout {
                width: parent.width

                Text {
                    text: qsTr("%1 items (%2 sorted)").arg(itemsListModel.count).arg(itemsListModel.sortCount)
                }
            }
        }

        ListView {
            anchors.fill: parent

            model: itemsListModel
            clip: true

            ScrollBar.vertical: ScrollBar {
                width: 20
            }

            delegate: Frame {
                background: Rectangle {
                    color: (index & 1) ? "#f0f0f0" : "#f8f8f8"
                }

                width: ListView.view.width - 20

                ColumnLayout {
                    width: parent.width

                    Text {
                        Layout.fillWidth: true
                        text: title
                        font.pointSize: 12
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    Text {
                        text: qsTr("%1, %2").arg(owner)
                        .arg(Qt.formatDate(new Date(modified), "dd-MMM-yyyy"))
                        font.pointSize: 10
                    }
                }
            }
        }

        footer: Frame {
            background: Rectangle {
                color: "#e0e0e0"
            }

            RowLayout {
                width: parent.width

                Button {
                    text: qsTr("Search")
                    font.pointSize: 12

                    onClicked: {
                        qmlPromises.asyncToGenerator( function * () {
                            yield qmlPromises.abortIfRunning();
                            yield qmlPromises.start();
                            itemsListModel.clear();
                            let portalUrl = "https://www.arcgis.com";
                            let start = 1;
                            while (start >= 1) {
                                let search = yield qmlPromises.fetch( {
                                    "method": "POST",
                                    "url": `${portalUrl}/sharing/rest/search`,
                                    "body": {
                                        "q": "type:native application",
                                        "start": start,
                                        "num": 100,
                                        "f": "pjson"
                                    },
                                    "headers": {
                                        "Content-type": "application/x-www-form-urlencoded"
                                    }
                                } );
                                console.log("start:", start, "results: ", search.response.results.length, "nextStart: ", search.response.nextStart);
                                itemsListModel.appendItems(search.response.results);
                                if (search.response.nextStart === -1) { break; }
                                start = search.response.nextStart;
                            }
                            yield qmlPromises.finish();
                        } )();
                    }
                }

                Button {
                    icon.source: "https://raw.githubusercontent.com/Esri/calcite-ui-icons/master/icons/clock-up-32.svg"
                    icon.width: 24
                    icon.height: 24
                    enabled: itemsListModel.sortRole !== itemsListModel.orderByModified
                    onClicked: {
                        itemsListModel.sortRole = itemsListModel.orderByModified;
                    }
                }

                Button {
                    icon.source: "https://raw.githubusercontent.com/Esri/calcite-ui-icons/master/icons/a-z-down-32.svg"
                    icon.width: 24
                    icon.height: 24
                    enabled: itemsListModel.sortRole !== itemsListModel.orderByTitle
                    onClicked: {
                        itemsListModel.sortRole = itemsListModel.orderByTitle;
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: qsTr("Abort")

                    onClicked: {
                        qmlPromises.abort();
                    }
                }
            }
        }
    }

    QMLPromises {
        id: qmlPromises
        owner: app
    }

    SortListModel {
        id: itemsListModel

        property var orderByTitle: ( [
                                      {
                                          "sortRole": "title",
                                          "sortOrder": Qt.AscendingOrder
                                      },
                                      {
                                          "sortRole": "modified",
                                          "sortOrder": Qt.DescendingOrder
                                      }
                                    ] )
        property var orderByModified: ( [
                                         {
                                             "sortRole": "modified",
                                             "sortOrder": Qt.DescendingOrder
                                         },
                                         {
                                             "sortRole": "title",
                                             "sortOrder": Qt.AscendingOrder
                                         }
                                       ] )
        sortRole: orderByModified

        function appendItem(item) {
            let itemId = item.id || "";
            let title = item.title || "";
            let modified = item.modified || 0;
            let owner = item.owner || "";
            append( { itemId, title, modified, owner } );
        }

        function appendItems(items) {
            for (let item of items) {
                appendItem(item);
            }
        }
    }
}
