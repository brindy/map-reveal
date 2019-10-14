
import Cocoa

// FROM: https://stackoverflow.com/a/28154936/73479
class CenteringClipView: NSClipView {

    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {

        var rect = super.constrainBoundsRect(proposedBounds)
        if let containerView = self.documentView {

            if (rect.size.width > containerView.frame.size.width) {
                rect.origin.x = (containerView.frame.width - rect.width) / 2
            }

            if(rect.size.height > containerView.frame.size.height) {
                rect.origin.y = (containerView.frame.height - rect.height) / 2
            }
        }

        return rect
    }

}
