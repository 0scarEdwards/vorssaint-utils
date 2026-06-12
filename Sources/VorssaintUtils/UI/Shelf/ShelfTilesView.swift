import AppKit
import SwiftUI

/// A transparent strip that moves the whole panel when dragged — placed over the
/// shelf's header so its title area acts like a window title bar, while the
/// tiles below stay free to start item drags.
struct WindowMoveHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { MoveView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class MoveView: NSView {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

/// The shelf's item tiles, in AppKit so they can do what SwiftUI's `.onDrag`
/// can't: drag several selected items out at once, and remove them from the
/// shelf once the drop is accepted somewhere.
struct ShelfTilesView: NSViewRepresentable {
    var items: [ShelfService.Item]
    var selection: Set<UUID>

    static let tileSize = NSSize(width: 76, height: 86)
    static let spacing: CGFloat = 8

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = false
        scroll.horizontalScrollElasticity = .allowed
        scroll.verticalScrollElasticity = .none
        scroll.contentView.drawsBackground = false
        let document = FlippedView()
        scroll.documentView = document
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let document = scroll.documentView else { return }
        document.subviews.forEach { $0.removeFromSuperview() }

        let tile = Self.tileSize
        for (index, item) in items.enumerated() {
            let view = ShelfTileView(item: item, isSelected: selection.contains(item.id))
            view.frame = NSRect(x: CGFloat(index) * (tile.width + Self.spacing) + 2,
                                y: 2, width: tile.width, height: tile.height)
            document.addSubview(view)
        }
        let width = max(CGFloat(items.count) * (tile.width + Self.spacing) + 4, scroll.contentSize.width)
        document.frame = NSRect(x: 0, y: 0, width: width, height: tile.height + 4)
    }

    private final class FlippedView: NSView {
        override var isFlipped: Bool { true }
    }
}

/// One tile. Click toggles selection; dragging starts a drag of the whole
/// selection (or just this tile if it isn't selected); a successful drop
/// removes the dragged tiles from the shelf.
final class ShelfTileView: NSView, NSDraggingSource {
    private let item: ShelfService.Item
    private let isSelected: Bool
    private var mouseDownPoint: NSPoint = .zero
    private var didDrag = false
    private var draggedIDs: [UUID] = []
    private var closeButton: NSButton!

    init(item: ShelfService.Item, isSelected: Bool) {
        self.item = item
        self.isSelected = isSelected
        super.init(frame: NSRect(origin: .zero, size: ShelfTilesView.tileSize))
        wantsLayer = true
        layer?.cornerRadius = 11
        if isSelected {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.16).cgColor
            layer?.borderWidth = 2
            layer?.borderColor = NSColor.controlAccentColor.cgColor
        }
        buildSubviews()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }

    private func buildSubviews() {
        let iconWell = NSView(frame: NSRect(x: 6, y: 5, width: 64, height: 50))
        iconWell.wantsLayer = true
        iconWell.layer?.cornerRadius = 8
        iconWell.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
        addSubview(iconWell)

        let imageView = NSImageView(frame: iconWell.bounds.insetBy(dx: item.isImage ? 4 : 13,
                                                                   dy: item.isImage ? 4 : 8))
        imageView.image = item.icon
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        iconWell.addSubview(imageView)

        let label = NSTextField(labelWithString: item.title)
        label.frame = NSRect(x: 2, y: 58, width: 72, height: 24)
        label.font = .systemFont(ofSize: 10)
        label.alignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        label.maximumNumberOfLines = 2
        label.textColor = .secondaryLabelColor
        addSubview(label)

        if isSelected {
            let badge = NSImageView(frame: NSRect(x: 4, y: 4, width: 16, height: 16))
            badge.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
            badge.contentTintColor = .controlAccentColor
            addSubview(badge)
        }

        closeButton = NSButton(frame: NSRect(x: 56, y: 3, width: 17, height: 17))
        closeButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
        closeButton.isBordered = false
        closeButton.bezelStyle = .regularSquare
        closeButton.imagePosition = .imageOnly
        closeButton.contentTintColor = .secondaryLabelColor
        closeButton.target = self
        closeButton.action = #selector(removeSelf)
        closeButton.isHidden = true
        addSubview(closeButton)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways],
                                       owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { closeButton.isHidden = false }
    override func mouseExited(with event: NSEvent) { closeButton.isHidden = true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        mouseDownPoint = event.locationInWindow
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !didDrag else { return }
        let point = event.locationInWindow
        if hypot(point.x - mouseDownPoint.x, point.y - mouseDownPoint.y) > 4 {
            didDrag = true
            beginItemDrag(with: event)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if !didDrag { ShelfService.shared.toggleSelection(item.id) }
    }

    @objc private func removeSelf() {
        ShelfService.shared.removeItem(item.id)
    }

    private func beginItemDrag(with event: NSEvent) {
        let shelf = ShelfService.shared
        let dragged = shelf.selection.contains(item.id) ? shelf.selectedItems() : [item]
        draggedIDs = dragged.map(\.id)

        let draggingItems: [NSDraggingItem] = dragged.map { entry in
            let draggingItem = NSDraggingItem(pasteboardWriter: shelf.pasteboardWriter(for: entry))
            // Overlapping frames make AppKit stack them with a count badge.
            draggingItem.setDraggingFrame(bounds, contents: entry.icon)
            return draggingItem
        }
        beginDraggingSession(with: draggingItems, event: event, source: self)
    }

    // MARK: NSDraggingSource

    func draggingSession(_ session: NSDraggingSession,
                         sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // A non-empty operation means the drop was accepted somewhere — pull the
        // dragged tiles out of the shelf. A cancelled drag leaves them.
        guard operation != [] else { return }
        let ids = draggedIDs
        DispatchQueue.main.async { ShelfService.shared.removeItems(ids) }
    }
}
