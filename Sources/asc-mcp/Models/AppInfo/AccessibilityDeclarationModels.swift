import Foundation

// MARK: - Accessibility Declaration Models
//
// Accessibility Nutrition Labels — declare which accessibility features an app
// supports, per device family. Shown on the App Store product page.
// See ASC API `/v1/accessibilityDeclarations` (API 4.4).

/// Accessibility declarations list response
public struct ASCAccessibilityDeclarationsResponse: Codable, Sendable {
    public let data: [ASCAccessibilityDeclaration]
    public let links: ASCPagedDocumentLinks?
}

/// Accessibility declaration single response
public struct ASCAccessibilityDeclarationResponse: Codable, Sendable {
    public let data: ASCAccessibilityDeclaration
}

/// Accessibility declaration resource
public struct ASCAccessibilityDeclaration: Codable, Sendable {
    public let type: String
    public let id: String
    public let attributes: AccessibilityDeclarationAttributes?
}

/// Accessibility declaration attributes
public struct AccessibilityDeclarationAttributes: Codable, Sendable {
    public let deviceFamily: String?
    public let state: String?
    public let supportsAudioDescriptions: Bool?
    public let supportsCaptions: Bool?
    public let supportsDarkInterface: Bool?
    public let supportsDifferentiateWithoutColorAlone: Bool?
    public let supportsLargerText: Bool?
    public let supportsReducedMotion: Bool?
    public let supportsSufficientContrast: Bool?
    public let supportsVoiceControl: Bool?
    public let supportsVoiceover: Bool?
}

// MARK: - Accessibility Declaration Request Models

/// Create accessibility declaration request
public struct CreateAccessibilityDeclarationRequest: Codable, Sendable {
    public let data: CreateData

    public struct CreateData: Codable, Sendable {
        public let type: String = "accessibilityDeclarations"
        public let attributes: Attributes
        public let relationships: Relationships
    }

    public struct Attributes: Codable, Sendable {
        public let deviceFamily: String
        public let supportsAudioDescriptions: Bool?
        public let supportsCaptions: Bool?
        public let supportsDarkInterface: Bool?
        public let supportsDifferentiateWithoutColorAlone: Bool?
        public let supportsLargerText: Bool?
        public let supportsReducedMotion: Bool?
        public let supportsSufficientContrast: Bool?
        public let supportsVoiceControl: Bool?
        public let supportsVoiceover: Bool?
    }

    public struct Relationships: Codable, Sendable {
        public let app: AppRelationship
    }

    public struct AppRelationship: Codable, Sendable {
        public let data: ASCResourceIdentifier
    }
}

/// Update accessibility declaration request
public struct UpdateAccessibilityDeclarationRequest: Codable, Sendable {
    public let data: UpdateData

    public struct UpdateData: Codable, Sendable {
        public let type: String = "accessibilityDeclarations"
        public let id: String
        public let attributes: Attributes
    }

    public struct Attributes: Codable, Sendable {
        public let publish: Bool?
        public let supportsAudioDescriptions: Bool?
        public let supportsCaptions: Bool?
        public let supportsDarkInterface: Bool?
        public let supportsDifferentiateWithoutColorAlone: Bool?
        public let supportsLargerText: Bool?
        public let supportsReducedMotion: Bool?
        public let supportsSufficientContrast: Bool?
        public let supportsVoiceControl: Bool?
        public let supportsVoiceover: Bool?
    }
}
