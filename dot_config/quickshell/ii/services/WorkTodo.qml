pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * Work to-do list manager — separate from personal todo.
 * Each item is an object with "content" and "done" properties.
 */
Singleton {
    id: root
    property var filePath: Directories.workTodoPath
    property var list: []

    function addItem(item) {
        list.push(item)
        root.list = list.slice(0)
        workTodoFileView.setText(JSON.stringify(root.list))
    }

    function addTask(desc) {
        const active = list.filter(t => !t.done).length
        if (active >= 8) {
            root.list = list.filter(t => !t.done)
        }
        const item = {
            "content": desc,
            "done": false,
        }
        addItem(item)
    }

    function purgeStaleDone() {
        const twoDaysAgo = Date.now() - 2 * 24 * 60 * 60 * 1000
        const before = list.length
        root.list = list.filter(t => !t.done || (t.doneAt && t.doneAt > twoDaysAgo))
        if (root.list.length !== before)
            workTodoFileView.setText(JSON.stringify(root.list))
    }

    function markDone(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = true
            list[index].doneAt = Date.now()
            root.list = list.slice(0)
            workTodoFileView.setText(JSON.stringify(root.list))
        }
    }

    function markUnfinished(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = false
            root.list = list.slice(0)
            workTodoFileView.setText(JSON.stringify(root.list))
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            list.splice(index, 1)
            root.list = list.slice(0)
            workTodoFileView.setText(JSON.stringify(root.list))
        }
    }

    function refresh() {
        workTodoFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    Timer {
        interval: 60 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.purgeStaleDone()
    }

    FileView {
        id: workTodoFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            const fileContents = workTodoFileView.text()
            root.list = JSON.parse(fileContents)
            console.log("[Work Todo] File loaded")
            root.purgeStaleDone()
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                console.log("[Work Todo] File not found, creating new file.")
                root.list = []
                workTodoFileView.setText(JSON.stringify(root.list))
            } else {
                console.log("[Work Todo] Error loading file: " + error)
            }
        }
    }
}
