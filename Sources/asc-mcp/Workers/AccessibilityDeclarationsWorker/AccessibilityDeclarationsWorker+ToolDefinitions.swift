import Foundation
import MCP

// MARK: - Tool Definitions
extension AccessibilityDeclarationsWorker {

    private var supportFlagProperties: [String: Value] {
        let flags = [
            "supports_audio_descriptions", "supports_captions", "supports_dark_interface",
            "supports_differentiate_without_color_alone", "supports_larger_text",
            "supports_reduced_motion", "supports_sufficient_contrast",
            "supports_voice_control", "supports_voiceover"
        ]
        var props: [String: Value] = [:]
        for flag in flags {
            props[flag] = .object([
                "type": .string("boolean"),
                "description": .string("Accessibility feature support flag: \(flag)")
            ])
        }
        return props
    }

    func listAccessibilityDeclarationsTool() -> Tool {
        return Tool(
            name: "accessibility_list",
            description: "List Accessibility Nutrition Label declarations for an app (one per device family). Shows which accessibility features the app declares supporting on the App Store.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "app_id": .object([
                        "type": .string("string"),
                        "description": .string("App ID to list accessibility declarations for")
                    ]),
                    "filter_device_family": .object([
                        "type": .string("string"),
                        "description": .string("Filter by device family: IPHONE, IPAD, APPLE_TV, APPLE_WATCH, MAC, VISION")
                    ]),
                    "filter_state": .object([
                        "type": .string("string"),
                        "description": .string("Filter by state: DRAFT, PUBLISHED, or REPLACED")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Max results (default: 25, max: 200)")
                    ])
                ]),
                "required": .array([.string("app_id")])
            ])
        )
    }

    func getAccessibilityDeclarationTool() -> Tool {
        return Tool(
            name: "accessibility_get",
            description: "Get a specific accessibility declaration by ID, including its state and supported feature flags.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "declaration_id": .object([
                        "type": .string("string"),
                        "description": .string("Accessibility declaration ID")
                    ])
                ]),
                "required": .array([.string("declaration_id")])
            ])
        )
    }

    func createAccessibilityDeclarationTool() -> Tool {
        var properties: [String: Value] = [
            "app_id": .object([
                "type": .string("string"),
                "description": .string("App ID this declaration belongs to")
            ]),
            "device_family": .object([
                "type": .string("string"),
                "description": .string("Device family: IPHONE, IPAD, APPLE_TV, APPLE_WATCH, MAC, VISION")
            ])
        ]
        for (key, value) in supportFlagProperties { properties[key] = value }

        return Tool(
            name: "accessibility_create",
            description: "Create a DRAFT accessibility declaration for an app + device family, setting which accessibility features it supports. Publish it later with accessibility_update (publish=true).",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object(properties),
                "required": .array([.string("app_id"), .string("device_family")])
            ])
        )
    }

    func updateAccessibilityDeclarationTool() -> Tool {
        var properties: [String: Value] = [
            "declaration_id": .object([
                "type": .string("string"),
                "description": .string("Accessibility declaration ID")
            ]),
            "publish": .object([
                "type": .string("boolean"),
                "description": .string("Set true to publish the declaration to the App Store")
            ])
        ]
        for (key, value) in supportFlagProperties { properties[key] = value }

        return Tool(
            name: "accessibility_update",
            description: "Update a DRAFT accessibility declaration's feature flags, or publish it (publish=true). Only provided fields change.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object(properties),
                "required": .array([.string("declaration_id")])
            ])
        )
    }

    func deleteAccessibilityDeclarationTool() -> Tool {
        return Tool(
            name: "accessibility_delete",
            description: "Delete an accessibility declaration by ID.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "declaration_id": .object([
                        "type": .string("string"),
                        "description": .string("Accessibility declaration ID to delete")
                    ])
                ]),
                "required": .array([.string("declaration_id")])
            ])
        )
    }
}
