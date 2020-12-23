import Foundation

struct MockPinCodeResponse {
    private static var mocks = [
        "pinCodes":
        """
        { 
            "pin_codes" : [
                {
                    "pin_code": "12345abc",
                    "created_at": "2020-01-01T12:00:00Z"
                },
                {
                    "pin_code": "zxc123123",
                    "created_at": "2020-01-01T12:00:00Z"
                }
            ]
        }
        """,
    ]

    private static func index(_ resource: String) -> String? {
        guard let jsonToLoad = mocks[resource] else {
            print("FAILED TO FIND RESOURCE ACTION, PLEASE INCLUDE MOCK")
            return nil
        }

        return jsonToLoad
    }

    static func find(_: URLRequest) -> Data? {
        guard let loadJSON = index("pinCodes") else {
            return nil
        }

        return loadJSON.data(using: String.Encoding.utf8)
    }
}
