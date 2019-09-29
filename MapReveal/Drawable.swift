/*
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

    var revealing: Bool {
        return true
    }

    func follow(into context: CGContext) { }

    func start(at point: NSPoint) { }
    
    func moved(to point: NSPoint) { }
    
    func finish(at point: NSPoint) -> Bool { return true }
    
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

    static func factory(revealing: Bool) -> Drawable { return PaintDrawable(revealing) }

    let revealing: Bool

    var width: CGFloat = 50
    var points = Set<NSPoint>()
    var lastPoint: NSPoint?

    private init(_ revealing: Bool) {
        self.revealing = revealing
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
    
    private func rect(from point: NSPoint) -> CGRect {
        return CGRect(x: point.x - width / 2, y: point.y - width / 2, width: width, height: width)
    }

}

class AreaDrawable: NSObject, Drawable {

    static func factory(revealing: Bool) -> Drawable {
        return AreaDrawable(revealing)
    }

    let followFillColor = NSColor(white: 1.0, alpha: 0.5).cgColor

    let revealing: Bool

    var startPoint: NSPoint?
    var lastPoint: NSPoint?

    var rect: NSRect? {
        guard let start = startPoint else { return nil }
        guard let end = lastPoint else { return nil }
        return NSRect(x: min(end.x, start.x), y: min(end.y, start.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
    }

    private init(_ revealing: Bool) {
        self.revealing = revealing
        super.init()
    }

    func start(at point: NSPoint) {
        startPoint = point
    }

    func moved(to point: NSPoint) {
        lastPoint = point
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
