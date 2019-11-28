/*
MapRenderingViewController.swift

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

protocol MapRendereringDelegate: NSObjectProtocol {

    func toolFinished(_ controller: MapRenderingViewController)
    func markerSelected(_ controller: MapRenderingViewController, marker: UserMarker)
    func markerModified(_ controller: MapRenderingViewController, marker: UserMarker)

}

class MapRenderingViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var scrollView: NSScrollView!

    weak var delegate: MapRendereringDelegate?
    weak var markerDragDelegate: MarkerDragDelegate!

    weak var fog: FogOfWarImageView?
    weak var markerDragDestination: MarkerDragDestinationView?

    var isRevealing = true {
        didSet {
            fog?.isRevealing = isRevealing
        }
    }

    var imageUrl: URL?
    var revealedUrl: URL?
    var isEditable = true
    var draggingMarker: MarkerView?
    var selectedMarker: MarkerView?
    var dragStart: Date?

    override func viewDidLoad() {
        super.viewDidLoad()

        let frame = NSRect.zero // (x: 0, y: 0, width: 200, height: 200)
        let markerDragDestination = MarkerDragDestinationView(frame: frame)
        let fogOfWar = FogOfWarImageView(frame: frame)

        imageView.addSubview(fogOfWar)
        imageView.addSubview(markerDragDestination)

        self.fog = fogOfWar
        self.markerDragDestination = markerDragDestination
        self.markerDragDestination?.delegate = markerDragDelegate
    }
            
    func load(imageUrl: URL, revealedUrl: URL) {

        imageView.subviews.forEach {
            if $0 is MarkerView {
                $0.removeFromSuperview()
            }
        }

        self.imageUrl = imageUrl
        self.revealedUrl = revealedUrl

        let image = NSImage(byReferencing: imageUrl)
        imageView?.image = image

        guard let currentFrame = imageView?.frame else { return }
        let newFrame = NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: image.size.width, height: image.size.height)
        imageView?.frame = newFrame

        fog?.frame = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        fog?.restore()

        self.fog?.readRevealed(from: revealedUrl)
    }

    func update(from other: FogOfWarImageView) {
        fog?.update(from: other)
    }

    func clear() {
        imageView.image = nil
        imageView.frame = NSRect(x: 0, y: 0, width: 0, height: 0)
        fog?.restore()
    }

    func usePaintTool() {
        fog?.usePaintTool()
    }

    func useAreaTool() {
        fog?.useAreaTool()
    }

    func zoomToFit() {
        guard let image = imageView.image else { return }
        let frame = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        imageView.frame = frame
        scrollView.magnify(toFit: imageView.bounds)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        let point = convert(event.locationInWindow)
        if let draggingMarker = draggingMarker(under: point) {
            self.draggingMarker = draggingMarker
            dragStart = Date()
            draggingMarker.dragStarted(at: point)
            imageView.bringSubviewToFront(draggingMarker)
            return
        }

        guard isEditable else { return }
        fog?.start(at: point)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        let point = convert(event.locationInWindow)
        if let draggingMarker = draggingMarker {
            draggingMarker.dragUpdated(at: point, scaling: event.modifierFlags.contains(.shift))
            dragStart = nil
            return
        }

        guard isEditable else { return }
        fog?.move(to: point)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)

        let point = convert(event.locationInWindow)
        if let draggingMarker = draggingMarker {

            if dragStart != nil {
                selected(marker: draggingMarker.marker)
                delegate?.markerSelected(self, marker: draggingMarker.marker)
                dragStart = nil
            }

            draggingMarker.dragFinished(at: point)
            self.draggingMarker = nil
            updateMarkerOrder()
            AppModel.shared.save()
            delegate?.markerModified(self, marker: draggingMarker.marker)
            return
        }

        guard isEditable else { return }
        fog?.finish(at: point)
        if let revealedUrl = revealedUrl {
            self.fog?.writeRevealed(to: revealedUrl)
        }
        delegate?.toolFinished(self)
    }

    func addMarker(_ marker: UserMarker) {
        print(#function, marker.displayName ?? "nil", marker.x, marker.y)

        if let markerView = imageView.subviews.first(where: { ($0 as? MarkerView)?.marker == marker }) {
            markerView.frame = CGRect(x: CGFloat(marker.x), y: CGFloat(marker.y), width: CGFloat(marker.width), height: CGFloat(marker.height))
        } else if let markerView = MarkerView.create(with: marker) {
            imageView.addSubview(markerView)
        }
    }

    func removeMarker(_ marker: UserMarker) {

        if let markerView = imageView.subviews.first(where: { ($0 as? MarkerView)?.marker == marker }) {
            markerView.removeFromSuperview()
        }

    }

    func zoomTo(marker: UserMarker) {
        guard let marker = imageView.subviews.first(where: { ($0 as? MarkerView)?.marker == marker } ) else { return }
        scrollView.magnify(toFit: marker.frame)
        scrollView.magnification /= 4.0
    }

    func selected(marker: UserMarker) {
        selectedMarker?.selected = false
        guard let marker = imageView.subviews.first(where: { ($0 as? MarkerView)?.marker == marker } ) else { return }
        selectedMarker = marker as? MarkerView
        selectedMarker?.selected = true
    }

    private func convert(_ point: NSPoint) -> NSPoint {
        guard let parent = parent else { return view.convert(point, to: imageView) }
        return parent.view.convert(point, to: imageView)
    }

    private func draggingMarker(under point: NSPoint) -> MarkerView? {
        return imageView.subviews.first(where: { ($0 as? MarkerView)?.frame.contains(point) ?? false }) as? MarkerView
    }

    private func updateMarkerOrder() {

        var i: Int64 = 0
        imageView.subviews.forEach({
            ($0 as? MarkerView)?.marker.displayOrder = i
            i += 1
        })

    }

}

extension NSView {

    func bringSubviewToFront(_ view: NSView) {
            var theView = view
            self.sortSubviews({(viewA,viewB,rawPointer) in
                let view = rawPointer?.load(as: NSView.self)

                switch view {
                case viewA:
                    return ComparisonResult.orderedDescending
                case viewB:
                    return ComparisonResult.orderedAscending
                default:
                    return ComparisonResult.orderedSame
                }
            }, context: &theView)
    }

}
