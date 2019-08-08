//
//  ViewController.swift
//  MapReveal
//
//  Created by Chris Brind on 02/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import Cocoa

// using images from icon8.com

class ViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!

    weak var fog: FogOfWarImageView?
    
    weak var otherViewController: ViewController?
    weak var mainViewController: ViewController?
    var other = false
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fogOfWar = FogOfWarImageView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
        fogOfWar.autoresizingMask = [.width, .height]
        fogOfWar.translatesAutoresizingMaskIntoConstraints = true
        imageView.addSubview(fogOfWar)
        self.fog = fogOfWar
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        view.window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier("Paint")
        
        fog?.color = other ? NSColor.white : NSColor(white: 1.0, alpha: 0.5)
        fog?.follow = !other
        
        if otherViewController == nil && !other {
            let otherWindowController = storyboard?.instantiateController(withIdentifier: "VisibleMap") as? NSWindowController
            guard let otherViewController = otherWindowController?.contentViewController as? ViewController else { return }
            otherViewController.other = true
            otherViewController.mainViewController = self
            self.otherViewController = otherViewController
            otherWindowController?.showWindow(self)
        }
        
    }
    
    @IBAction func openDocument(_ sender: Any) {
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            mainViewController?.loadImage(panel.url!)
            otherViewController?.loadImage(panel.url!)
            loadImage(panel.url!)
        }
        
    }

    @IBAction func setRevealPaint(_ sender: Any) {
        print(#function)
    }

    @IBAction func setRevealArea(_ sender: Any) {
        print(#function)
    }
    
    @IBAction func setRevealPath(_ sender: Any) {
        print(#function)
    }
    
    @IBAction func activatePointer(_ sender: Any) {
        print(#function)
    }
    
    @IBAction func pushToOther(_ sender: Any) {
        print(#function)
        guard let fog = fog else { return }
        otherViewController?.fog?.update(from: fog)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        guard !other else { return }
        let point = view.convert(event.locationInWindow, to: imageView)
        print(#function, point)
        fog?.start(at: point)
        // otherViewController?.fog?.start(at: point)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        guard !other else { return }
        let point = view.convert(event.locationInWindow, to: imageView)
        print(#function, point)
        fog?.finish(at: point)
        // otherViewController?.fog?.finish(at: point)
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        guard !other else { return }
        let point = view.convert(event.locationInWindow, to: imageView)
        print(#function, point)
        fog?.move(to: point)
        // otherViewController?.fog?.move(to : point)
    }
    
    private func loadImage(_ url: URL) {
        print(#function, url)
        let image = NSImage(byReferencing: url)
        imageView?.image = image
        guard let currentFrame = imageView?.frame else { return }
        imageView?.frame = NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: image.size.width, height: image.size.height)
        view.needsLayout = true
        fog?.restore()
        otherViewController?.fog?.restore()
    }
    
}

class FogOfWarImageView: NSView {

    var color: NSColor = NSColor(white: 1.0, alpha: 0.5)
    var follow = true
    var currentDrawFactory: Drawable.Factory = PaintDrawable.factory
    
    private var currentDrawable: Drawable = PaintDrawable()
    private var drawables = [Drawable]()
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()
        context.cgContext.setFillColor(color.cgColor)
        context.cgContext.fill(bounds)
        
        reveal(context: context)

        if follow {
            context.cgContext.setStrokeColor(NSColor.black.cgColor)
            context.cgContext.setLineWidth(5)
            context.cgContext.setFillColor(NSColor.black.cgColor)
            currentDrawable.follow(into: context.cgContext)
        }
        
        context.restoreGraphicsState()
    }
    
    private func reveal(context: NSGraphicsContext) {
        context.saveGraphicsState()
        context.compositingOperation = .destinationIn
        context.cgContext.setFillColor(NSColor.clear.cgColor)
        context.cgContext.setStrokeColor(NSColor.clear.cgColor)
        currentDrawable.reveal(into: context.cgContext)
        drawables.forEach { $0.reveal(into: context.cgContext )}
        context.restoreGraphicsState()
    }

    func start(at point: NSPoint) {
        currentDrawable.start(at: point)
        needsDisplay = true
    }
    
    func move(to point: NSPoint) {
        currentDrawable.moved(to: point)
        needsDisplay = true
    }
    
    func finish(at point: NSPoint) {
        if currentDrawable.finish(at: point) {
            drawables.append(currentDrawable)
        }
        currentDrawable = currentDrawFactory()
        needsDisplay = true
    }
    
    func undo() {
        drawables.removeLast()
        needsDisplay = true
    }
    
    func restore() {
        drawables.removeAll()
        currentDrawable = currentDrawFactory()
        needsDisplay = true
    }
    
    func update(from other: FogOfWarImageView) {
        drawables = other.drawables
        needsDisplay = true
    }
    
}

extension NSPoint: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
}

protocol Drawable: NSObjectProtocol {
    
    typealias Factory = (() -> Drawable)
    
    func follow(into context: CGContext)
    
    func reveal(into context: CGContext)
    
    func start(at point: NSPoint)
    
    func moved(to point: NSPoint)
    
    func finish(at point: NSPoint) -> Bool
    
}

extension Drawable {
    
    func start(at point: NSPoint) { }
    
    func moved(to point: NSPoint) { }
    
    func finish(at point: NSPoint) -> Bool { return true }
    
}

class PaintDrawable: NSObject, Drawable {
    
    static func factory() -> Drawable { return PaintDrawable() }
    
    let width: CGFloat = 50
    
    var points = Set<NSPoint>()
    var lastPoint: NSPoint?
    
    func start(at point: NSPoint) {
        lastPoint = point
    }
    
    func moved(to point: NSPoint) {
        lastPoint = point
        points.insert(point)
    }
    
    func finish(at point: NSPoint) -> Bool {
        lastPoint = nil
        return !points.isEmpty
    }
    
    func follow(into context: CGContext) {
        guard let lastPoint = lastPoint else { return }
        context.strokeEllipse(in: rect(from: lastPoint))
    }
    
    func reveal(into context: CGContext) {
        points.forEach {
            context.fillEllipse(in: rect(from: $0))
        }
    }
    
    func rect(from point: NSPoint) -> CGRect {
        return CGRect(x: point.x - width / 2, y: point.y - width / 2, width: width, height: width)
    }
    
}
