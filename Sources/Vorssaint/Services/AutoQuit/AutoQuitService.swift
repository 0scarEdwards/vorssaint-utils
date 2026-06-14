import AppKit
import ApplicationServices
import Combine

/// Quits an app when its last window closes — the behavior many people expect
/// coming from Windows. Each regular app gets an Accessibility observer that
/// watches windows being created and destroyed; when an app that had at least
/// one window drops to zero standard windows, it's asked to quit (a normal
/// terminate, so unsaved-changes dialogs still appear).
///
/// Predictable by design: apps that launch window-less are never touched, and
/// any app can be kept running through the exception list. Requires
/// Accessibility.
final class AutoQuitService: ObservableObject {
    static let shared = AutoQuitService()

    /// Bundle ids never auto-quit; mirrors the persisted list for the UI.
    @Published private(set) var exceptions: [String] = []

    private var running = false
    private var observers: [pid_t: AXObserver] = [:]
    /// Apps that have shown at least one window since we started watching them.
    /// Only these are eligible to quit, so window-less agents stay put.
    private var hadWindows: [pid_t: Bool] = [:]
    private var launchToken: NSObjectProtocol?
    private var terminateToken: NSObjectProtocol?

    private init() {
        reloadExceptions()
    }

    var isRunning: Bool { running }

    // MARK: - Lifecycle

    func syncWithPreferences() {
        let enabled = UserDefaults.standard.bool(forKey: DefaultsKey.autoQuitEnabled)
        if enabled, Permissions.shared.accessibility {
            start()
        } else {
            stop()
        }
    }

    private func start() {
        guard !running else { return }
        running = true

        let center = NSWorkspace.shared.notificationCenter
        launchToken = center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification,
                                         object: nil, queue: .main) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.attach(app)
        }
        terminateToken = center.addObserver(forName: NSWorkspace.didTerminateApplicationNotification,
                                            object: nil, queue: .main) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.detach(pid: app.processIdentifier)
        }

        for app in NSWorkspace.shared.runningApplications {
            attach(app)
        }
    }

    private func stop() {
        guard running else { return }
        running = false
        let center = NSWorkspace.shared.notificationCenter
        if let launchToken { center.removeObserver(launchToken) }
        if let terminateToken { center.removeObserver(terminateToken) }
        launchToken = nil
        terminateToken = nil
        // Snapshot the keys — detach(pid:) mutates the dictionary.
        for pid in Array(observers.keys) { detach(pid: pid) }
        observers.removeAll()
        hadWindows.removeAll()
    }

    // MARK: - Per-app observers

    private func attach(_ app: NSRunningApplication) {
        guard running, app.activationPolicy == .regular else { return }
        let pid = app.processIdentifier
        guard pid != getpid(), observers[pid] == nil else { return }

        var observerRef: AXObserver?
        guard AXObserverCreate(pid, autoQuitAXCallback, &observerRef) == .success,
              let observer = observerRef else { return }

        let appElement = AXUIElementCreateApplication(pid)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        AXObserverAddNotification(observer, appElement, kAXWindowCreatedNotification as CFString, refcon)
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        observers[pid] = observer

        // Watch the windows that already exist and seed the "had windows" flag.
        let existing = standardWindows(of: appElement)
        for window in existing {
            AXObserverAddNotification(observer, window, kAXUIElementDestroyedNotification as CFString, refcon)
        }
        if !existing.isEmpty { hadWindows[pid] = true }
    }

    private func detach(pid: pid_t) {
        if let observer = observers[pid] {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        }
        observers[pid] = nil
        hadWindows[pid] = nil
    }

    /// Called from the C observer callback (on the main run loop).
    func handleAX(element: AXUIElement, notification: String) {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        guard pid != 0 else { return }

        if notification == (kAXWindowCreatedNotification as String) {
            // `element` is the new window: watch it close, and remember the app
            // has had a window.
            if let observer = observers[pid] {
                AXObserverAddNotification(observer, element, kAXUIElementDestroyedNotification as CFString,
                                          Unmanaged.passUnretained(self).toOpaque())
            }
            hadWindows[pid] = true
        } else if notification == (kAXUIElementDestroyedNotification as String) {
            // A watched window closed. Recount slightly later — the closing
            // window can still linger in the window list for a moment.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.checkWindows(pid: pid)
            }
        }
    }

    private func checkWindows(pid: pid_t, confirm: Bool = true) {
        guard running, hadWindows[pid] == true,
              let app = NSRunningApplication(processIdentifier: pid), !app.isTerminated else { return }
        if let bundleID = app.bundleIdentifier, exceptions.contains(bundleID) { return }

        let appElement = AXUIElementCreateApplication(pid)
        guard standardWindows(of: appElement).isEmpty else { return }

        // Zero windows can be a transient state, most notably when leaving full
        // screen with the green button: the full-screen window is destroyed a
        // moment before the windowed one reappears. Quitting on that flicker
        // would close the app as if the user pressed Cmd-Q. So re-check once the
        // transition has settled, and only quit if the app is still window-less.
        if confirm {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.checkWindows(pid: pid, confirm: false)
            }
            return
        }

        hadWindows[pid] = false
        app.terminate()
    }

    private func standardWindows(of appElement: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value) == .success,
              let windows = value as? [AXUIElement] else { return [] }
        return windows.filter(Self.isStandardWindow)
    }

    /// A real, user-facing window — not a sheet, palette or system dialog, which
    /// shouldn't keep an app "alive" for this purpose.
    private static func isStandardWindow(_ window: AXUIElement) -> Bool {
        var subrole: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subrole) == .success,
           let value = subrole as? String {
            return value == "AXStandardWindow"
        }
        var role: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &role) == .success,
           let value = role as? String {
            return value == "AXWindow"
        }
        return false
    }

    // MARK: - Exceptions

    func reloadExceptions() {
        exceptions = UserDefaults.standard.stringArray(forKey: DefaultsKey.autoQuitExceptions) ?? []
    }

    func addException(_ bundleID: String) {
        guard !exceptions.contains(bundleID) else { return }
        var list = exceptions
        list.append(bundleID)
        UserDefaults.standard.set(list, forKey: DefaultsKey.autoQuitExceptions)
        reloadExceptions()
    }

    func removeException(_ bundleID: String) {
        let list = exceptions.filter { $0 != bundleID }
        UserDefaults.standard.set(list, forKey: DefaultsKey.autoQuitExceptions)
        reloadExceptions()
    }
}

/// C trampoline for AXObserver — no captures, so it bridges to a C function
/// pointer; the service is recovered from the refcon.
private func autoQuitAXCallback(_ observer: AXObserver,
                                _ element: AXUIElement,
                                _ notification: CFString,
                                _ refcon: UnsafeMutableRawPointer?) {
    guard let refcon else { return }
    let service = Unmanaged<AutoQuitService>.fromOpaque(refcon).takeUnretainedValue()
    service.handleAX(element: element, notification: notification as String)
}
