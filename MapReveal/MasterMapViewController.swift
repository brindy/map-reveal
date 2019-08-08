//
//  MasterMapViewController.swift
//  MapReveal
//
//  Created by Chris Brind on 08/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

class MasterMapViewController: NSViewController {
    
    weak var gmMap: MapRenderingViewController?
    weak var playerMap: MapRenderingViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let otherWindowController = storyboard?.instantiateController(withIdentifier: "VisibleMap") as? NSWindowController
        guard let otherViewController = otherWindowController?.contentViewController as? MapRenderingViewController else { return }
        otherViewController.fog?.color = NSColor.white
        self.playerMap = otherViewController
        otherWindowController?.showWindow(self)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier("Paint")
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let controller = segue.destinationController as? MapRenderingViewController {
            gmMap = controller
        }
    }
    
    @IBAction func openDocument(_ sender: Any) {
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            gmMap?.loadImage(panel.url!)
            playerMap?.loadImage(panel.url!)
        }
        
    }

    @IBAction func setRevealPaint(_ sender: Any) {
        print(#function)
    }
    
    @IBAction func setRevealArea(_ sender: Any) {
        print(#function)
    }
    
    @IBAction func setRevealPath(_ sender: Any) {
        print(#function)
    }
    
    @IBAction func activatePointer(_ sender: Any) {
        print(#function)
    }
    
    @IBAction func pushToOther(_ sender: Any) {
        print(#function)
        guard let fog = gmMap?.fog else { return }
        playerMap?.fog?.update(from: fog)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let point = view.convert(event.locationInWindow, to: gmMap?.imageView)
        print(#function, point)
        gmMap?.fog?.start(at: point)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        let point = view.convert(event.locationInWindow, to: gmMap?.imageView)
        print(#function, point)
        gmMap?.fog?.finish(at: point)
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        let point = view.convert(event.locationInWindow, to: gmMap?.imageView)
        print(#function, point)
        gmMap?.fog?.move(to: point)
    }

}
