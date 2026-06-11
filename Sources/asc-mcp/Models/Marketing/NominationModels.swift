import Foundation

// MARK: - Nomination Models
//
// App Store nominations — submit an app for editorial featuring on the App Store
// (app launch, app enhancements, or new content). See ASC API `/v1/nominations`.

/// Nominations list response
public struct ASCNominationsResponse: Codable, Sendable {
    public let data: [ASCNomination]
    public let links: ASCPagedDocumentLinks?
}

/// Nomination single response
public struct ASCNominationResponse: Codable, Sendable {
    public let data: ASCNomination
}

/// Nomination resource
public struct ASCNomination: Codable, Sendable {
    public let type: String
    public let id: String
    public let attributes: NominationAttributes?
}

/// Nomination attributes (read-back)
public struct NominationAttributes: Codable, Sendable {
    public let name: String?
    public let type: String?
    public let description: String?
    public let createdDate: String?
    public let lastModifiedDate: String?
    public let submittedDate: String?
    public let state: String?
    public let publishStartDate: String?
    public let publishEndDate: String?
    public let deviceFamilies: [String]?
    public let locales: [String]?
    public let supplementalMaterialsUris: [String]?
    public let hasInAppEvents: Bool?
    public let launchInSelectMarketsFirst: Bool?
    public let notes: String?
    public let preOrderEnabled: Bool?
}

// MARK: - Nomination Request Models

/// Create nomination request
public struct CreateNominationRequest: Codable, Sendable {
    public let data: CreateData

    public struct CreateData: Codable, Sendable {
        public let type: String
        public let attributes: Attributes
        public let relationships: Relationships

        public init(attributes: Attributes, relationships: Relationships) {
            self.type = "nominations"
            self.attributes = attributes
            self.relationships = relationships
        }
    }

    public struct Attributes: Codable, Sendable {
        public let name: String
        public let type: String
        public let description: String
        public let submitted: Bool
        public let publishStartDate: String
        public let publishEndDate: String?
        public let deviceFamilies: [String]?
        public let locales: [String]?
        public let supplementalMaterialsUris: [String]?
        public let hasInAppEvents: Bool?
        public let launchInSelectMarketsFirst: Bool?
        public let notes: String?
        public let preOrderEnabled: Bool?
    }

    public struct Relationships: Codable, Sendable {
        public let relatedApps: RelationshipData
        public let inAppEvents: RelationshipData?
        public let supportedTerritories: RelationshipData?
    }

    public struct RelationshipData: Codable, Sendable {
        public let data: [ASCResourceIdentifier]
    }
}

/// Update nomination request
public struct UpdateNominationRequest: Codable, Sendable {
    public let data: UpdateData

    public struct UpdateData: Codable, Sendable {
        public let type: String
        public let id: String
        public let attributes: Attributes

        public init(id: String, attributes: Attributes) {
            self.type = "nominations"
            self.id = id
            self.attributes = attributes
        }
    }

    public struct Attributes: Codable, Sendable {
        public let name: String?
        public let type: String?
        public let description: String?
        public let submitted: Bool?
        public let archived: Bool?
        public let publishStartDate: String?
        public let publishEndDate: String?
        public let deviceFamilies: [String]?
        public let locales: [String]?
        public let supplementalMaterialsUris: [String]?
        public let hasInAppEvents: Bool?
        public let launchInSelectMarketsFirst: Bool?
        public let notes: String?
        public let preOrderEnabled: Bool?
    }
}
