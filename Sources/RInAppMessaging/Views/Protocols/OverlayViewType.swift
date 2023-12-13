internal protocol OverlayViewType: BaseView {
    var isOptOutChecked: Bool { get }

    func setup(viewModel: OverlayViewModel)
    func addButtons(_ buttons: [(ActionButton, viewModel: ActionButtonViewModel)])
}
