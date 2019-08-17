//
//  ViewController.swift
//  MapReveal
//
//  Created by Chris Brind on 02/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import Cocoa

protocol MapRendereringDelegate: NSObjectProtocol {

    func toolFinished(_ controller: MapRenderingViewController)

}

class MapRenderingViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var scrollView: NSScrollView!

    weak var delegate: MapRendereringDelegate?
    weak var fog: FogOfWarImageView?

    var revealing = true {
        didSet {
            fog?.revealing = revealing
        }
    }

    var imageUrl: URL?
    var revealedUrl: URL?
    var editable = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fogOfWar = FogOfWarImageView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
        fogOfWar.autoresizingMask = [.width, .height]
        fogOfWar.translatesAutoresizingMaskIntoConstraints = true
        imageView.addSubview(fogOfWar)
        self.fog = fogOfWar
    }
            
    func load(imageUrl: URL, revealedUrl: URL) {

        self.imageUrl = imageUrl
        self.revealedUrl = revealedUrl

        let image = NSImage(byReferencing: imageUrl)
        imageView?.image = image

        guard let currentFrame = imageView?.frame else { return }
        let newFrame = NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: image.size.width, height: image.size.height)
        imageView?.frame = newFrame
        view.needsLayout = true
        
        fog?.restore()
        scrollView.magnify(toFit: newFrame)

        DispatchQueue.global(qos: .utility).async {
            self.fog?.readRevealed(from: revealedUrl)
        }
    }

    func update(from other: FogOfWarImageView) {
        fog?.update(from: other)

        guard let image = imageView.image else { return }
        let frame = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        imageView.frame = frame
        scrollView.magnify(toFit: frame)
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
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        guard editable else { return }
        let point = convert(event.locationInWindow)
        print(#function, point)
        fog?.start(at: point)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        guard editable else { return }
        let point = convert(event.locationInWindow)
        print(#function, point)
        fog?.move(to: point)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        guard editable else { return }
        let point = convert(event.locationInWindow)
        print(#function, point)
        fog?.finish(at: point)

        if let revealedUrl = revealedUrl {
            self.fog?.writeRevealed(to: revealedUrl)
        }
        delegate?.toolFinished(self)
    }

    private func convert(_ point: NSPoint) -> NSPoint {
        guard let parent = parent else { return point }
        return parent.view.convert(point, to: imageView)
    }

}
