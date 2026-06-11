import Foundation

// MARK: - Subscription Plan Availability Models
//
// Per-plan territory availability (planType MONTHLY/UPFRONT) — the API 4.4 successor
// to the deprecated `subscriptionAvailabilities`. See `/v1/subscriptionPlanAvailabilities`.

/// Subscription plan availabilities list response
public struct ASCSubscriptionPlanAvailabilitiesResponse: Codable, Sendable {
    public let data: [ASCSubscriptionPlanAvailability]
    public let links: ASCPagedDocumentLinks?
}

/// Subscription plan availability single response
public struct ASCSubscriptionPlanAvailabilityResponse: Codable, Sendable {
    public let data: ASCSubscriptionPlanAvailability
}

/// Subscription plan availability resource
public struct ASCSubscriptionPlanAvailability: Codable, Sendable {
    public let type: String
    public let id: String
    public let attributes: SubscriptionPlanAvailabilityAttributes?
}

/// Subscription plan availability attributes
public struct SubscriptionPlanAvailabilityAttributes: Codable, Sendable {
    public let availableInNewTerritories: Bool?
    public let planType: String?
}

// MARK: - Request Models

/// Create subscription plan availability request
public struct CreateSubscriptionPlanAvailabilityRequest: Codable, Sendable {
    public let data: CreateData

    public struct CreateData: Codable, Sendable {
        public let type: String = "subscriptionPlanAvailabilities"
        public let attributes: Attributes
        public let relationships: Relationships
    }

    public struct Attributes: Codable, Sendable {
        public let planType: String
        public let availableInNewTerritories: Bool?
    }

    public struct Relationships: Codable, Sendable {
        public let subscription: SubscriptionRelationship
        public let availableTerritories: TerritoriesRelationship
    }

    public struct SubscriptionRelationship: Codable, Sendable {
        public let data: ASCResourceIdentifier
    }

    public struct TerritoriesRelationship: Codable, Sendable {
        public let data: [ASCResourceIdentifier]
    }
}
