//
//  ViewController.swift
//  MapReveal
//
//  Created by Chris Brind on 02/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var imageView: FogOfWarImageView!
    
    var otherWindowController: NSWindowController?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if otherWindowController == nil {
            otherWindowController = storyboard?.instantiateController(withIdentifier: "VisibleMap") as? NSWindowController
            otherWindowController?.showWindow(self)        
        }
    }
    
    @IBAction func openDocument(_ sender: Any) {
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            loadImage(panel.url!)
        }
        
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        reveal(event: event)
        print(#function, event)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        print(#function)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        print(#function)
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        print(#function, event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        reveal(event: event)
    }
   
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        print(#function, event)
    }
    
    private func loadImage(_ url: URL) {
        print(#function, url)
        imageView?.image = NSImage(byReferencing: url)
    }
    
    func reveal(event: NSEvent) {
        let point = view.convert(event.locationInWindow, to: imageView)
        print(#function, point)

        guard let fog = imageView.fog else { return }
        print(#function, fog.bytesPerRow)

        let x = Int(point.x)
        let y = Int(point.y)
        
        guard x > 0, x < fog.width, y > 0, y < fog.height else { return }
        
        imageView.fog = drawPixels(pixelsAround(x: x, y: fog.height - y, size: 50), on: fog, in: .transparent)
        imageView.needsDisplay = true
        
        // TODO draw the drawing rectangle as mouse is moved
    }
    
}

class FogOfWarImageView: NSView {

    var color: NSColor = NSColor(white: 1.0, alpha: 0.5)
    
    var fog: CGImage?
  
    var image: NSImage? {
        didSet {
            guard let image = image else { return }
            let currentFrame = frame
            frame = NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: image.size.width, height: image.size.height)
            
//            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
//            let currentCIImage = CIImage(cgImage: cgImage)
//
//            let filter = CIFilter(name: "CIColorMonochrome")
//            filter?.setValue(currentCIImage, forKey: "inputImage")
//
//            // set a gray value for the tint color
//            filter?.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: "inputColor")
//
//            filter?.setValue(1.0, forKey: "inputIntensity")
//            guard let outputImage = filter?.outputImage else { return }
//
//            let context = CIContext()
//
//            fog = context.createCGImage(outputImage, from: outputImage.extent)
            
            let colorSpace       = CGColorSpaceCreateDeviceRGB()
            let width            = Int(image.size.width)
            let height           = Int(image.size.height)
            let bytesPerPixel    = 4
            let bitsPerComponent = 8
            let bytesPerRow      = bytesPerPixel * width
            let bitmapInfo       = RGBA32.bitmapInfo

            guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
                print("Cannot create context!"); return
            }
            
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))

            fog = context.makeImage()
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
    
        image?.draw(in: bounds)
        
        if let fog = fog {
            context.draw(fog, in: bounds)
        }
        
//        context.setFillColor(NSColor(calibratedWhite: 1, alpha: 0.5).cgColor)
//        context.fill(bounds)
//
//        context.setStrokeColor(NSColor.white.cgColor)
//
//        context.setBlendMode(.destinationOut)
//        context.beginPath()
//        context.move(to: NSPoint(x: 10, y: self.bounds.height / 2))
//        context.addLine(to: NSPoint(x: self.bounds.width - 10, y: self.bounds.height / 2))
//        context.setLineWidth(6)
//        context.setLineCap(.round)
//        context.strokePath()
    
//        NSColor.white.set()
//        let clippingPath = NSBezierPath()
//        clippingPath.move(to: CGPoint(x: 10, y: self.bounds.height / 2))
//        clippingPath.line(to: NSPoint(x: self.bounds.width - 10, y: self.bounds.height / 2))
//        clippingPath.lineWidth = 6
//        clippingPath.lineCapStyle = .round
//        clippingPath.stroke()
        
        context.restoreGState()
    }
    
}

func drawPixels(_ pixels: [(x:Int, y:Int)], on image: CGImage, in: RGBA32) -> CGImage? {
    let colorSpace       = CGColorSpaceCreateDeviceRGB()
    let width            = image.width
    let height           = image.height
    let bytesPerPixel    = 4
    let bitsPerComponent = 8
    let bytesPerRow      = bytesPerPixel * width
    let bitmapInfo       = RGBA32.bitmapInfo

    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
        print("Cannot create context!"); return nil
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    guard let buffer = context.data else { print("Cannot get context data!"); return nil }

    let capacity = width * height
    let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: capacity)

    pixels.forEach {
        let index = $0.y * width + $0.x
        guard index > 0, index < capacity else { return }
        pixelBuffer[index] = .transparent
    }
    
    return context.makeImage()
}

struct RGBA32: Equatable {
    private var color: UInt32

    var redComponent: UInt8 {
        return UInt8((color >> 24) & 255)
    }

    var greenComponent: UInt8 {
        return UInt8((color >> 16) & 255)
    }

    var blueComponent: UInt8 {
        return UInt8((color >> 8) & 255)
    }

    var alphaComponent: UInt8 {
        return UInt8((color >> 0) & 255)
    }

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        let red   = UInt32(red)
        let green = UInt32(green)
        let blue  = UInt32(blue)
        let alpha = UInt32(alpha)
        color = (red << 24) | (green << 16) | (blue << 8) | (alpha << 0)
    }

    static let red         = RGBA32(red: 255, green: 0,   blue: 0,   alpha: 255)
    static let green       = RGBA32(red: 0,   green: 255, blue: 0,   alpha: 255)
    static let blue        = RGBA32(red: 0,   green: 0,   blue: 255, alpha: 255)
    static let white       = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
    static let black       = RGBA32(red: 0,   green: 0,   blue: 0,   alpha: 255)
    static let magenta     = RGBA32(red: 255, green: 0,   blue: 255, alpha: 255)
    static let yellow      = RGBA32(red: 255, green: 255, blue: 0,   alpha: 255)
    static let cyan        = RGBA32(red: 0,   green: 255, blue: 255, alpha: 255)
    static let transparent = RGBA32(red: 0,   green: 0,   blue: 0,   alpha: 0)

    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

    static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
        return lhs.color == rhs.color
    }
}

func pixelsAround(x: Int, y: Int, size: Int) -> [ (Int, Int) ] {
    var pixels: [(Int, Int)] = []
    for x in x - size ..< x + size {
        for y in y - size ..< y + size {
            pixels.append((x, y))
        }
    }
    return pixels
}
