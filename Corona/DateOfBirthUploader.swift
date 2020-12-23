import Foundation

protocol HasDateOfBirthUploader {
    var dateOfBirthUploader: DateOfBirthUploaderProviding { get }
}

protocol DateOfBirthUploaderProviding: class {
    func uploadIfNeeded()
}

class DateOfBirthUploader: DateOfBirthUploaderProviding {
    private let localStorage: LocalStorageServiceProviding
    private let apiService: ApiServiceProviding

    init(localStorage: LocalStorageServiceProviding, apiService: ApiServiceProviding) {
        self.localStorage = localStorage
        self.apiService = apiService
    }

    func uploadIfNeeded() {
        guard !localStorage.isDateOfBirthUploaded else {
            return
        }
        upload()
    }

    func upload() {
        guard let year = localStorage.dateOfBirth?.year else { return }

        apiService.sendYearOfBirth(year: year) { result in
            switch result {
            case .success:
                self.localStorage.isDateOfBirthUploaded = true

            case let .failure(error):
                Logger.error("Failed to send year of birth: \(error)", tag: "DateOfBirthUploader")
            }
        }
    }
}
