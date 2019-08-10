//
//  ViewController.swift
//  MapReveal
//
//  Created by Chris Brind on 02/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import Cocoa

// using images from icon8.com

class MapRenderingViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!

    weak var fog: FogOfWarImageView?
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fogOfWar = FogOfWarImageView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
        fogOfWar.autoresizingMask = [.width, .height]
        fogOfWar.translatesAutoresizingMaskIntoConstraints = true
        imageView.addSubview(fogOfWar)
        self.fog = fogOfWar
        
    }
            
    func loadImage(_ url: URL) {
        print(#function, url)
        let image = NSImage(byReferencing: url)
        imageView?.image = image
        guard let currentFrame = imageView?.frame else { return }
        imageView?.frame = NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: image.size.width, height: image.size.height)
        view.needsLayout = true
        fog?.restore()
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
