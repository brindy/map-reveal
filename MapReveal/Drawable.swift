//
//  Drawable.swift
//  MapReveal
//
//  Created by Chris Brind on 08/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

protocol Drawable: NSObjectProtocol {
    
    typealias Factory = ((Bool) -> Drawable)

    var revealing: Bool { get }

    func follow(into context: CGContext)
    
    func reveal(into context: CGContext)
    
    func start(at point: NSPoint)
    
    func moved(to point: NSPoint)
    
    func finish(at point: NSPoint) -> Bool

}

extension Drawable {

    func follow(into context: CGContext) { }

    func start(at point: NSPoint) { }
    
    func moved(to point: NSPoint) { }
    
    func finish(at point: NSPoint) -> Bool { return true }
    
}

class PNGDrawable: NSObject, Drawable {

    var revealing: Bool = true

    let image: CGImage

    init(image: CGImage) {
        self.image = image
    }

    func reveal(into context: CGContext) {
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }

}

class PaintDrawable: NSObject, Drawable {

    static func factory(revealing: Bool) -> Drawable { return PaintDrawable(revealing) }

    struct Keys {
        static let points = "points"
    }

    let revealing: Bool

    init(_ revealing: Bool) {
        self.revealing = revealing
        super.init()
    }

    var points = Set<NSPoint>()

    var width: CGFloat = 50
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

extension NSPoint: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
}
