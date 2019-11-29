//
//  BorderColorCycler.swift
//  MapReveal
//
//  Created by Christopher Brind on 29/11/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

class BorderColorCycler {

    let view: NSView
    let every: TimeInterval
    let colors: [NSColor]

    var timer: Timer?
    var index = 0

    init(view: NSView, every: TimeInterval, colors: [NSColor]) {
        self.view = view
        self.every = every
        self.colors = colors
    }

    func start() {
        cycleColor()
        timer = Timer.scheduledTimer(withTimeInterval: every, repeats: true, block: { _ in
            self.cycleColor()
        })
    }

    func cycleColor() {
        view.layer?.borderColor = colors[index].cgColor
        index += 1
        if index >= colors.count {
            index = 0
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    static func animateBorder(of view: NSView, every: TimeInterval, with colors: [NSColor]) -> BorderColorCycler {
        let cycler = BorderColorCycler(view: view, every: every, colors: colors)
        cycler.start()
        return cycler
    }

}
