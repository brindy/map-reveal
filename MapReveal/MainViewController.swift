//
//  MasterMapViewController.swift
//  MapReveal
//
//  Created by Chris Brind on 08/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

class MainViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!

    weak var gmMap: MapRenderingViewController?
    weak var playerMap: MapRenderingViewController?

    var selectedUserMap: UserMap?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let otherWindowController = storyboard?.instantiateController(withIdentifier: "VisibleMap") as? NSWindowController
        guard let otherViewController = otherWindowController?.contentViewController as? MapRenderingViewController else { return }
        otherViewController.fog?.color = NSColor.white
        otherViewController.editable = false
        self.playerMap = otherViewController
        otherWindowController?.showWindow(self)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier("Paint")
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let controller = segue.destinationController as? MapRenderingViewController {
            gmMap = controller
        }
        if let controller = segue.destinationController as? OpenViewController {
            controller.delegate = self
        }
    }

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

        gmMap?.revealing = (sender as? NSButton)?.state == NSControl.StateValue.on

    }
    
    @IBAction func pushToOther(_ sender: Any) {
        print(#function)
        guard let playerImageUrl = selectedUserMap?.playerImageUrl, let revealedUrl = selectedUserMap?.revealedUrl else { return }
        guard let fog = gmMap?.fog else { return }
        playerMap?.load(imageUrl: playerImageUrl, revealedUrl: revealedUrl)
        playerMap?.update(from: fog)
    }

    @IBAction func imageNameEdited(_ sender: NSTextField) {
        AppModel.shared.userMaps[tableView.selectedRow].displayName = sender.stringValue
        AppModel.shared.save()
    }

    private func loadSelected() {
        let userMap = AppModel.shared.userMaps[tableView.selectedRow]
        selectedUserMap = userMap
        guard let gmImageUrl = selectedUserMap?.gmImageUrl, let revealedUrl = selectedUserMap?.revealedUrl else { return }
        gmMap?.load(imageUrl: gmImageUrl, revealedUrl: revealedUrl)
    }

    private func selectLast() {
        let index = AppModel.shared.userMaps.count - 1
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
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

}

extension MainViewController: OpenDelegate {

    func viewController(_ controller: OpenViewController, didOpenImages images: [NSImage], named: String) {
        print(#function)
        AppModel.shared.add(gmImage: images[0], playerImage: images.count > 1 ? images[1] : images[0], named: named) { error in
            guard error == nil else { return }
            self.tableView.reloadData()
            self.selectLast()
        }
    }

}
