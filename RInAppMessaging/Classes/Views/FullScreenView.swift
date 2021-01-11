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
        uiConstants.exitButtonVerticalOffset = -(36 + UIApplication.shared.statusBarFrame.height)
        uiConstants.exitButtonSize = 25
        uiConstants.exitButtonFontSize = 14
        uiConstants.bodyViewSafeAreaOffsetY =
            -uiConstants.exitButtonVerticalOffset - uiConstants.exitButtonSize + 8.0

        if UIDevice.current.userInterfaceIdiom == .pad {
            uiConstants.exitButtonSize = 32
            uiConstants.exitButtonFontSize = 16
        }
    }

    override func setup(viewModel: FullViewModel) {
        super.setup(viewModel: viewModel)

        guard hasImage else {
            return
        }

        let statusBarBackground = UIView()
        statusBarBackground.translatesAutoresizingMaskIntoConstraints = false
        statusBarBackground.backgroundColor = UIColor.statusBarOverlayColor

        contentView.addSubview(statusBarBackground)
        NSLayoutConstraint.activate([
            statusBarBackground.topAnchor.constraint(equalTo: contentView.topAnchor),
            statusBarBackground.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            statusBarBackground.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            statusBarBackground.heightAnchor.constraint(equalToConstant: UIApplication.shared.statusBarFrame.height)
        ])
    }
}
