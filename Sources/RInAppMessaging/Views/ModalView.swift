import UIKit

/// Class that initializes the modal view using the passed in campaign information to build the UI.
internal class ModalView: FullView {

    override class var viewIdentifier: String {
        return "IAMView-Modal"
    }

    override var mode: Mode {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .modal(maxWindowHeightPercentage: 0.75)
        } else {
            return .modal(maxWindowHeightPercentage: 0.65)
        }
    }

    override func updateUIConstants() {
        super.updateUIConstants()

        uiConstants.backgroundColor = UIColor.black.withAlphaComponent(0.14)
        uiConstants.cornerRadiusForDialogView = 10
        uiConstants.dialogViewWidthMultiplier = 1
        uiConstants.dialogViewWidthOffset = 100

        if UIDevice.current.userInterfaceIdiom == .pad {
            uiConstants.dialogViewWidthMultiplier = 0.6
        }
    }
}
