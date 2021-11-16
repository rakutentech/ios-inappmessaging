import UIKit

/// Class that initializes the modal view using the passed in campaign information to build the UI.
internal class FullScreenView: FullView {

    override class var viewIdentifier: String {
        return "IAMView-FullScreen"
    }

//    private lazy var statusBarBackgroundView: UIView = {
//        let backgroundView = UIView()
//        backgroundView.translatesAutoresizingMaskIntoConstraints = false
//        backgroundView.backgroundColor = .statusBarOverlayColor
//        return backgroundView
//    }()
//    private lazy var statusBarBackgroundViewHeightConstraint = statusBarBackgroundView.heightAnchor
//        .constraint(equalToConstant: UIApplication.shared.statusBarFrame.height)

    override var mode: Mode {
        return .fullScreen
    }

    override func updateUIConstants() {
        super.updateUIConstants()

        uiConstants.cornerRadiusForDialogView = 0
        uiConstants.dialogViewWidthOffset = 0
        uiConstants.dialogViewWidthMultiplier = 1.0
//        uiConstants.exitButtonVerticalOffset = -(36 + UIApplication.shared.statusBarFrame.height)
//        uiConstants.exitButtonSize = 25
//        uiConstants.exitButtonFontSize = 14
//        uiConstants.bodyViewSafeAreaOffsetY =
//            -uiConstants.exitButtonVerticalOffset - uiConstants.exitButtonSize + 8.0

//        if UIDevice.current.userInterfaceIdiom == .pad {
//            uiConstants.exitButtonSize = 32
//            uiConstants.exitButtonFontSize = 16
//        }
    }

//    override func setup(viewModel: FullViewModel) {
//        super.setup(viewModel: viewModel)

//        contentView.addSubview(statusBarBackgroundView)
//        NSLayoutConstraint.activate([
//            statusBarBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            statusBarBackgroundView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
//            statusBarBackgroundView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
//            statusBarBackgroundViewHeightConstraint
//        ])
//    }

//    override func layoutSubviews() {
//        super.layoutSubviews()
//
//        statusBarBackgroundView.backgroundColor = .statusBarOverlayColor
//        // statusBarFrame.height is 0 when status bar is hidden
//        statusBarBackgroundViewHeightConstraint.constant = UIApplication.shared.statusBarFrame.height
//    }
}
