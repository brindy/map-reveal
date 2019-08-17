//
//  MasterMapViewController.swift
//  MapReveal
//
//  Created by Chris Brind on 08/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

class MainViewController: NSViewController {

    struct DropInfo {

        let image: NSImage
        let row: Int

    }

    let mapPasteboardType = NSPasteboard.PasteboardType(rawValue: "mapreveal.usermap")

    @IBOutlet weak var tableView: NSTableView!

    weak var gmMap: MapRenderingViewController?
    weak var playerMap: MapRenderingViewController?

    var selectedUserMap: UserMap?
    var autoPush: Bool = true
    var zoomFit: Bool = true

    // MARK: overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let otherWindowController = storyboard?.instantiateController(withIdentifier: "VisibleMap") as? NSWindowController
        guard let otherViewController = otherWindowController?.contentViewController as? MapRenderingViewController else { return }
        otherViewController.fog?.color = NSColor.white
        otherViewController.editable = false
        self.playerMap = otherViewController
        otherWindowController?.showWindow(self)

        tableView.registerForDraggedTypes([ mapPasteboardType, .fileURL ])
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier("Paint")
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let controller = segue.destinationController as? MapRenderingViewController {
            gmMap = controller
            gmMap?.delegate = self
        }
        if let controller = segue.destinationController as? OpenViewController {
            controller.delegate = self
            controller.droppedImage = (sender as? DropInfo)?.image
            controller.dropRow = (sender as? DropInfo)?.row
        }
    }

    // MARK: actions

    @IBAction func openDocument(_ sender: Any) {

        performSegue(withIdentifier: NSStoryboardSegue.Identifier("Open"), sender: self)

    }

    @IBAction func delete(_ sender: Any) {
        guard tableView.selectedRow >= 0 else { return }

        let userMap = AppModel.shared.userMaps[tableView.selectedRow]
        AppModel.shared.delete(userMap)
        AppModel.shared.save()
        tableView.reloadData()

        gmMap?.clear()

        if playerMap?.imageUrl == userMap.playerImageUrl {
            playerMap?.clear()
        }

    }

    @IBAction func setRevealPaint(_ sender: Any) {
        print(#function)
        gmMap?.usePaintTool()
    }
    
    @IBAction func setRevealArea(_ sender: Any) {
        gmMap?.useAreaTool()
        print(#function)
    }
    
    @IBAction func setRevealPath(_ sender: Any) {
        print(#function)
    }
    
    @IBAction func activatePointer(_ sender: Any) {
        print(#function)
    }

    @IBAction func toggleReveal(_ sender: Any) {
        print(#function, sender)
        gmMap?.revealing = (sender as? NSButton)?.state == .on
    }

    @IBAction func toggleAutoPush(_ sender: Any) {
        autoPush = (sender as? NSButton)?.state == .on
    }

    @IBAction func toggleZoomFit(_ sender: Any) {
        zoomFit = (sender as? NSButton)?.state == .on
    }
    
    @IBAction func pushToOther(_ sender: Any) {
        print(#function)
        guard let playerImageUrl = selectedUserMap?.playerImageUrl, let revealedUrl = selectedUserMap?.revealedUrl else { return }
        guard let fog = gmMap?.fog else { return }
        playerMap?.load(imageUrl: playerImageUrl, revealedUrl: revealedUrl)
        playerMap?.update(from: fog)
        if zoomFit {
            playerMap?.zoomToFit()
        }
    }

    @IBAction func imageNameEdited(_ sender: NSTextField) {
        AppModel.shared.userMaps[tableView.selectedRow].displayName = sender.stringValue
        AppModel.shared.save()
    }

    // MARK: private

    private func loadSelected() {
        let userMap = AppModel.shared.userMaps[tableView.selectedRow]
        selectedUserMap = userMap
        guard let gmImageUrl = selectedUserMap?.gmImageUrl, let revealedUrl = selectedUserMap?.revealedUrl else { return }
        gmMap?.load(imageUrl: gmImageUrl, revealedUrl: revealedUrl)
        gmMap?.zoomToFit()
    }

}

extension MainViewController: MapRendereringDelegate {

    func toolFinished(_ controller: MapRenderingViewController) {
        guard autoPush else { return }
        pushToOther(self)
    }

}

extension MainViewController: NSTableViewDelegate, NSTableViewDataSource {
    
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
        loadSelected()
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        print(#function, row)

        if let uid = info.draggingPasteboard.string(forType: mapPasteboardType) {
            moveMapWithUid(uid: uid, to: row)
            return true
        }

        if let image = NSImage(pasteboard: info.draggingPasteboard) {

            print(#function, dropOperation == .above ? "above" : "on")

            performSegue(withIdentifier: "Open", sender: DropInfo(image: image, row: row))
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

    private func moveMapWithUid(uid: String, to row: Int) {
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

extension MainViewController: OpenDelegate {

    func viewController(_ controller: OpenViewController, didOpenImages images: [NSImage], named: String, toRow row: Int?) {
        print(#function, named, row ?? -1)
        AppModel.shared.add(gmImage: images[0], playerImage: images.count > 1 ? images[1] : images[0], named: named, toRow: row) { uid, error in
            guard error == nil else { return }
            guard let index = AppModel.shared.userMaps.firstIndex(where: { $0.uid == uid }) else { return }
            let indexes  = IndexSet(integer: index)
            self.tableView.insertRows(at: indexes, withAnimation: .effectGap)
            self.tableView.selectRowIndexes(indexes, byExtendingSelection: false)
        }
    }

}
