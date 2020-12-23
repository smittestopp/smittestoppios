import UIKit

public enum OnboardingPageType: String, Decodable {
    case ageVerification
    case page
    case privacy
    case permissions
    case register

    public init?(rawValue: String) {
        switch rawValue {
        case "ageVerification": self = .ageVerification
        case "privacy": self = .privacy
        case "permissions": self = .permissions
        case "register": self = .register
        default: self = .page
        }
    }
}

public struct Onboarding: Decodable {
    public let pages: [OnboardingPage]
}

public struct OnboardingPage: Decodable {
    public let type: OnboardingPageType
    public let items: [OnboardingPageItemElement]
    public let buttonText: String
    public let buttonAction: OnboardingButtonAction
    public let buttonIdentifier: String
}

public enum OnboardingPageItemElement: Decodable {
    case spacer(size: Int)
    case label(text: String, size: CGFloat, bold: Bool, identifier: String)
    case localImage(named: String)
    case image(url: String)

    private enum ElementType: String, Codable {
        case text
        case localImage
        case image
        case spacer
    }

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case size
        case bold
        case url
        case named
        case identifier
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(ElementType.self, forKey: .type)

        switch type {
        case .text:
            let text = try container.decode(String.self, forKey: .text)
            let size = try container.decode(CGFloat.self, forKey: .size)
            let bold = try container.decode(Bool.self, forKey: .bold)
            let identifier = try container.decode(String.self, forKey: .identifier)
            self = .label(text: text, size: size, bold: bold, identifier: identifier)
        case .localImage:
            let named = try container.decode(String.self, forKey: .named)
            self = .localImage(named: named)
        case .image:
            let url = try container.decode(String.self, forKey: .url)
            self = .image(url: url)
        case .spacer:
            let size = try container.decode(Int.self, forKey: .size)
            self = .spacer(size: size)
        }
    }
}

public enum OnboardingButtonAction: String, Decodable {
    case next
    case privacyPolicy
    case register
}
