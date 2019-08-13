//
//  FogOfWarImageView.swift
//  MapReveal
//
//  Created by Chris Brind on 10/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

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
    
    func restore() {
        drawables.removeAll()
        currentDrawable = currentDrawFactory()
        needsDisplay = true
    }
    
    func update(from other: FogOfWarImageView) {
        drawables = other.drawables
        needsDisplay = true
    }

    func writeRevealed(to url: URL) {
        print(#function, url)
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: drawables, requiringSecureCoding: false) else {
            print(#function, "failed to archive drawables")
            return
        }
        do {
            try data.write(to: url)
        } catch {
            print(#function, "failed to write archive data")
        }
    }

    func readRevealed(from url: URL) {
        print(#function, url)

        guard let data = try? Data(contentsOf: url) else {
            print(#function, "failed to read data at", url)
            return
        }

        guard let drawables = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Drawable] else {
            print(#function, "failed to unarchive data at", url)
            return
        }
        self.drawables = drawables
    }
    
}
