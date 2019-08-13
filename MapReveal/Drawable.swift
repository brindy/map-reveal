//
//  Drawable.swift
//  MapReveal
//
//  Created by Chris Brind on 08/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

protocol Drawable: NSObjectProtocol, NSCoding {
    
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

    struct Keys {
        static let points = "points"
    }

    var points = Set<NSPoint>()

    var width: CGFloat = 50
    var lastPoint: NSPoint?

    required init?(coder: NSCoder) {
        points = (coder.decodeObject(forKey: Keys.points) as? Set<NSPoint>) ?? Set<NSPoint>()
    }

    override init() {
        super.init()
    }

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

    func encode(with coder: NSCoder) {
        coder.encode(points, forKey: Keys.points)
    }

}

extension NSPoint: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
}
