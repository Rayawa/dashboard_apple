import Foundation

enum NaturalLanguageExtractor {
    static func extract(from text: String) -> ExtractedSeed {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ExtractedSeed() }

        let linkPattern = #"https://appgallery\.huawei\.com/app/detail\?id=([A-Za-z0-9._-]+)"#
        let appIdPattern = #"\b[Cc][\s:_-]?\d{10,25}\b"#
        let packagePattern = #"\b[a-zA-Z][a-zA-Z0-9_]*(?:\.[a-zA-Z0-9_]+){2,}\b"#
        let datePattern = #"\b20\d{2}[-/.年]\d{1,2}[-/.月]\d{1,2}(?:日)?\b"#

        let link = firstMatch(in: trimmed, pattern: linkPattern, group: 0)
        let packageFromLink = firstMatch(in: trimmed, pattern: linkPattern, group: 1)
        let packageFromText = firstMatch(in: trimmed, pattern: packagePattern, group: 0)
        let date = firstMatch(in: trimmed, pattern: datePattern, group: 0)?
            .replacingOccurrences(of: "年", with: "-")
            .replacingOccurrences(of: "月", with: "-")
            .replacingOccurrences(of: "日", with: "")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "-")

        let rawAppId = firstMatch(in: trimmed, pattern: appIdPattern, group: 0)?
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ":", with: "")
            .uppercased()

        let firstLine = trimmed
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty && !$0.contains("http") && !$0.contains("com.") })

        return ExtractedSeed(
            appName: firstLine,
            appLink: link,
            packageName: packageFromLink ?? packageFromText,
            appId: rawAppId,
            date: date
        )
    }

    private static func firstMatch(in text: String, pattern: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range), let matchRange = Range(match.range(at: group), in: text) else {
            return nil
        }
        return String(text[matchRange])
    }
}
