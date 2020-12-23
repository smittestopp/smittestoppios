import Foundation

extension JSONDecoder {
    static var standard: JSONDecoder {
        let decoder = JSONDecoder()
        // Date decoding strategy that support ISO8601-formatted dates with and without milliseconds.
        // E.g.
        //   2019-12-02T11:13:24Z
        // and
        //   2019-12-02T11:13:24.123Z
        decoder.dateDecodingStrategy = .custom({ decoder -> Date in
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)

            guard let date = Date(iso8601String: stringValue) else {
                throw DecodingError.typeMismatch(
                    Date.self,
                    DecodingError.Context(codingPath: decoder.codingPath,
                                          debugDescription: "Failed to parse date string. Expecting ISO8601-formatted date."))
            }

            return date
        })
        return decoder
    }
}
