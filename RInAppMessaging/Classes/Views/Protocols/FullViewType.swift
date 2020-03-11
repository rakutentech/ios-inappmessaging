internal protocol FullViewType: BaseView, AlertPresentable {
    var isOptOutChecked: Bool { get }

    func initializeView(viewModel: FullViewModel)
    func addButtons(_ buttons: [(ActionButton, viewModel: ActionButtonViewModel)])
}
