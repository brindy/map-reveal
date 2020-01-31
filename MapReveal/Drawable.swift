/*
Drawable.swift

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

protocol Drawable: NSObjectProtocol {
    
    typealias Factory = ((Bool) -> Drawable)

    var isRevealing: Bool { get }

    func follow(into context: CGContext)
    
    func reveal(into context: CGContext)

    /// @return true if finished
    func down(at point: NSPoint) -> Bool

    func moved(to point: NSPoint)

    /// @return true if finished
    func up(at point: NSPoint) -> Bool
    

}

extension Drawable {

    var isRevealing: Bool {
        return true
    }

    func follow(into context: CGContext) { }

    func down(at point: NSPoint) -> Bool { return true }

    func moved(to point: NSPoint) { }

    func up(at point: NSPoint) -> Bool { return true }

}

class PNGDrawable: NSObject, Drawable {

    let image: CGImage

    init(image: CGImage) {
        self.image = image
    }

    func reveal(into context: CGContext) {
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }

}

class PaintDrawable: NSObject, Drawable {

    static func factory(isRevealing: Bool) -> Drawable { return PaintDrawable(isRevealing) }

    let isRevealing: Bool

    var width: CGFloat = 50
    var points = Set<NSPoint>()
    var lastPoint: NSPoint?

    private init(_ revealing: Bool) {
        self.isRevealing = revealing
        super.init()
    }

    func down(at point: NSPoint) -> Bool {
        lastPoint = point
        return false
    }
    
    func moved(to point: NSPoint) {
        lastPoint = point
        points.insert(point)
    }
    
    func up(at point: NSPoint) -> Bool {
        lastPoint = nil
        return true
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
    
    private func rect(from point: NSPoint) -> CGRect {
        return CGRect(x: point.x - width / 2, y: point.y - width / 2, width: width, height: width)
    }

}

class PathDrawable: NSObject, Drawable {

    static func factory(revealing: Bool) -> Drawable {
        return PathDrawable(revealing)
    }

    let isRevealing: Bool

    var startPoint: NSPoint?
    var lastPoint: NSPoint?
    var path: CGMutablePath?

    init(_ revealing: Bool) {
        self.isRevealing = revealing
    }

    func down(at point: NSPoint) -> Bool {

        var finished = false
        if nil == path {
            path = CGMutablePath()
            path?.move(to: point)
        } else {
            finished = lastPoint == point
            lastPoint = point
            path?.addLine(to: point)
            startPoint = point
        }

        print(#function, lastPoint as Any, point, finished)
        return finished
    }

    func up(at point: NSPoint) -> Bool {
        return false
    }

    func reveal(into context: CGContext) {

        print(#function)

        guard let path = path else { return }

        context.addPath(path)
        context.fillPath()

    }

    func follow(into context: CGContext) {

        print(#function, path as Any)

        guard let path = path else { return }

        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(10.0)
        context.addPath(path)
        context.strokePath()
        context.fillPath()
    }

}

class AreaDrawable: NSObject, Drawable {

    static func factory(revealing: Bool) -> Drawable {
        return AreaDrawable(revealing)
    }

    let followFillColor = NSColor(white: 1.0, alpha: 0.5).cgColor

    let isRevealing: Bool

    var startPoint: NSPoint?
    var lastPoint: NSPoint?

    var rect: NSRect? {
        guard let start = startPoint else { return nil }
        guard let end = lastPoint else { return nil }
        return NSRect(x: min(end.x, start.x), y: min(end.y, start.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
    }

    private init(_ revealing: Bool) {
        self.isRevealing = revealing
        super.init()
    }

    func down(at point: NSPoint) -> Bool {
        startPoint = point
        return false
    }

    func moved(to point: NSPoint) {
        lastPoint = point
    }

    func up(at point: NSPoint) -> Bool {
        lastPoint = point
        return true
    }

    func reveal(into context: CGContext) {
        if let rect = rect {
            context.fill(rect)
        }
    }

    func follow(into context: CGContext) {
        if let rect = rect {
            context.stroke(rect)
        }
    }

}

extension NSPoint: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
}
