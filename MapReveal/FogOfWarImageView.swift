/*
FogOfWarImageView.swift

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

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        autoresizingMask = [.width, .height]
        translatesAutoresizingMaskIntoConstraints = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current else { return }

        // Fill in the background color
        context.saveGraphicsState()
        context.cgContext.setFillColor(color.cgColor)
        context.cgContext.fill(bounds)
        context.restoreGraphicsState()

        // Erase or draw depending on drawables revealing type
        draw(drawables, into: context)
        if let currentDrawable = currentDrawable {
            draw([currentDrawable], into: context)
        }

        // if drawing the follow of the mouse do so for current drawable
        if follow, let currentDrawable = currentDrawable {
            context.saveGraphicsState()
            context.cgContext.setStrokeColor(CGColor.black)
            context.cgContext.setLineWidth(5)
            currentDrawable.follow(into: context.cgContext)
            context.restoreGraphicsState()
        }
        
    }

    func usePaintTool() {
        currentDrawFactory = PaintDrawable.factory
        newDrawable()
    }

    func useAreaTool() {
        currentDrawFactory = AreaDrawable.factory
        newDrawable()
    }

    func start(at point: NSPoint) {

        if nil == currentDrawable {
            newDrawable()
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
        newDrawable()
        needsDisplay = true
    }
    
    func restore() {
        drawables.removeAll()
        newDrawable()
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
        DispatchQueue.main.async {
            self.needsDisplay = true
        }
    }

    private func draw(_ drawables: [Drawable], into context: NSGraphicsContext) {
        drawables.forEach {
            context.saveGraphicsState()
            configure(context, for: $0.revealing)
            $0.reveal(into: context.cgContext)
            context.restoreGraphicsState()
        }
    }

    private func newDrawable() {
        currentDrawable = currentDrawFactory(revealing)
    }

    private func configure(_ context: NSGraphicsContext, for revealing: Bool) {
        context.compositingOperation = revealing ? .destinationIn : .color
        context.cgContext.setFillColor(revealing ? CGColor.clear : CGColor.white)
    }

}
