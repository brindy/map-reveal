/*
 MainViewController.swift
 
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

class MainViewController: NSViewController {

    struct Segues {

        static let importMap = "Import Map"
        static let importMarker = "Import Marker"

    }

    var markerDragDestination: MarkerDragDestinationView?

    @IBOutlet weak var mapsTableView: NSTableView!
    @IBOutlet weak var markersTableView: NSTableView!

    weak var gmMap: MapRenderingViewController?
    weak var playerMap: MapRenderingViewController?
    weak var markerImageView: NSImageView?

    var selectedUserMap: UserMap?
    var autoPush: Bool = true
    var zoomFit: Bool = true

    var mapsTableController: MapsTableController!
    var markersTableController: MarkersTableController!

    // MARK: overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        mapsTableController = MapsTableController(tableView: mapsTableView, delegate: self)
        markersTableController = MarkersTableController(tableView: markersTableView, delegate: self)
        createOtherWindow()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier("Paint")
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let controller = segue.destinationController as? MapRenderingViewController {

            print(#function)

            gmMap = controller
            gmMap?.delegate = self
            gmMap?.markerDragDelegate = self

        }
        if let controller = segue.destinationController as? ImportMapViewController {
            controller.delegate = self
            controller.droppedImage = (sender as? MapsTableController.DropInfo)?.image
            controller.dropRow = (sender as?  MapsTableController.DropInfo)?.row
        }
        if let controller = segue.destinationController as? ImportMarkerViewController {
            controller.delegate = self
            controller.droppedImage = (sender as? MarkersTableController.DropInfo)?.image
            controller.dropRow = (sender as?  MarkersTableController.DropInfo)?.row
        }
    }

    // MARK: actions

    @IBAction func importMap(_ sender: Any) {
        performSegue(withIdentifier: Segues.importMap, sender: nil)
    }

    @IBAction func importMarker(_ sender: Any) {
        performSegue(withIdentifier: Segues.importMarker, sender: nil)
    }

    @IBAction func delete(_ sender: Any) {
        mapsTableController.deleteSelected()
        markersTableController.deleteSelected()
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
        AppModel.shared.userMaps[mapsTableView.selectedRow].displayName = sender.stringValue
        AppModel.shared.save()
    }

    @IBAction func markerNameEdited(_ sender: NSTextField) {
        // TODO update the name
        AppModel.shared.save()
    }

    // MARK: private

    private func createOtherWindow() {
        let otherWindowController = storyboard?.instantiateController(withIdentifier: "VisibleMap") as? NSWindowController
        guard let otherViewController = otherWindowController?.contentViewController as? MapRenderingViewController else { return }
        otherViewController.fog?.color = NSColor.white
        otherViewController.editable = false
        self.playerMap = otherViewController
        otherWindowController?.showWindow(self)
        DispatchQueue.main.async {
            otherWindowController?.window?.orderFrontRegardless()
        }
    }

}

extension MainViewController: MapRendereringDelegate {

    func toolFinished(_ controller: MapRenderingViewController) {
        guard autoPush else { return }
        pushToOther(self)
    }

}

extension MainViewController: ImportMapDelegate {

    func viewController(_ controller: ImportMapViewController, didOpenImages images: [NSImage], named name: String, toRow row: Int?) {
        print(#function, name, row ?? -1)
        AppModel.shared.add(gmImage: images[0], playerImage: images.count > 1 ? images[1] : images[0], named: name, toRow: row) { uid, error in
            guard error == nil else { return }
            guard let index = AppModel.shared.userMaps.firstIndex(where: { $0.uid == uid }) else { return }
            let indexes  = IndexSet(integer: index)
            self.mapsTableView.insertRows(at: indexes, withAnimation: .effectGap)
            self.mapsTableView.selectRowIndexes(indexes, byExtendingSelection: false)
        }
    }

}

extension MainViewController: ImportMarkerDelegate {

    func viewController(_ controller: ImportMarkerViewController, didOpenImage image: NSImage, named name: String, toRow row: Int?) {
        print(#function, name, row ?? -1)
        AppModel.shared.add(markerImage: image, named: name, toRow: row) { uid, error in
            guard error == nil else { return }
            guard let index = AppModel.shared.userMarkers.firstIndex(where: { $0.uid == uid }) else { return }
            let indexes  = IndexSet(integer: index)
            self.markersTableView.insertRows(at: indexes, withAnimation: .effectGap)
            self.markersTableView.selectRowIndexes(indexes, byExtendingSelection: false)
        }
    }

}

extension MainViewController: MapsTableControllerDelegate {

    func selected(userMap: UserMap) {
        markersTableView.selectRowIndexes([], byExtendingSelection: false)
        selectedUserMap = userMap
        guard let gmImageUrl = selectedUserMap?.gmImageUrl, let revealedUrl = selectedUserMap?.revealedUrl else { return }
        gmMap?.load(imageUrl: gmImageUrl, revealedUrl: revealedUrl)
        gmMap?.zoomToFit()
    }

    func handle(drop: MapsTableController.DropInfo) {
        performSegue(withIdentifier: Segues.importMap, sender: drop)
    }

    func delete(userMap: UserMap) {
        AppModel.shared.delete(userMap)
        AppModel.shared.save()
        mapsTableView.reloadData()

        gmMap?.clear()

        if playerMap?.imageUrl == userMap.playerImageUrl {
            playerMap?.clear()
        }
    }

}

extension MainViewController: MarkersTableControllerDelegate {

    func selected(userMarker: UserMarker) {
        mapsTableView.selectRowIndexes([], byExtendingSelection: false)
        // TODO
    }

    func handle(drop: MarkersTableController.DropInfo) {
        performSegue(withIdentifier: Segues.importMarker, sender: drop)
    }

    func delete(userMarker: UserMarker) {
        AppModel.shared.delete(userMarker)
        AppModel.shared.save()
        markersTableView.reloadData()

        // TODO refresh the map

    }

}

extension MainViewController: MarkerDragDelegate {

    func startDragging(_ destination: MarkerDragDestinationView, marker: MarkerDragDestinationView.DraggedMarker) {
        let converted = view.convert(marker.location, to: gmMap?.imageView)
        print(#function, marker.location, converted)
        markerImageView?.removeFromSuperview()

        let size = NSSize(width: marker.image.width, height: marker.image.height)
        let markerImageView = NSImageView(image: NSImage(cgImage: marker.image, size: size))
        gmMap?.imageView.addSubview(markerImageView)
        self.markerImageView = markerImageView
    }

    func updateDragging(_ destination: MarkerDragDestinationView, marker: MarkerDragDestinationView.DraggedMarker) {
        let converted = view.convert(marker.location, to: gmMap?.imageView)
        print(#function, marker.location, converted)
        if let size = markerImageView?.image?.size {
            markerImageView?.frame = NSRect(origin: converted.offsetBy(size.half.inverted), size: size)
        }
    }

    func finishDragging(_ destination: MarkerDragDestinationView, marker: MarkerDragDestinationView.DraggedMarker) {
        markerImageView = nil
    }

    func cancelDragging(_ destination: MarkerDragDestinationView) {
        markerImageView?.removeFromSuperview()
    }

}

extension NSSize {

    var half: NSSize {
        return NSSize(width: width / 2, height: height / 2)
    }

    var inverted: NSSize {
        return NSSize(width: -width, height: -height)
    }

}

extension NSPoint {

    func offsetBy(_ size: NSSize) -> NSPoint {
        return NSPoint(x: x + size.width, y: y + size.height)
    }

}
