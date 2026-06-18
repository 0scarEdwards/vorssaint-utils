// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import ApplicationServices
import Combine
import CoreGraphics

/// Makes the green traffic-light button maximize in the current Space instead
/// of entering macOS fullscreen. The event tap is installed only while the user
/// has opted in and Accessibility is granted.
final class WindowMaximizer: ObservableObject {
    static let shared = WindowMaximizer()

    @Published private(set) var isRunning = false

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var pendingClick: ClickTarget?
    private var originalFrames: [CGWindowID: AXFrame] = [:]

    private let clickTolerance: CGFloat = 8
    private let frameTolerance: CGFloat = 4

    private init() {}

    func syncWithPreferences() {
        let wanted = UserDefaults.standard.bool(forKey: DefaultsKey.windowMaximizeEnabled)
        if wanted, Permissions.shared.accessibility {
            start()
        } else {
            stop()
        }
    }

    func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
        pendingClick = nil
        originalFrames.removeAll()
        isRunning = false
    }

    private func start() {
        guard tap == nil else {
            isRunning = true
            return
        }

        let mask = CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
            | CGEventMask(1 << CGEventType.leftMouseUp.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let service = Unmanaged<WindowMaximizer>.fromOpaque(userInfo).takeUnretainedValue()
                return service.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            isRunning = false
            return
        }

        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .leftMouseDown:
            guard event.flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift]).isEmpty,
                  let target = target(at: event.location)
            else {
                pendingClick = nil
                return Unmanaged.passUnretained(event)
            }
            pendingClick = target
            return nil

        case .leftMouseUp:
            guard let target = pendingClick else { return Unmanaged.passUnretained(event) }
            pendingClick = nil
            if target.acceptsMouseUp(at: event.location, tolerance: clickTolerance) {
                if let fresh = self.target(at: event.location),
                   fresh.windowID == target.windowID {
                    if !toggle(fresh) {
                        pressNativeButton(fresh.button)
                    }
                } else {
                    pressNativeButton(target.button)
                }
            }
            return nil

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func target(at point: CGPoint) -> ClickTarget? {
        guard let element = elementAt(point: point),
              let window = topLevelWindow(from: element),
              role(of: window) == (kAXWindowRole as String),
              !boolAttribute(window, "AXFullScreen"),
              let buttonFrame = greenButtonFrame(in: window, containing: point),
              let windowID = AXWindowResolver.windowID(for: window),
              let frame = frame(of: window)
        else { return nil }

        return ClickTarget(window: window,
                           button: buttonFrame.button,
                           windowID: windowID,
                           frame: frame,
                           buttonFrame: buttonFrame.frame)
    }

    @discardableResult
    private func toggle(_ target: ClickTarget) -> Bool {
        guard let current = frame(of: target.window),
              let screen = bestScreen(for: current)
        else { return false }

        let maximized = axFrame(fromAppKit: screen.visibleFrame)
        if current.isClose(to: maximized, tolerance: frameTolerance),
           let original = originalFrames[target.windowID],
           original.size.width > 80,
           original.size.height > 80 {
            if setFrame(original, on: target.window) {
                originalFrames.removeValue(forKey: target.windowID)
                return true
            }
            return false
        } else {
            originalFrames[target.windowID] = current
            if setFrame(maximized, on: target.window) {
                return true
            }
            originalFrames.removeValue(forKey: target.windowID)
            return false
        }
    }

    private func elementAt(point: CGPoint) -> AXUIElement? {
        let system = AXUIElementCreateSystemWide()
        var element: AXUIElement?
        guard AXUIElementCopyElementAtPosition(system, Float(point.x), Float(point.y), &element) == .success
        else { return nil }
        return element
    }

    private func topLevelWindow(from element: AXUIElement) -> AXUIElement? {
        if role(of: element) == (kAXWindowRole as String) { return element }

        if let window = elementAttribute(element, kAXWindowAttribute as String),
           role(of: window) == (kAXWindowRole as String) {
            return window
        }
        if let window = elementAttribute(element, kAXTopLevelUIElementAttribute as String),
           role(of: window) == (kAXWindowRole as String) {
            return window
        }

        var current = element
        for _ in 0..<8 {
            guard let parent = elementAttribute(current, kAXParentAttribute as String) else { return nil }
            if role(of: parent) == (kAXWindowRole as String) { return parent }
            current = parent
        }
        return nil
    }

    private func greenButtonFrame(in window: AXUIElement, containing point: CGPoint) -> ButtonFrame? {
        for attribute in [kAXFullScreenButtonAttribute as String, kAXZoomButtonAttribute as String] {
            guard let button = elementAttribute(window, attribute),
                  boolAttribute(button, kAXEnabledAttribute as String, default: true),
                  let frame = frame(of: button),
                  frame.insetBy(dx: -3, dy: -3).contains(point)
            else { continue }
            return ButtonFrame(button: button, frame: frame)
        }
        return nil
    }

    private func setFrame(_ frame: AXFrame, on window: AXUIElement) -> Bool {
        let original = self.frame(of: window)

        for _ in 0..<2 {
            let positioned = setPosition(frame.origin, on: window)
            let sized = setSize(frame.size, on: window)
            let repositioned = positioned && setPosition(frame.origin, on: window)
            guard positioned && sized && repositioned else {
                restoreFrame(original, on: window)
                return false
            }
            if let actual = self.frame(of: window),
               actual.isClose(to: frame, tolerance: frameTolerance) {
                return true
            }
        }

        restoreFrame(original, on: window)
        return false
    }

    private func restoreFrame(_ frame: AXFrame?, on window: AXUIElement) {
        guard let frame else { return }
        _ = setPosition(frame.origin, on: window)
        _ = setSize(frame.size, on: window)
        _ = setPosition(frame.origin, on: window)
    }

    private func pressNativeButton(_ button: AXUIElement) {
        AXUIElementPerformAction(button, kAXPressAction as CFString)
    }

    private func setPosition(_ point: CGPoint, on element: AXUIElement) -> Bool {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return false }
        return AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value) == .success
    }

    private func setSize(_ size: CGSize, on element: AXUIElement) -> Bool {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return false }
        return AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value) == .success
    }

    private func frame(of element: AXUIElement) -> AXFrame? {
        guard let origin = pointAttribute(element, kAXPositionAttribute as String),
              let size = sizeAttribute(element, kAXSizeAttribute as String),
              size.width > 0,
              size.height > 0
        else { return nil }
        return AXFrame(origin: origin, size: size)
    }

    private func pointAttribute(_ element: AXUIElement, _ attribute: String) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID()
        else { return nil }
        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgPoint else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else { return nil }
        return point
    }

    private func sizeAttribute(_ element: AXUIElement, _ attribute: String) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID()
        else { return nil }
        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgSize else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else { return nil }
        return size
    }

    private func elementAttribute(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (value as! AXUIElement)
    }

    private func role(of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value) == .success
        else { return nil }
        return value as? String
    }

    private func boolAttribute(_ element: AXUIElement, _ attribute: String, default defaultValue: Bool = false) -> Bool {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value
        else { return defaultValue }
        return (value as? Bool) ?? defaultValue
    }

    private func bestScreen(for frame: AXFrame) -> NSScreen? {
        let appKitFrame = appKitFrame(fromAX: frame)
        return NSScreen.screens.max { lhs, rhs in
            lhs.frame.intersection(appKitFrame).area < rhs.frame.intersection(appKitFrame).area
        } ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func axFrame(fromAppKit rect: NSRect) -> AXFrame {
        AXFrame(origin: CGPoint(x: rect.minX, y: menuBarScreenTopY - rect.maxY),
                size: rect.size)
    }

    private func appKitFrame(fromAX frame: AXFrame) -> NSRect {
        NSRect(x: frame.origin.x,
               y: menuBarScreenTopY - frame.origin.y - frame.size.height,
               width: frame.size.width,
               height: frame.size.height)
    }

    private var menuBarScreenTopY: CGFloat {
        let menuBarScreen = NSScreen.screens.first {
            abs($0.frame.minX) < 0.5 && abs($0.frame.minY) < 0.5
        }
        return (menuBarScreen ?? NSScreen.main ?? NSScreen.screens.first)?.frame.maxY ?? 0
    }
}

