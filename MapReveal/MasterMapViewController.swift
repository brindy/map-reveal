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
        otherViewController.editable = false
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
    
}
