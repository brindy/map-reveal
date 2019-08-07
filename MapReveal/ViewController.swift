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
            loadImage(panel.url!)
        }
        
    }
    
    @IBAction func setRevealPaint(_ sender: Any) {
        print(#function)
    }

    @IBAction func setRevealArea(_ sender: Any) {
        print(#function)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        guard !other else { return }
        let point = view.convert(event.locationInWindow, to: imageView)
        print(#function, point)
        fog?.start(point)
        otherViewController?.fog?.start(point)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        guard !other else { return }
        let point = view.convert(event.locationInWindow, to: imageView)
        print(#function, point)
        fog?.finish()
        otherViewController?.fog?.finish()
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        guard !other else { return }
        let point = view.convert(event.locationInWindow, to: imageView)
        print(#function, point)
        fog?.move(point)
        otherViewController?.fog?.move(point)
    }
    
    private func loadImage(_ url: URL) {
        print(#function, url)
        let image = NSImage(byReferencing: url)
        imageView?.image = image
        guard let currentFrame = imageView?.frame else { return }
        imageView?.frame = NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: image.size.width, height: image.size.height)
        view.needsLayout = true
    }
    
}

class FogOfWarImageView: NSView {

    var color: NSColor = NSColor(white: 1.0, alpha: 0.5)
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()
        context.cgContext.setFillColor(color.cgColor)
        context.cgContext.fill(bounds)
        
        context.compositingOperation = .destinationIn
        context.cgContext.setFillColor(NSColor.clear.cgColor)
        
        let width: CGFloat = 50
        points.forEach {
            let rect = CGRect(x: $0.x - width / 2, y: $0.y - width / 2, width: width, height: width)
            context.cgContext.fillEllipse(in: rect)
        }
        
        context.restoreGraphicsState()
    }
    
    var points = Set<NSPoint>()
    
    func start(_ point: NSPoint) {
    }
    
    func move(_ point: NSPoint) {
        points.insert(point)
        needsDisplay = true
    }
    
    func finish() {
    }
     
}

extension NSPoint: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
}