private struct ClickTarget {
    let window: AXUIElement
    let button: AXUIElement
    let windowID: CGWindowID
    let frame: AXFrame
    let buttonFrame: AXFrame

    func acceptsMouseUp(at point: CGPoint, tolerance: CGFloat) -> Bool {
        buttonFrame.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
    }
}

private struct ButtonFrame {
    let button: AXUIElement
    let frame: AXFrame
}

private struct AXFrame: Equatable {
    var origin: CGPoint
    var size: CGSize

    var minX: CGFloat { origin.x }
    var minY: CGFloat { origin.y }
    var maxX: CGFloat { origin.x + size.width }
    var maxY: CGFloat { origin.y + size.height }

    func contains(_ point: CGPoint) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }

    func insetBy(dx: CGFloat, dy: CGFloat) -> AXFrame {
        AXFrame(origin: CGPoint(x: origin.x + dx, y: origin.y + dy),
                size: CGSize(width: size.width - dx * 2, height: size.height - dy * 2))
    }

    func isClose(to other: AXFrame, tolerance: CGFloat) -> Bool {
        abs(origin.x - other.origin.x) <= tolerance
            && abs(origin.y - other.origin.y) <= tolerance
            && abs(size.width - other.size.width) <= tolerance
            && abs(size.height - other.size.height) <= tolerance
    }
}

private extension NSRect {
    var area: CGFloat {
        guard !isNull, !isEmpty else { return 0 }
        return width * height
    }
}
