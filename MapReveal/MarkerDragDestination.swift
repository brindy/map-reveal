//
//  MarkerDragDestination.swift
//  MapReveal
//
//  Created by Christopher Brind on 01/10/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

protocol MarkerDragDelegate: NSObjectProtocol {

    func startDragging(_ destination: MarkerDragDestination, marker: MarkerDragDestination.DraggedMarker)
    func updateDragging(_ destination: MarkerDragDestination, marker: MarkerDragDestination.DraggedMarker)

}

class MarkerDragDestination: NSView {

    weak var delegate: MarkerDragDelegate?
    private var draggedMarker: DraggedMarker?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        autoresizingMask = [.width, .height]
        translatesAutoresizingMaskIntoConstraints = true
        registerForDraggedTypes([MarkersTableController.DropInfo.pastboardType])
        needsLayout = true
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

        if let draggedMarker = DraggedMarker(marker: marker, location: sender.draggingLocation) {
            self.draggedMarker = draggedMarker
            delegate?.startDragging(self, marker: draggedMarker)
            return .generic
        }

        return []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.types?.contains(MarkersTableController.DropInfo.pastboardType) ?? true else {
            return []
        }
        draggedMarker?.location = sender.draggingLocation

        if let draggedMarker = draggedMarker {
            delegate?.updateDragging(self, marker: draggedMarker)
            return .generic
        }

        return []
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

