// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

/// A live reading the user can pin next to the menu bar icon. Order here is the
/// order shown in the menu bar.
enum MenuBarMetric: CaseIterable {
    case cpu, gpu, memory, network, battery, power

    var defaultsKey: String {
        switch self {
        case .cpu: return DefaultsKey.menuBarCPU
        case .gpu: return DefaultsKey.menuBarGPU
        case .memory: return DefaultsKey.menuBarMemory
        case .network: return DefaultsKey.menuBarNetwork
        case .battery: return DefaultsKey.menuBarBattery
        case .power: return DefaultsKey.menuBarPower
        }
    }

    static func enabled(in defaults: UserDefaults) -> [MenuBarMetric] {
        allCases.filter { defaults.bool(forKey: $0.defaultsKey) }
    }

    static func anyEnabled(in defaults: UserDefaults) -> Bool {
        allCases.contains { defaults.bool(forKey: $0.defaultsKey) }
    }
}

/// How the Memory metric appears in the menu bar: a colored pressure dot, the
/// percentage of RAM in use, or both.
enum MemoryMenuBarStyle: String, CaseIterable {
    case dot, percent, both

    static var current: MemoryMenuBarStyle {
        let raw = UserDefaults.standard.string(forKey: DefaultsKey.menuBarMemoryStyle) ?? ""
        let style = Defaults.sanitizedMenuBarMemoryStyle(raw)
        return MemoryMenuBarStyle(rawValue: style) ?? .percent
    }

    var showsDot: Bool { self == .dot || self == .both }
    var showsPercent: Bool { self == .percent || self == .both }
}

enum MenuBarLabelStyle: String, CaseIterable {
    case compact, classic

    static var current: MenuBarLabelStyle {
        let raw = UserDefaults.standard.string(forKey: DefaultsKey.menuBarLabelStyle) ?? ""
        let style = Defaults.sanitizedMenuBarLabelStyle(raw)
        return MenuBarLabelStyle(rawValue: style) ?? .compact
    }
}

/// One drawable piece of the menu bar text: plain (adaptive) text, or the memory
/// pressure dot, which carries a green/yellow/red color.
enum MenuBarSegment {
    case text(String)
    case dot(MemoryPressure)
}

/// Builds the compact content shown next to the icon.
///
/// Output is a list of segments so two consumers stay in sync: the status item
/// turns them into a colored attributed string, and the onboarding preview into
/// SwiftUI views. Labels are intentionally abbreviated because the menu bar is
/// a scarce space, especially on notched MacBooks.
enum MenuBarRenderer {
    private static let stackedFontSize: CGFloat = 9.4
    private static let singleLineFontSize: CGFloat = 11.6
    private static let statusTextGapColumns = 1
    private static let countdownColumns = 7
    private static let glyphAndButtonChrome: CGFloat = 26

    private struct MetricItem {
        var metric: MenuBarMetric
        var segments: [MenuBarSegment]
        var width: Int
    }

    static func lines(for snapshot: SystemSnapshot,
                      metrics: [MenuBarMetric],
                      allowStacked: Bool = true) -> [[MenuBarSegment]] {
        let items = metricItems(for: snapshot, metrics: metrics)
        guard !items.isEmpty else { return [] }

        if allowStacked, shouldStack(items) {
            let top = items.filter { $0.metric == .cpu || $0.metric == .gpu || $0.metric == .memory }
            let bottom = items.filter { $0.metric == .network || $0.metric == .battery || $0.metric == .power }
            if !top.isEmpty, !bottom.isEmpty {
                return [joined(top), joined(bottom)]
            }
        }

        return [joined(items)]
    }

    static func segments(for snapshot: SystemSnapshot,
                         metrics: [MenuBarMetric],
                         allowStacked: Bool = true) -> [MenuBarSegment] {
        var segments: [MenuBarSegment] = []
        for (index, line) in lines(for: snapshot, metrics: metrics, allowStacked: allowStacked).enumerated() {
            if index > 0 { segments.append(.text("\n")) }
            segments.append(contentsOf: line)
        }
        return segments
    }

    static func usesStackedLayout(for snapshot: SystemSnapshot,
                                  metrics: [MenuBarMetric],
                                  allowStacked: Bool = true) -> Bool {
        lines(for: snapshot, metrics: metrics, allowStacked: allowStacked).count > 1
    }

