pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * Simple to-do list manager.
 * Each item is an object with "content" and "done" properties.
 */
Singleton {
    id: root
    property var filePath: Directories.todoPath
    property var list: []
    
    function addItem(item) {
        list.push(item)
        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        todoFileView.setText(JSON.stringify(root.list))
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
            todoFileView.setText(JSON.stringify(root.list))
    }

    function markDone(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = true
            list[index].doneAt = Date.now()
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function markUnfinished(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = false
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            list.splice(index, 1)
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function refresh() {
        todoFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    Timer {
        interval: 60 * 60 * 1000 // every hour
        repeat: true
        running: true
        onTriggered: root.purgeStaleDone()
    }

    FileView {
        id: todoFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            const fileContents = todoFileView.text()
            root.list = JSON.parse(fileContents)
            console.log("[To Do] File loaded")
            root.purgeStaleDone()
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[To Do] File not found, creating new file.")
                root.list = []
                todoFileView.setText(JSON.stringify(root.list))
            } else {
                console.log("[To Do] Error loading file: " + error)
            }
        }
    }
}

