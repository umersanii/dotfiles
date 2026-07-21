pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Pinned clipboard entries. Stored independently of cliphist so pins
 * survive cliphist history trimming/wipes. Text content is copied inline
 * into the store; images are decoded once at pin time into a cache file.
 */
Singleton {
    id: root
    property string filePath: Directories.pinnedClipboardPath
    property string imageDir: Directories.pinnedClipboardImages
    property list<var> entries: []

    function isPinned(rawEntry) {
        return root.entries.some(e => e.preview === rawEntry);
    }

    function persist() {
        fileView.setText(JSON.stringify(root.entries, null, 2));
    }

    function pin(rawEntry) {
        if (root.isPinned(rawEntry))
            return;
        const isImage = Cliphist.entryIsImage(rawEntry);
        const item = {
            id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
            preview: rawEntry,
            isImage: isImage,
            pinnedAt: Date.now()
        };
        if (isImage) {
            item.imagePath = `${root.imageDir}/${item.id}.png`;
            Quickshell.execDetached(["bash", "-c", `mkdir -p '${root.imageDir}' && printf '${StringUtils.shellSingleQuoteEscape(rawEntry)}' | ${Cliphist.cliphistBinary} decode > '${item.imagePath}'`]);
        } else {
            item.textContent = StringUtils.cleanCliphistEntry(rawEntry);
        }
        root.entries = [item, ...root.entries];
        root.persist();
    }

    function unpinByPreview(rawEntry) {
        const target = root.entries.find(e => e.preview === rawEntry);
        root.entries = root.entries.filter(e => e.preview !== rawEntry);
        root.persist();
        if (target?.isImage && target.imagePath)
            Quickshell.execDetached(["rm", "-f", target.imagePath]);
    }

    function unpin(id) {
        const target = root.entries.find(e => e.id === id);
        root.entries = root.entries.filter(e => e.id !== id);
        root.persist();
        if (target?.isImage && target.imagePath)
            Quickshell.execDetached(["rm", "-f", target.imagePath]);
    }

    function copy(item) {
        if (item.isImage)
            Quickshell.execDetached(["bash", "-c", `wl-copy < '${item.imagePath}'`]);
        else
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(item.textContent)}' | wl-copy`]);
    }

    function fuzzyQuery(search) {
        if (search.trim() === "")
            return root.entries;
        const searchLower = search.toLowerCase();
        return root.entries.filter(e => (e.isImage ? e.preview : e.textContent).toLowerCase().includes(searchLower));
    }

    function refresh() {
        fileView.reload();
    }

    FileView {
        id: fileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            try {
                root.entries = JSON.parse(fileView.text());
            } catch (e) {
                console.error("[Pinned] Failed to parse pinned clipboard file:", e);
                root.entries = [];
            }
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.entries = [];
                fileView.setText(JSON.stringify(root.entries));
            } else {
                console.error("[Pinned] Error loading file:", error);
            }
        }
    }
}
