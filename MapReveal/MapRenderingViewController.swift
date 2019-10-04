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
    func markerModified(_ controller: MapRenderingViewController, marker: UserMarker)
    func markerRemoved(_ controller: MapRenderingViewController, marker: UserMarker)

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
        view.needsLayout = true

        fog?.frame = newFrame
        fog?.restore()

        DispatchQueue.global(qos: .utility).async {
            self.fog?.readRevealed(from: revealedUrl)
        }
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
        scrollView.magnify(toFit: frame)
    }

    var draggingMarker: MarkerView?
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        guard isEditable else { return }
        let point = convert(event.locationInWindow)
        if let draggingMarker = draggingMarker(under: point) {
            print(#function, "found dragging marker")
            self.draggingMarker = draggingMarker
            draggingMarker.dragStarted(at: point)
            return
        }
        fog?.start(at: point)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        guard isEditable else { return }
        let point = convert(event.locationInWindow)
        if let draggingMarker = draggingMarker {
            print(#function, "found dragging marker")
            draggingMarker.dragUpdated(at: point)
            return
        }
        fog?.move(to: point)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        guard isEditable else { return }
        let point = convert(event.locationInWindow)
        if let draggingMarker = draggingMarker {
            draggingMarker.dragFinished(at: point)
            self.draggingMarker = nil
            AppModel.shared.save()
            return
        }
        fog?.finish(at: point)
        if let revealedUrl = revealedUrl {
            self.fog?.writeRevealed(to: revealedUrl)
        }
        delegate?.toolFinished(self)
    }

    func addMarker(_ marker: UserMarker) {
        print(marker.displayName ?? "nil", marker.x, marker.y)

        if let markerView = imageView.subviews.first(where: { ($0 as? MarkerView)?.marker == marker }) {
            markerView.frame.origin = NSPoint(x: CGFloat(marker.x), y: CGFloat(marker.y))
        } else if let markerView = MarkerView.create(with: marker) {
            imageView.addSubview(markerView)
        }
    }

    private func convert(_ point: NSPoint) -> NSPoint {
        guard let parent = parent else { return point }
        return parent.view.convert(point, to: imageView)
    }

    private func draggingMarker(under point: NSPoint) -> MarkerView? {
        return imageView.subviews.first(where: { ($0 as? MarkerView)?.frame.contains(point) ?? false }) as? MarkerView
    }

}
