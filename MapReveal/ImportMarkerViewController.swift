/*
ImportMarkerViewController.swift

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

protocol ImportMarkerDelegate: NSObjectProtocol {

    func viewController(_ controller: ImportMarkerViewController, didOpenImage image: NSImage, named: String, copies: Int, toRow row: Int?)

}

class ImportMarkerViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var openButton: NSButton!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var copiesField: NSTextField!

    weak var delegate: ImportMarkerDelegate?

    weak var droppedImage: NSImage?
    var dropRow: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = droppedImage
    }

    var hasImage: Bool {
        return imageView.image != nil
    }

    var hasTitle: Bool {
        return !nameField.stringValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @IBAction func imageSelected(sender: Any) {
        print(#function, sender)
        refreshOpenButton()
    }

    @IBAction func selectImage(sender: Any) {
        print(#function, sender)
        let panel = createOpenPanel()
        if panel.runModal() == .OK, let url = panel.url {
            imageView.image = NSImage(contentsOf: url)
            imageSelected(sender: self)
        }

    }

   @IBAction func openClicked(sneder: Any) {
        guard let image = imageView.image else { return }
        delegate?.viewController(self, didOpenImage: image, named: nameField.stringValue, copies: copiesField.integerValue, toRow: dropRow)
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

extension ImportMarkerViewController: NSTextFieldDelegate {

    func controlTextDidChange(_ obj: Notification) {
        refreshOpenButton()
    }

}