    static func statusFont(stacked: Bool) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: statusFontSize(stacked: stacked),
                                    weight: stacked ? .semibold : .medium)
    }

    static func statusFontSize(stacked: Bool) -> CGFloat {
        stacked ? stackedFontSize : singleLineFontSize
    }

    static func statusLineHeight(stacked: Bool) -> CGFloat {
        stacked ? 10.2 : 14
    }

    static func reservedStatusItemLength(for metrics: [MenuBarMetric],
                                         includesCountdown: Bool,
                                         allowStacked: Bool = true) -> CGFloat {
        let stacked = !includesCountdown && estimatedUsesStackedLayout(for: metrics, allowStacked: allowStacked)
        let font = statusFont(stacked: stacked)
        let columns = reservedContentColumns(for: metrics,
                                             includesCountdown: includesCountdown,
                                             allowStacked: allowStacked)
        guard columns > 0 else { return NSStatusItem.variableLength }

        let charWidth = ("0" as NSString).size(withAttributes: [.font: font]).width
        return ceil(glyphAndButtonChrome + CGFloat(columns) * charWidth)
    }

    static func reservedContentColumns(for metrics: [MenuBarMetric],
                                       includesCountdown: Bool,
                                       allowStacked: Bool = true) -> Int {
        let columns = reservedColumns(for: metrics,
                                      includesCountdown: includesCountdown,
                                      allowStacked: allowStacked)
        return columns > 0 ? columns + statusTextGapColumns : 0
    }

    private static func metricItems(for snapshot: SystemSnapshot, metrics: [MenuBarMetric]) -> [MetricItem] {
        var items: [MetricItem] = []
        let labelStyle = MenuBarLabelStyle.current
        for metric in metrics {
            switch metric {
            case .cpu:
                if let usage = snapshot.cpuUsage {
                    let text = prefix(for: .cpu, style: labelStyle) + percent(usage, paddedTo: 2)
                    items.append(MetricItem(metric: metric, segments: [.text(text)], width: text.count))
                }
            case .gpu:
                if let usage = snapshot.gpuUsage {
                    let text = prefix(for: .gpu, style: labelStyle) + percent(usage, paddedTo: 2)
                    items.append(MetricItem(metric: metric, segments: [.text(text)], width: text.count))
                }
            case .memory:
                guard let used = snapshot.memoryUsed, let total = snapshot.memoryTotal, total > 0 else { break }
                let style = MemoryMenuBarStyle.current
                var segments: [MenuBarSegment] = []
                var width = 0
                if style.showsDot {
                    segments.append(.dot(snapshot.memoryPressure))
                    width += 1
                    if style.showsPercent {
                        segments.append(.text(" "))
                        width += 1
                    }
                }
                if style.showsPercent {
                    let text = prefix(for: .memory, style: labelStyle) + percent(Double(used) / Double(total), paddedTo: 2)
                    segments.append(.text(text))
                    width += text.count
                }
                if !segments.isEmpty {
                    items.append(MetricItem(metric: metric, segments: segments, width: width))
                }
            case .network:
                if let down = snapshot.netDownBytesPerSec, let up = snapshot.netUpBytesPerSec {
                    let text = "↓ " + rjust(MetricFormat.bytesPerSecCompact(down), 4)
                        + " ↑ " + rjust(MetricFormat.bytesPerSecCompact(up), 4)
                    items.append(MetricItem(metric: metric, segments: [.text(text)], width: text.count))
                }
            case .battery:
                if let charge = snapshot.power?.chargePercent {
                    let text = prefix(for: .battery,
                                      style: labelStyle,
                                      isCharging: snapshot.power?.isCharging ?? false)
                        + percent(Double(charge) / 100.0, paddedTo: 3)
                    items.append(MetricItem(metric: metric, segments: [.text(text)], width: text.count))
                }
            case .power:
                if let watts = snapshot.power?.systemWatts {
                    let text = prefix(for: .power, style: labelStyle) + MetricFormat.wattsCompact(watts)
                    items.append(MetricItem(metric: metric, segments: [.text(text)], width: text.count))
                }
            }
        }
        return items
    }

    private static func estimatedUsesStackedLayout(for metrics: [MenuBarMetric], allowStacked: Bool) -> Bool {
        allowStacked && shouldStack(estimatedMetricItems(for: metrics))
    }

    private static func reservedColumns(for metrics: [MenuBarMetric],
                                        includesCountdown: Bool,
                                        allowStacked: Bool) -> Int {
        let items = estimatedMetricItems(for: metrics)
        guard !items.isEmpty else { return includesCountdown ? countdownColumns : 0 }

        if includesCountdown {
            return countdownColumns + 2 + joinedWidth(items)
        }

        if allowStacked, shouldStack(items) {
            let top = items.filter { $0.metric == .cpu || $0.metric == .gpu || $0.metric == .memory }
            let bottom = items.filter { $0.metric == .network || $0.metric == .battery || $0.metric == .power }
            if !top.isEmpty, !bottom.isEmpty {
                return max(joinedWidth(top), joinedWidth(bottom))
            }
        }

        return joinedWidth(items)
    }

    private static func estimatedMetricItems(for metrics: [MenuBarMetric]) -> [MetricItem] {
        metrics.map {
            MetricItem(metric: $0, segments: [], width: reservedWidth(for: $0))
        }
    }

    private static func reservedWidth(for metric: MenuBarMetric) -> Int {
        let labelStyle = MenuBarLabelStyle.current
        switch metric {
        case .cpu, .gpu:
            return prefix(for: metric, style: labelStyle).count + 3
        case .memory:
            let style = MemoryMenuBarStyle.current
            switch style {
            case .dot: return 1
            case .percent: return prefix(for: .memory, style: labelStyle).count + 3
            case .both: return 2 + prefix(for: .memory, style: labelStyle).count + 3
            }
        case .network:
            return 13      // ↓ 1.0G ↑ 1.0G
        case .battery:
            return prefix(for: .battery, style: labelStyle, isCharging: true).count + 4
        case .power:
            return prefix(for: .power, style: labelStyle).count + 3
        }
    }

    private static func prefix(for metric: MenuBarMetric,
                               style: MenuBarLabelStyle,
                               isCharging: Bool = false) -> String {
        switch (style, metric) {
        case (.compact, .cpu): return "C "
        case (.compact, .gpu): return "G "
        case (.compact, .memory): return "M "
        case (.compact, .battery): return isCharging ? "B+ " : "B "
        case (.compact, .power): return "P "
        case (.compact, .network): return ""
        case (.classic, .cpu): return "CPU "
        case (.classic, .gpu): return "GPU "
        case (.classic, .memory): return "MEM "
        case (.classic, .battery): return isCharging ? "BAT+ " : "BAT "
        case (.classic, .power): return "POW "
        case (.classic, .network): return ""
        }
    }

    private static func shouldStack(_ items: [MetricItem]) -> Bool {
        items.count >= 3 && joinedWidth(items) > 21
    }

    private static func joinedWidth(_ items: [MetricItem]) -> Int {
        let separators = max(0, items.count - 1)
        return items.reduce(0) { $0 + $1.width } + separators
    }

    private static func joined(_ items: [MetricItem]) -> [MenuBarSegment] {
        var segments: [MenuBarSegment] = []
        for item in items {
            if !segments.isEmpty { segments.append(.text(" ")) }
            segments.append(contentsOf: item.segments)
        }
        return segments
    }

    /// The colored attributed string for the status item. Only the memory dot
    /// gets an explicit color; everything else stays adaptive (the caller applies
    /// the font over the whole run, which does not disturb the dot's color).
    static func attributed(for snapshot: SystemSnapshot,
                           metrics: [MenuBarMetric],
                           allowStacked: Bool = true,
                           linePrefix: String = "") -> NSAttributedString {
        let result = NSMutableAttributedString()
        for segment in segments(for: snapshot, metrics: metrics, allowStacked: allowStacked) {
            switch segment {
            case let .text(string):
                let rendered = string == "\n" && !linePrefix.isEmpty ? "\n" + linePrefix : string
                result.append(NSAttributedString(string: rendered))
            case let .dot(pressure):
                result.append(NSAttributedString(string: "●", attributes: [.foregroundColor: nsColor(for: pressure)]))
            }
        }
        return result
    }

    static func nsColor(for pressure: MemoryPressure) -> NSColor {
        switch pressure {
        case .normal: return .systemGreen
        case .warning: return .systemYellow
        case .critical: return .systemRed
        case .unknown: return .secondaryLabelColor
        }
    }

    /// A compact 0...1 fraction: "5%", "47%", "100%".
    private static func percent(_ fraction: Double, paddedTo width: Int = 0) -> String {
        let value = Int((max(0, min(1, fraction)) * 100).rounded())
        return rjust("\(value)", width) + "%"
    }

    private static func rjust(_ string: String, _ width: Int) -> String {
        string.count >= width ? string : String(repeating: " ", count: width - string.count) + string
    }
}
