/*
MarkersTableControllerDelegate.swift

Copyright 2019 Chris Brind

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import AppKit

protocol MarkersTableControllerDelegate: NSObjectProtocol {

    func selected(userMarker: UserMarker)
    func delete(userMarker: UserMarker)
    func handle(drop: MarkersTableController.DropInfo)

}

class MarkersTableController: NSObject, NSTableViewDelegate, NSTableViewDataSource {

    struct DropInfo {

        static let pastboardType = NSPasteboard.PasteboardType(rawValue: "mapreveal.usermarker")

        let image: NSImage
        let row: Int

    }

    let tableView: NSTableView
    let delegate: MarkersTableControllerDelegate

    init(tableView: NSTableView, delegate: MarkersTableControllerDelegate) {
        self.tableView = tableView
        self.delegate = delegate
        super.init()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerForDraggedTypes([ DropInfo.pastboardType, .fileURL ])
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return AppModel.shared.userMarkers.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("Cell"), owner: self) as? NSTableCellView else { return nil }
        
        let marker = AppModel.shared.userMarkers[row]
        cell.textField?.stringValue = marker.displayName ?? "<unnamed>"

        if let imageUrl = marker.imageUrl {
            cell.imageView?.image = NSImage(byReferencing: imageUrl)
        }

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow >= 0 else { return }
        let userMarker = AppModel.shared.userMarkers[tableView.selectedRow]
        delegate.selected(userMarker: userMarker)
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        print(#function, row)

        if let uid = info.draggingPasteboard.string(forType: DropInfo.pastboardType) {
            moveMarkerWithUid(uid: uid, to: row, onTableView: tableView)
            return true
        }

        if let image = NSImage(pasteboard: info.draggingPasteboard) {
            print(#function, dropOperation == .above ? "above" : "on")
            delegate.handle(drop: DropInfo(image: image, row: row))
            return true
        }

        return false
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        return info.draggingPasteboard.string(forType: DropInfo.pastboardType) != nil ? .move : .copy
    }

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        print(#function, row)
        guard let uid = AppModel.shared.userMarkers[row].uid else { return nil }
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(uid, forType: DropInfo.pastboardType)
        return pasteboardItem
    }

    func deleteSelected() {
        guard tableView.selectedRow >= 0 else { return }
        let userMarker = AppModel.shared.userMarkers[tableView.selectedRow]
        delegate.delete(userMarker: userMarker)
    }

    private func moveMarkerWithUid(uid: String, to row: Int, onTableView tableView: NSTableView) {
        print(#function, uid)

        guard let originalRow = AppModel.shared.userMarkers.firstIndex(where: { $0.uid == uid }) else { return }
        print(#function, originalRow)

        var newRow = row
        if originalRow < newRow {
            newRow = row - 1
        }

        tableView.beginUpdates()
        tableView.moveRow(at: originalRow, to: newRow)
        tableView.endUpdates()

        AppModel.shared.moveMarker(from: originalRow, to: newRow)
    }

}
