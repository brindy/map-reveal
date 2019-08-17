//
//  OpenViewController.swift
//  MapReveal
//
//  Created by Christopher Brind on 13/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit

protocol OpenDelegate: NSObjectProtocol {

    func viewController(_ controller: OpenViewController, didOpenImages images: [NSImage], named: String, toRow row: Int?)

}

class OpenViewController: NSViewController {

    @IBOutlet weak var gmImage: NSImageView!
    @IBOutlet weak var playerImage: NSImageView!
    @IBOutlet weak var openButton: NSButton!
    @IBOutlet weak var nameField: NSTextField!

    weak var delegate: OpenDelegate?

    weak var droppedImage: NSImage?
    var dropRow: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        gmImage.image = droppedImage
    }

    var hasImage: Bool {
        return gmImage.image != nil || playerImage.image != nil
    }

    var hasTitle: Bool {
        return !nameField.stringValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @IBAction func imageSelected(sender: Any) {
        print(#function, sender)
        refreshOpenButton()
    }

    @IBAction func selectGMImage(sender: Any) {
        print(#function, sender)
        let panel = createOpenPanel()
        if panel.runModal() == .OK, let url = panel.url {
            gmImage.image = NSImage(contentsOf: url)
            imageSelected(sender: self)
        }

    }

    @IBAction func selectPlayerImage(sender: Any) {
        print(#function, sender)
        let panel = createOpenPanel()
        if panel.runModal() == .OK, let url = panel.url {
            playerImage.image = NSImage(contentsOf: url)
            imageSelected(sender: self)
        }
    }

    @IBAction func openClicked(sneder: Any) {
        let images = [gmImage.image, playerImage.image].compactMap { $0 }
        delegate?.viewController(self, didOpenImages: images, named: nameField.stringValue, toRow: dropRow)
        dismiss(self)
    }

    private func createOpenPanel() -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        return panel
    }

    private func refreshOpenButton() {
        openButton.isEnabled = hasImage && hasTitle
    }

}

extension OpenViewController: NSTextFieldDelegate {

    func controlTextDidChange(_ obj: Notification) {
        refreshOpenButton()
    }

}
