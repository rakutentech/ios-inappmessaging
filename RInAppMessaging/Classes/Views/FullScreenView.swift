/// Class that initializes the modal view using the passed in campaign information to build the UI.
internal class FullScreenView: FullView {

    override var mode: FullViewMode {
        return .fullScreen
    }

    override func updateUIConstants() {
        super.updateUIConstants()

        uiConstants.cornerRadiusForDialogView = 0
        uiConstants.dialogViewWidthOffset = 0
        uiConstants.dialogViewWidthMultiplier = 1.0
        uiConstants.exitButtonVerticalOffset = -56
        uiConstants.exitButtonSize = 25
        uiConstants.exitButtonFontSize = 14
        uiConstants.bodyViewSafeAreaOffsetY =
            -uiConstants.exitButtonVerticalOffset - uiConstants.exitButtonSize + 8.0

        if UIDevice.current.userInterfaceIdiom == .pad {
            uiConstants.exitButtonSize = 32
            uiConstants.exitButtonFontSize = 16
        }
    }
}
