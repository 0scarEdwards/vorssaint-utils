// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import CoreGraphics

/// One selectable entry in the switcher: a real user-facing window.
/// Multiple windows of the same app appear as independent entries, so the
/// switcher can move between them the way the system moves between apps.
struct SwitcherItem: Identifiable, Equatable {
    let id: String
    let title: String
    let appName: String
    let pid: pid_t
    /// The backing CGWindow: thumbnails and AX raising go through it.
    let windowID: CGWindowID
    let isOnScreen: Bool
    let frame: CGRect

    /// The window whose thumbnail represents this entry (every entry has one).
    var previewWindowID: CGWindowID? { windowID }

    /// Label shown under the thumbnail; untitled windows fall back to the app name.
    var displayTitle: String {
        title.isEmpty ? appName : title
    }

    var appIcon: NSImage? {
        NSRunningApplication(processIdentifier: pid)?.icon
    }

    static func window(id: CGWindowID, title: String, appName: String, pid: pid_t,
                       isOnScreen: Bool, frame: CGRect) -> SwitcherItem {
        SwitcherItem(id: "w:\(id)", title: title, appName: appName,
                     pid: pid, windowID: id, isOnScreen: isOnScreen, frame: frame)
    }
}
