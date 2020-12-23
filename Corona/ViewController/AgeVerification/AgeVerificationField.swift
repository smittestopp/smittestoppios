import UIKit

class AgeVerificationField: UITextField {
    var registerAge: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        adjustsFontForContentSizeCategory = true
        font = .custom(.regular, size: 18, forTextStyle: .body)
        accessibilityIdentifier = "ageVerificationTextField"
        textAlignment = .center
        layer.cornerRadius = 8.0
        layer.masksToBounds = true
        inputView = datePicker
        inputAccessoryView = toolbar
    }

    lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        return datePicker
    }()

    lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonTapped))
        doneButton.accessibilityIdentifier = "ageVerificationDoneButton"
        toolbar.setItems([flexibleSpace, doneButton], animated: true)
        return toolbar
    }()

    @objc func doneButtonTapped(_: UIBarButtonItem) {
        registerAge?()
    }
}
