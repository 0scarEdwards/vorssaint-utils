// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// A faithful, live miniature of the menu bar corner. It uses the same compact
/// lines the real status item renders, so choices in Settings have an immediate
/// visual cost before they occupy the actual menu bar.
struct MenuBarMetricsPreview: View {
    @ObservedObject private var monitor = SystemMonitor.shared
    @AppStorage(DefaultsKey.menuBarCPU) private var cpu = false
    @AppStorage(DefaultsKey.menuBarGPU) private var gpu = false
    @AppStorage(DefaultsKey.menuBarMemory) private var memory = false
    @AppStorage(DefaultsKey.menuBarNetwork) private var network = false
    @AppStorage(DefaultsKey.menuBarBattery) private var battery = false
    @AppStorage(DefaultsKey.menuBarPower) private var power = false
    @AppStorage(DefaultsKey.menuBarLabelStyle) private var labelStyle = "compact"
    @AppStorage(DefaultsKey.menuBarMemoryStyle) private var memoryStyle = "percent"

    var body: some View {
        let _ = labelStyle
        let _ = memoryStyle
        let lines = MenuBarRenderer.lines(for: monitor.snapshot, metrics: activeMetrics)
        let stacked = lines.count > 1

        HStack(spacing: 12) {
            Spacer()
            Image(systemName: "wifi")
                .foregroundStyle(.white.opacity(0.5))
            Image(systemName: "battery.75")
                .foregroundStyle(.white.opacity(0.5))
            HStack(spacing: 5) {
                glyph
                    .frame(width: 20, height: 14)
                if !lines.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                            HStack(spacing: 0) {
                                ForEach(Array(line.enumerated()), id: \.offset) { _, segment in
                                    segmentView(segment, stacked: stacked)
                                }
                            }
                            .frame(height: MenuBarRenderer.statusLineHeight(stacked: stacked))
                        }
                    }
                }
            }
        }
        .font(.system(size: 12))
        .padding(.horizontal, 14)
        .frame(height: 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.82))
        )
    }

    private var activeMetrics: [MenuBarMetric] {
        var metrics: [MenuBarMetric] = []
        if cpu { metrics.append(.cpu) }
        if gpu { metrics.append(.gpu) }
        if memory { metrics.append(.memory) }
        if network { metrics.append(.network) }
        if battery { metrics.append(.battery) }
        if power { metrics.append(.power) }
        return metrics
    }

    @ViewBuilder
    private func segmentView(_ segment: MenuBarSegment, stacked: Bool) -> some View {
        switch segment {
        case let .text(string):
            Text(string)
                .font(.system(size: MenuBarRenderer.statusFontSize(stacked: stacked),
                              weight: stacked ? .semibold : .medium,
                              design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        case let .dot(pressure):
            Circle()
                .fill(dotColor(pressure))
                .frame(width: stacked ? 5.5 : 7.5, height: stacked ? 5.5 : 7.5)
        }
    }

    private func dotColor(_ pressure: MemoryPressure) -> Color {
        switch pressure {
        case .normal: return .green
        case .warning: return .yellow
        case .critical: return .red
        case .unknown: return .gray
        }
    }

    private var glyph: some View {
        Group {
            if let image = BlackHoleGlyph.image(active: true) {
                Image(nsImage: image).renderingMode(.template)
            } else {
                Image(systemName: "circle.fill")
            }
        }
        .foregroundStyle(.white)
    }
}
