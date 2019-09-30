/*
MapsTableController.swift

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

protocol MapsTableControllerDelegate: NSObjectProtocol {

    func load(userMap: UserMap)
    func handle(drop: MapsTableController.UserMapDrop)

}

class MapsTableController: NSObject, NSTableViewDelegate, NSTableViewDataSource {

    struct UserMapDrop {

        let image: NSImage
        let row: Int

    }

    let mapPasteboardType = NSPasteboard.PasteboardType(rawValue: "mapreveal.usermap")

    let tableView: NSTableView
    let delegate: MapsTableControllerDelegate

    init(tableView: NSTableView, delegate: MapsTableControllerDelegate) {
        self.tableView = tableView
        self.delegate = delegate
        super.init()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerForDraggedTypes([ mapPasteboardType, .fileURL ])
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return AppModel.shared.userMaps.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("UserMapCellId"), owner: self) as? NSTableCellView else { return nil }
        cell.textField?.stringValue = AppModel.shared.userMaps[row].displayName ?? "<unnamed>"
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow >= 0 else { return }
        let userMap = AppModel.shared.userMaps[tableView.selectedRow]
        delegate.load(userMap: userMap)
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        print(#function, row)

        if let uid = info.draggingPasteboard.string(forType: mapPasteboardType) {
            moveMapWithUid(uid: uid, to: row, onTableView: tableView)
            return true
        }

        if let image = NSImage(pasteboard: info.draggingPasteboard) {
            print(#function, dropOperation == .above ? "above" : "on")
            // performSegue(withIdentifier: "Open", sender: )
            delegate.handle(drop: UserMapDrop(image: image, row: row))
            return true
        }

        return false
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        print(#function)
        return info.draggingPasteboard.string(forType: mapPasteboardType) != nil ? .move : .copy
    }

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        print(#function, row)
        guard let uid = AppModel.shared.userMaps[row].uid else { return nil }
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(uid, forType: mapPasteboardType)
        return pasteboardItem
    }

    private func moveMapWithUid(uid: String, to row: Int, onTableView tableView: NSTableView) {
        print(#function, uid)

        guard let originalRow = AppModel.shared.userMaps.firstIndex(where: { $0.uid == uid }) else { return }
        print(#function, originalRow)

        var newRow = row
        if originalRow < newRow {
            newRow = row - 1
        }

        tableView.beginUpdates()
        tableView.moveRow(at: originalRow, to: newRow)
        tableView.endUpdates()

        AppModel.shared.moveMap(from: originalRow, to: newRow)

    }

}
