import UIKit
import OSLog

class SecondPageViewController: UIViewController {

    @IBAction func returnToHomepage(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        os_log("second page 1")
    }
}
