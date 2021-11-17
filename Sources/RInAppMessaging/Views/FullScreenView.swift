import UIKit

/// Class that initializes the modal view using the passed in campaign information to build the UI.
internal class FullScreenView: FullView {

    override class var viewIdentifier: String {
        return "IAMView-FullScreen"
    }

    override var mode: Mode {
        return .fullScreen
    }

    override func updateUIConstants() {
        super.updateUIConstants()

        uiConstants.cornerRadiusForDialogView = 0
        uiConstants.dialogViewWidthOffset = 0
        uiConstants.dialogViewWidthMultiplier = 1.0
    }
}
