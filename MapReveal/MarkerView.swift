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

    var isDragging = false

    static func create(with marker: UserMarker) -> NSView? {
        guard let imageUrl = marker.imageUrl else { return nil }
        let image = NSImage(byReferencing: imageUrl)
        let imageView = NSImageView(image: image)
        let frame = NSRect(x: CGFloat(marker.x), y: CGFloat(marker.y), width: image.size.width, height: image.size.height)
        imageView.frame = NSRect(origin: NSPoint(x: 0, y: 0), size: frame.size)

        let markerView = MarkerView(frame: frame, marker: marker)
        markerView.addSubview(imageView)
        markerView.wantsLayer = true
        markerView.layer?.contentsScale = CGFloat(marker.scale)
        markerView.marker = marker
        return markerView
    }

    var marker: UserMarker!

    init(frame: NSRect, marker: UserMarker) {
        super.init(frame: frame)
        self.marker = marker
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var offset: NSPoint?
    func dragStarted(at point: NSPoint) {
        offset = NSPoint(x: frame.origin.x - point.x, y: frame.origin.y - point.y)
    }

    func dragUpdated(at point: NSPoint) {
        guard let offset = offset else { return }
        frame.origin = NSPoint(x: point.x + offset.x, y: point.y + offset.y)
    }

    func dragFinished(at point: NSPoint) {
        guard let offset = offset else { return }
        marker.x = Float(point.x + offset.x)
        marker.y = Float(point.y + offset.y)
    }
}
