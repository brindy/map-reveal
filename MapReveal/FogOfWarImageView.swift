//
//  FogOfWarImageView.swift
//  MapReveal
//
//  Created by Chris Brind on 10/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

class FogOfWarImageView: NSView {

    var revealing = true {
        didSet {
            currentDrawable = currentDrawFactory(revealing)
        }
    }

    var color: NSColor = NSColor(white: 1.0, alpha: 0.5)
    var follow = true
    var currentDrawFactory: Drawable.Factory = PaintDrawable.factory
    
    private var currentDrawable: Drawable?
    private var drawables = [Drawable]()

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()
        context.cgContext.setFillColor(color.cgColor)
        context.cgContext.fill(bounds)
        
        draw(drawables, into: context)

        if let currentDrawable = currentDrawable {
            draw([currentDrawable], into: context)
        }

        if follow {
            context.cgContext.setStrokeColor(NSColor.black.cgColor)
            context.cgContext.setLineWidth(5)
            context.cgContext.setFillColor(NSColor.black.cgColor)
            currentDrawable?.follow(into: context.cgContext)
        }
        
        context.restoreGraphicsState()
    }
    
    private func draw(_ drawables: [Drawable], into context: NSGraphicsContext) {
        drawables.forEach {
            context.saveGraphicsState()

            if $0.revealing {
                context.compositingOperation = .destinationIn
                context.cgContext.setFillColor(NSColor.clear.cgColor)
                context.cgContext.setStrokeColor(NSColor.clear.cgColor)
            } else {
                context.compositingOperation = .destinationOver
                context.cgContext.setFillColor(color.cgColor)
                context.cgContext.setStrokeColor(color.cgColor)
            }
            $0.reveal(into: context.cgContext)

            context.restoreGraphicsState()
        }
    }
    
    func start(at point: NSPoint) {

        if nil == currentDrawable {
            currentDrawable = currentDrawFactory(revealing)
        }

        currentDrawable?.start(at: point)
        needsDisplay = true
    }
    
    func move(to point: NSPoint) {
        currentDrawable?.moved(to: point)
        needsDisplay = true
    }
    
    func finish(at point: NSPoint) {
        if let currentDrawable = currentDrawable, currentDrawable.finish(at: point) {
            drawables.append(currentDrawable)
            if let image = createImage() {
                drawables = [PNGDrawable(image: image)]
            }
        }
        currentDrawable = currentDrawFactory(revealing)
        needsDisplay = true
    }
    
    func restore() {
        drawables.removeAll()
        currentDrawable = currentDrawFactory(revealing)
        needsDisplay = true
    }
    
    func update(from other: FogOfWarImageView) {
        drawables = other.drawables
        needsDisplay = true
    }

    func createImage() -> CGImage? {
        let cgContext = CGContext(data: nil,
                           width: Int(frame.width),
                           height: Int(frame.height),
                           bitsPerComponent: 8,
                           bytesPerRow: 0,
                           space: CGColorSpace(name: CGColorSpace.sRGB)!,
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let nsContext = NSGraphicsContext(cgContext: cgContext, flipped: false)

        cgContext.setFillColor(CGColor.white)
        cgContext.fill(bounds)

        cgContext.fill(frame)

        draw(drawables, into: nsContext)

        return cgContext.makeImage()
    }

    func writeRevealed(to url: URL) {

        guard let image = createImage() else {
            print(#function, "failed to create image")
            return
        }

        let rep = NSBitmapImageRep(cgImage: image)
        rep.size = frame.size
        guard let imageData = rep.representation(using: .png, properties: [:]) else {
            print(#function, "failed to create representation of image")
            return
        }

        do {
            try imageData.write(to: url)
        } catch {
            print(#function, "failed to write revealed image to", url)
        }

    }

    func readRevealed(from url: URL) {
        print(#function, url)

        guard let image = NSImage(contentsOf: url) else {
            print(#function, "failed to read image at", url)
            return
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print(#function, "failed to get cgimage from image at", url)
            return
        }

        drawables = [PNGDrawable(image: cgImage)]
    }
    
}
