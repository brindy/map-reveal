/*
MarkerView.swift

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

class MarkerView: NSView {

    static func create(with marker: UserMarker) -> NSView? {
        guard let imageUrl = marker.imageUrl else { return nil }
        let image = NSImage(byReferencing: imageUrl)
        let imageView = NSImageView(image: image)
        let size = CGFloat(max(marker.width, marker.height))
        let frame = NSRect(x: CGFloat(marker.x), y: CGFloat(marker.y), width: size, height: size)
        imageView.frame = NSRect(origin: NSPoint(x: 0, y: 0), size: frame.size)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]

        let markerView = MarkerView(frame: frame, marker: marker)
        markerView.addSubview(imageView)
        return markerView
    }

    let marker: UserMarker
    var isDragging = false
    var selected = false {
        didSet {
            if selected {
                layer?.borderColor = NSColor.green.cgColor
            } else {
                layer?.borderColor = NSColor.black.cgColor
            }
        }
    }

    private var cursorRect: NSRect?
    private var trackingArea: NSTrackingArea?
    private var offset: NSPoint?

    init(frame: NSRect, marker: UserMarker) {
        self.marker = marker
        super.init(frame: frame)
        updateTrackingAreas()
        autoresizesSubviews = true
        wantsLayer = true
        updateLayerProperties()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func dragStarted(at point: NSPoint) {
        offset = NSPoint(x: frame.origin.x - point.x, y: frame.origin.y - point.y)
    }

    func dragUpdated(at point: NSPoint, scaling: Bool) {
        guard let offset = offset else { return }

        if scaling {
            let distance = point.distanceTo(frame.origin)
            frame.size = NSSize(width: distance, height: distance)
            updateLayerProperties()
        } else {
            frame.origin = NSPoint(x: point.x + offset.x, y: point.y + offset.y)
        }

    }

    func dragFinished(at point: NSPoint) {
        guard let offset = offset else { return }
        marker.x = Float(point.x + offset.x)
        marker.y = Float(point.y + offset.y)
        marker.width = Float(frame.size.width)
        marker.height = Float(frame.size.height)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if isDragging {
            NSCursor.closedHand.set()
        } else {
            NSCursor.openHand.set()
        }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        NSCursor.closedHand.set()
        isDragging = true
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        NSCursor.openHand.set()
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        NSCursor.closedHand.set()
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        NSCursor.openHand.set()
        isDragging = false
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil))
    }

    private func updateLayerProperties() {
        layer?.cornerRadius = frame.size.height / 2
        layer?.borderWidth = frame.size.height / 10
    }

}

extension NSPoint {

    func distanceTo(_ point: NSPoint) -> CGFloat {
        return distanceTo(x: point.x, y: point.y)
    }

    func distanceTo(x: CGFloat, y: CGFloat) -> CGFloat {
        let width = self.x - x
        let height = self.y - y
        return sqrt(width * width + height * height)
    }

}
