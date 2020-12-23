import UIKit

extension UIViewController {
    func presentAgeVerificationConfirmationAlert(_ dateAsString: String) {
        let alertController = UIAlertController(
            title: "AgeVerification.Confirmed.Title".localized,
            message: "AgeVerification.Confirmed.Message".localized + dateAsString,
            preferredStyle: .alert)

        alertController.addAction(UIAlertAction(
            title: "OKButton.Title".localized,
            style: .default,
            handler: nil)
        )

        present(alertController, animated: true, completion: nil)
    }

    func presentAgeVerificationInvalidAgeAlert() {
        let alertController = UIAlertController(
            title: "Onboarding.AgeVerification.Error.Title".localized,
            message: "Onboarding.AgeVerification.Error.InvalidAge".localized,
            preferredStyle: .alert)

        alertController.addAction(UIAlertAction(
            title: "OKButton.Title".localized,
            style: .default,
            handler: nil)
        )

        present(alertController, animated: true, completion: nil)
    }

    func presentAgeVerificationExplanationAlert() {
        let alertController = UIAlertController(
            title: "AgeVerification.Explanation.Title".localized,
            message: "AgeVerification.Explanation.Message".localized,
            preferredStyle: .alert)

        alertController.addAction(UIAlertAction(
            title: "CloseButton.Title".localized,
            style: .cancel,
            handler: nil))

        present(alertController, animated: true, completion: nil)
    }
}
