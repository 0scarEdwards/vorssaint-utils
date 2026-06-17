// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct ReleaseNotes {
    let version: String
    let date: String?
    let sections: [ReleaseNoteSection]

    static var current: ReleaseNotes {
        notes(for: AppInfo.version)
    }

    static func notes(for version: String, changelog: String? = bundledChangelog()) -> ReleaseNotes {
        guard let changelog,
              let parsed = parse(version: version, changelog: changelog) else {
            return ReleaseNotes(version: version, date: nil, sections: [])
        }
        return parsed
    }

    private static func bundledChangelog() -> String? {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func parse(version: String, changelog: String) -> ReleaseNotes? {
        let lines = changelog.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { header(in: $0)?.version == version }),
              let header = header(in: lines[start]) else { return nil }

        var sections: [ReleaseNoteSection] = []
        var currentTitle = ""
        var currentItems: [String] = []

        func flushSection() {
            guard !currentItems.isEmpty, shouldDisplaySection(currentTitle) else { return }
            sections.append(ReleaseNoteSection(title: currentTitle, items: currentItems))
            currentItems.removeAll()
        }

        for rawLine in lines.dropFirst(start + 1) {
            if rawLine.hasPrefix("## [") { break }
            if rawLine.hasPrefix("### ") {
                flushSection()
                currentTitle = String(rawLine.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                continue
            }

            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") {
                currentItems.append(clean(String(trimmed.dropFirst(2))))
            } else if rawLine.hasPrefix("  "), !currentItems.isEmpty, !trimmed.isEmpty {
                currentItems[currentItems.count - 1] += " " + clean(trimmed)
            }
        }
        flushSection()

        return ReleaseNotes(version: header.version, date: header.date, sections: sections)
    }

    private static func header(in line: String) -> (version: String, date: String?)? {
        guard line.hasPrefix("## [") else { return nil }
        let versionStart = line.index(line.startIndex, offsetBy: 4)
        guard let close = line[versionStart...].firstIndex(of: "]") else { return nil }
        let version = String(line[versionStart..<close])
        let suffixStart = line.index(after: close)
        let suffix = line[suffixStart...]
        let date = suffix.range(of: " - ").map { range in
            String(suffix[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return (version, date)
    }

    private static func clean(_ text: String) -> String {
        var result = text
        while let labelStart = result.range(of: "["),
              let labelEnd = result[labelStart.upperBound...].range(of: "]"),
              let linkStart = result[labelEnd.upperBound...].range(of: "("),
              linkStart.lowerBound == labelEnd.upperBound,
              let linkEnd = result[linkStart.upperBound...].range(of: ")") {
            let label = String(result[labelStart.upperBound..<labelEnd.lowerBound])
            result.replaceSubrange(labelStart.lowerBound..<linkEnd.upperBound, with: label)
        }
        return result.replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private static func shouldDisplaySection(_ title: String) -> Bool {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized != "website" && normalized != "links"
    }
}

struct ReleaseNoteSection {
    let title: String
    let items: [String]
}
