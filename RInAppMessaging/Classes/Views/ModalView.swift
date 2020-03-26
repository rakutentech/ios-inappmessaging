/// Class that initializes the modal view using the passed in campaign information to build the UI.
internal class ModalView: FullView {

    override var mode: FullViewMode {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .modal(maxWindowHeightPercentage: 0.75)
        } else {
            return .modal(maxWindowHeightPercentage: 0.65)
        }
    }

    override func setup(viewModel: FullViewModel) {
        super.setup(viewModel: viewModel)
        exitButton.invertedColors = true
    }

    override func updateUIConstants() {
        super.updateUIConstants()

        uiConstants.backgroundColor = UIColor.black.withAlphaComponent(0.66)
        uiConstants.cornerRadiusForDialogView = 8
        uiConstants.dialogViewWidthMultiplier = 1
        uiConstants.exitButtonVerticalOffset = 10
        uiConstants.dialogViewWidthOffset = 100
        uiConstants.exitButtonSize = 15
        uiConstants.exitButtonFontSize = 13

        if UIDevice.current.userInterfaceIdiom == .pad {
            uiConstants.exitButtonVerticalOffset = 16
            uiConstants.dialogViewWidthMultiplier = 0.6
            uiConstants.exitButtonSize = 22
            uiConstants.exitButtonFontSize = 16
        }
    }
}
