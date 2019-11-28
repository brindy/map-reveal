//
//  MarkerDragDestination.swift
//  MapReveal
//
//  Created by Christopher Brind on 01/10/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

protocol MarkerDragDelegate: NSObjectProtocol {

    func startDragging(_ destination: MarkerDragDestinationView, marker: MarkerDragDestinationView.DraggedMarker)
    func updateDragging(_ destination: MarkerDragDestinationView, marker: MarkerDragDestinationView.DraggedMarker)
    func finishDragging(_ destination: MarkerDragDestinationView, marker: MarkerDragDestinationView.DraggedMarker)
    func cancelDragging(_ destination: MarkerDragDestinationView)

}

class MarkerDragDestinationView: NSView {

    weak var delegate: MarkerDragDelegate?
    private var draggedMarker: DraggedMarker?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        autoresizingMask = [.width, .height]
        registerForDraggedTypes([MarkersTableController.DropInfo.pastboardType])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.types?.contains(MarkersTableController.DropInfo.pastboardType) ?? true else {
            return []
        }

        guard let uid = sender.draggingPasteboard.string(forType: MarkersTableController.DropInfo.pastboardType) else {
            return []
        }

        guard let marker = AppModel.shared.marker(withUid: uid) else {
            return []
        }

        print(#function, sender.draggingLocation)
        if let draggedMarker = DraggedMarker(marker: marker, location: sender.draggingLocation) {
            self.draggedMarker = draggedMarker
            delegate?.startDragging(self, marker: draggedMarker)
            return .copy
        }

        return []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.types?.contains(MarkersTableController.DropInfo.pastboardType) ?? true else {
            return []
        }
        print(#function, sender.draggingLocation)
        draggedMarker?.location = sender.draggingLocation

        if let draggedMarker = draggedMarker {
            delegate?.updateDragging(self, marker: draggedMarker)
            return .copy
        }

        return []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        guard sender?.draggingPasteboard.types?.contains(MarkersTableController.DropInfo.pastboardType) ?? true else { return }
        delegate?.cancelDragging(self)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        guard sender.draggingPasteboard.types?.contains(MarkersTableController.DropInfo.pastboardType) ?? true else { return }
        draggedMarker?.location = sender.draggingLocation
        if let draggedMarker = draggedMarker {
            delegate?.finishDragging(self, marker: draggedMarker)
        }
    }

    class DraggedMarker {

        let marker: UserMarker
        var location: NSPoint
        var image: CGImage

        init?(marker: UserMarker, location: NSPoint) {
            self.marker = marker
            self.location = location

            guard let url = marker.imageUrl else {
                return nil
            }

            guard let image = NSImage(byReferencing: url).cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return nil
            }

            self.image = image
        }
    }

}

