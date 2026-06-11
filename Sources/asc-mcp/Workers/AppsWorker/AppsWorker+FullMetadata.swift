import Foundation
import MCP

// MARK: - Full Metadata (bulk ASO read)
extension AppsWorker {

    func getFullMetadataTool() -> Tool {
        Tool(
            name: "apps_get_full_metadata",
            description: "Get title, subtitle and keywords for ALL localizations of the latest app version in one call. Auto-selects newest version (PREPARE_FOR_SUBMISSION preferred, then READY_FOR_SALE). Use this instead of calling apps_get_metadata once per locale.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "app_id": .object(["type": .string("string"), "description": .string("App Store Connect app ID")]),
                    "locale": .object(["type": .string("string"), "description": .string("Optional: restrict to a single locale (e.g. en-US)")]),
                    "version_id": .object(["type": .string("string"), "description": .string("Optional: specific appStoreVersion ID; otherwise the newest version is auto-selected")])
                ]),
                "required": .array([.string("app_id")])
            ])
        )
    }

    /// Returns title/subtitle/keywords for every localization of the latest version.
    public func getFullMetadata(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let appId = arguments["app_id"]?.stringValue else {
            return MCPResult.error("Required parameter 'app_id' is missing")
        }

        let localeFilter = arguments["locale"]?.stringValue
        let versionIdParam = arguments["version_id"]?.stringValue

        do {
            // Step 1: Resolve version
            let versionId: String
            let versionString: String
            let versionState: String

            if let vid = versionIdParam {
                let vr: ASCAppStoreVersionResponse = try await httpClient.get(
                    "/v1/appStoreVersions/\(vid)",
                    parameters: ["fields[appStoreVersions]": "versionString,appStoreState"],
                    as: ASCAppStoreVersionResponse.self
                )
                versionId = vr.data.id
                versionString = vr.data.version
                versionState = vr.data.state
            } else {
                let vr: ASCAppStoreVersionsResponse = try await httpClient.get(
                    "/v1/apps/\(appId)/appStoreVersions",
                    parameters: ["fields[appStoreVersions]": "versionString,appStoreState,createdDate,platform", "limit": "10"],
                    as: ASCAppStoreVersionsResponse.self
                )
                guard !vr.data.isEmpty else {
                    return MCPResult.error("No versions found for app \(appId)")
                }
                let platformPriority = ["IOS", "MAC_OS", "TV_OS", "WATCH_OS", "VISION_OS"]
                func preferPlatform(_ list: [ASCAppStoreVersion]) -> ASCAppStoreVersion? {
                    for p in platformPriority where list.contains(where: { $0.attributes?.platform == p }) {
                        return list.first(where: { $0.attributes?.platform == p })
                    }
                    return list.first
                }
                let selected = preferPlatform(vr.data.filter { $0.attributes?.appStoreState == "PREPARE_FOR_SUBMISSION" })
                    ?? preferPlatform(vr.data.filter { $0.attributes?.appStoreState == "READY_FOR_SALE" })
                    ?? vr.data[0]
                versionId = selected.id
                versionString = selected.attributes?.versionString ?? "N/A"
                versionState = selected.attributes?.appStoreState ?? "UNKNOWN"
            }

            // Step 2: Fetch all version localizations (keywords)
            var locParams: [String: String] = [
                "fields[appStoreVersionLocalizations]": "locale,keywords",
                "limit": "200"
            ]
            if let lf = localeFilter { locParams["filter[locale]"] = lf }
            let locResp: ASCAppStoreVersionLocalizationsResponse = try await httpClient.get(
                "/v1/appStoreVersions/\(versionId)/appStoreVersionLocalizations",
                parameters: locParams,
                as: ASCAppStoreVersionLocalizationsResponse.self
            )

            // Step 3: Fetch appInfo localizations (title, subtitle)
            let appInfosResp: ASCAppInfosResponse = try await httpClient.get(
                "/v1/apps/\(appId)/appInfos",
                parameters: ["fields[appInfos]": "appStoreState"],
                as: ASCAppInfosResponse.self
            )
            let matchingAppInfo = appInfosResp.data.first(where: { $0.attributes?.appStoreState == versionState })
                ?? appInfosResp.data.first

            var titleByLocale: [String: (name: String, subtitle: String)] = [:]
            if let infoId = matchingAppInfo?.id {
                var infoLocParams: [String: String] = [
                    "fields[appInfoLocalizations]": "locale,name,subtitle",
                    "limit": "200"
                ]
                if let lf = localeFilter { infoLocParams["filter[locale]"] = lf }
                let infoLocResp: ASCAppInfoLocalizationsResponse = try await httpClient.get(
                    "/v1/appInfos/\(infoId)/appInfoLocalizations",
                    parameters: infoLocParams,
                    as: ASCAppInfoLocalizationsResponse.self
                )
                for loc in infoLocResp.data {
                    titleByLocale[loc.attributes?.locale ?? ""] = (
                        name: loc.attributes?.name ?? "",
                        subtitle: loc.attributes?.subtitle ?? ""
                    )
                }
            }

            // Step 4: Build response
            let localizations: [[String: Any]] = locResp.data.map { loc in
                let locale = loc.attributes?.locale ?? ""
                let keywords = loc.attributes?.keywords ?? ""
                let info = titleByLocale[locale]
                let name = info?.name ?? ""
                let subtitle = info?.subtitle ?? ""
                return [
                    "locale": locale,
                    "title": name,
                    "title_len": name.count,
                    "subtitle": subtitle,
                    "subtitle_len": subtitle.count,
                    "keywords": keywords,
                    "keywords_len": keywords.count
                ] as [String: Any]
            }

            return MCPResult.jsonObject([
                "success": true,
                "appId": appId,
                "version": versionString,
                "versionState": versionState,
                "versionId": versionId,
                "totalLocalizations": localizations.count,
                "localizations": localizations
            ])
        } catch {
            return MCPResult.error("Failed to get full metadata: \(error.localizedDescription)")
        }
    }
}
