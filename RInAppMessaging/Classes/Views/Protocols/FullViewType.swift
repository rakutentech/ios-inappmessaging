internal protocol FullViewType: BaseView, AlertPresentable {
    var isOptOutChecked: Bool { get }

    func setup(viewModel: FullViewModel)
    func addButtons(_ buttons: [(ActionButton, viewModel: ActionButtonViewModel)])
}
