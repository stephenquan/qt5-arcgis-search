# qt5-arcgis-search
Qt5 application demonstrating ArcGIS Online Search API

The made search uses generator function with yield syntax which
was transpiled from async function with await syntax:

```qml
Button {
    text: qsTr("Search")
    onClicked: {
        qmlPromises.userAbort();
        qmlPromises.asyncToGenerator( function * () {
            let startTime = Date.now();
            let start = 1;
            while (start >= 1) {
                let search = yield qmlPromises.fetch( {
                    "url": `https://www.arcgis.com/sharing/rest/search`,
                    "body": {
                        "q": "type:native application",
                        "start": start,
                        "num": 100,
                        "f": "pjson"
                    }
                } );
                if (qmlPromises.userAbortTime > startTime) { throw new Error("User Abort"); }
                console.log("start:", start, "results: ", search.response.results.length, "nextStart: ", search.response.nextStart);
                if (search.response.nextStart === -1) { break; }
                start = search.response.nextStart;
            }
        } )();
    }
}
```

This application uses the following Qt5 QML submodule libraries:
 - https://github.com/stephenquan/qt5-qml-promises
 - https://github.com/stephenquan/qt5-qml-sortlistmodel