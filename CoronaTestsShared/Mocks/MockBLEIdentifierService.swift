import Foundation

class MockBLEIdentifierService: BLEIdentifierServiceProviding {
    var identifierToUse: BLEIdentifier?  {
        BLEIdentifier(expiration: Date().addingTimeInterval(15 * 60),
                      identifier: "i-am-an-identifier-lol")
    }

    func clear() { }
}
