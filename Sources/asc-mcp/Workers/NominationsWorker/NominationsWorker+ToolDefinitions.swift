import Foundation
import MCP

// MARK: - Tool Definitions
extension NominationsWorker {

    func listNominationsTool() -> Tool {
        return Tool(
            name: "nominations_list",
            description: "List App Store nominations (editorial featuring requests). Filter by type, state, or app. Each nomination pitches an app to Apple's editorial team for featuring.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "filter_type": .object([
                        "type": .string("string"),
                        "description": .string("Filter by nomination type: APP_LAUNCH, APP_ENHANCEMENTS, or NEW_CONTENT")
                    ]),
                    "filter_state": .object([
                        "type": .string("string"),
                        "description": .string("Filter by state: DRAFT, SUBMITTED, or ARCHIVED")
                    ]),
                    "app_id": .object([
                        "type": .string("string"),
                        "description": .string("Filter by related app ID")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Max results (default: 25, max: 200)")
                    ]),
                    "next_url": .object([
                        "type": .string("string"),
                        "description": .string("Pagination URL from previous response to fetch next page")
                    ])
                ]),
                "required": .array([])
            ])
        )
    }

    func getNominationTool() -> Tool {
        return Tool(
            name: "nominations_get",
            description: "Get a specific App Store nomination by ID, including its state, schedule, and related apps.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "nomination_id": .object([
                        "type": .string("string"),
                        "description": .string("Nomination ID")
                    ])
                ]),
                "required": .array([.string("nomination_id")])
            ])
        )
    }

    func createNominationTool() -> Tool {
        return Tool(
            name: "nominations_create",
            description: "Create an App Store nomination to pitch an app for editorial featuring. Set submitted=true to submit immediately, or false to save as DRAFT.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "name": .object([
                        "type": .string("string"),
                        "description": .string("Internal name for the nomination")
                    ]),
                    "nomination_type": .object([
                        "type": .string("string"),
                        "description": .string("Type: APP_LAUNCH (new app), APP_ENHANCEMENTS (significant update), or NEW_CONTENT")
                    ]),
                    "description": .object([
                        "type": .string("string"),
                        "description": .string("Pitch description for Apple's editorial team — what's new and why it should be featured")
                    ]),
                    "publish_start_date": .object([
                        "type": .string("string"),
                        "description": .string("Desired publish start date (ISO 8601, e.g. 2026-07-01T00:00:00Z)")
                    ]),
                    "related_app_ids": .object([
                        "type": .string("array"),
                        "items": .object(["type": .string("string")]),
                        "description": .string("App IDs this nomination relates to (at least one required)")
                    ]),
                    "submitted": .object([
                        "type": .string("boolean"),
                        "description": .string("true = submit now, false = save as draft (default false)")
                    ]),
                    "publish_end_date": .object([
                        "type": .string("string"),
                        "description": .string("Optional desired publish end date (ISO 8601)")
                    ]),
                    "device_families": .object([
                        "type": .string("array"),
                        "items": .object(["type": .string("string")]),
                        "description": .string("Optional device families: IPHONE, IPAD, APPLE_TV, APPLE_WATCH, MAC, APPLE_VISION_PRO")
                    ]),
                    "locales": .object([
                        "type": .string("array"),
                        "items": .object(["type": .string("string")]),
                        "description": .string("Optional locale codes the nomination targets (e.g. en-US)")
                    ]),
                    "supplemental_materials_uris": .object([
                        "type": .string("array"),
                        "items": .object(["type": .string("string")]),
                        "description": .string("Optional URLs to supplemental materials (videos, press kit)")
                    ]),
                    "has_in_app_events": .object([
                        "type": .string("boolean"),
                        "description": .string("Optional — nomination involves in-app events")
                    ]),
                    "launch_in_select_markets_first": .object([
                        "type": .string("boolean"),
                        "description": .string("Optional — staged market launch")
                    ]),
                    "notes": .object([
                        "type": .string("string"),
                        "description": .string("Optional additional notes for Apple")
                    ]),
                    "pre_order_enabled": .object([
                        "type": .string("boolean"),
                        "description": .string("Optional — app is available for pre-order")
                    ]),
                    "in_app_event_ids": .object([
                        "type": .string("array"),
                        "items": .object(["type": .string("string")]),
                        "description": .string("Optional related in-app event IDs")
                    ]),
                    "territory_ids": .object([
                        "type": .string("array"),
                        "items": .object(["type": .string("string")]),
                        "description": .string("Optional supported territory IDs (e.g. USA, GBR)")
                    ])
                ]),
                "required": .array([
                    .string("name"), .string("nomination_type"), .string("description"),
                    .string("publish_start_date"), .string("related_app_ids")
                ])
            ])
        )
    }

    func updateNominationTool() -> Tool {
        return Tool(
            name: "nominations_update",
            description: "Update a DRAFT App Store nomination, or submit it (submitted=true) / archive it (archived=true). Only provided fields change.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "nomination_id": .object([
                        "type": .string("string"),
                        "description": .string("Nomination ID")
                    ]),
                    "name": .object(["type": .string("string"), "description": .string("New internal name")]),
                    "nomination_type": .object(["type": .string("string"), "description": .string("New type: APP_LAUNCH, APP_ENHANCEMENTS, NEW_CONTENT")]),
                    "description": .object(["type": .string("string"), "description": .string("New pitch description")]),
                    "submitted": .object(["type": .string("boolean"), "description": .string("Set true to submit the nomination to Apple")]),
                    "archived": .object(["type": .string("boolean"), "description": .string("Set true to archive the nomination")]),
                    "publish_start_date": .object(["type": .string("string"), "description": .string("New publish start date (ISO 8601)")]),
                    "publish_end_date": .object(["type": .string("string"), "description": .string("New publish end date (ISO 8601)")]),
                    "device_families": .object(["type": .string("array"), "items": .object(["type": .string("string")]), "description": .string("New device families")]),
                    "locales": .object(["type": .string("array"), "items": .object(["type": .string("string")]), "description": .string("New locale codes")]),
                    "supplemental_materials_uris": .object(["type": .string("array"), "items": .object(["type": .string("string")]), "description": .string("New supplemental material URLs")]),
                    "has_in_app_events": .object(["type": .string("boolean"), "description": .string("Involves in-app events")]),
                    "launch_in_select_markets_first": .object(["type": .string("boolean"), "description": .string("Staged market launch")]),
                    "notes": .object(["type": .string("string"), "description": .string("New notes")]),
                    "pre_order_enabled": .object(["type": .string("boolean"), "description": .string("Pre-order enabled")])
                ]),
                "required": .array([.string("nomination_id")])
            ])
        )
    }

    func deleteNominationTool() -> Tool {
        return Tool(
            name: "nominations_delete",
            description: "Delete an App Store nomination by ID.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "nomination_id": .object([
                        "type": .string("string"),
                        "description": .string("Nomination ID to delete")
                    ])
                ]),
                "required": .array([.string("nomination_id")])
            ])
        )
    }
}
