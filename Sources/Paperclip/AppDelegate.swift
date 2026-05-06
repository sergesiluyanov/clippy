import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var clippyWindow: NSWindow!
    private var tasksWindow: NSWindow?
    private var statusItem: NSStatusItem!

    private let store = TaskStore()

    private var nudgeTimer: Timer?
    private var quipClearTimer: Timer?
    private var paused = false

    /// How often Clippy nags by default (seconds).
    private let nudgeIntervalSeconds: TimeInterval = 8 * 60

    /// Bridges to SwiftUI: current line in the speech bubble and current mood.
    private let viewModel = ClippyViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildClippyWindow()
        buildStatusItem()
        scheduleNudges()

        // First hello — staggered so the window has settled.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.show(quip: "Привет. Я снова здесь. Кажется, мы оба об этом пожалеем.",
                       mood: .smug,
                       linger: 6)
        }
    }

    // MARK: - Floating Clippy window

    private func buildClippyWindow() {
        let size = NSSize(width: 360, height: 380)
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(x: screen.maxX - size.width - 24,
                             y: screen.minY + 24)

        let window = TransparentWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false

        let root = ClippyView(
            viewModel: viewModel,
            onClick: { [weak self] in self?.tickle() }
        )

        let host = NSHostingView(rootView: AnyView(root))
        host.frame = NSRect(origin: .zero, size: size)
        host.autoresizingMask = [.width, .height]

        window.contentView = host
        window.orderFrontRegardless()

        clippyWindow = window

        NSLog("Paperclip: window placed at \(origin), size \(size); screen visibleFrame=\(screen)")
    }

    // MARK: - Menu bar

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "paperclip",
                                   accessibilityDescription: "Paperclip")
            button.toolTip = "Скрепыш"
        }

        let menu = NSMenu()
        menu.addItem(menuItem(title: "Добавить задачу…", action: #selector(showTasksWindow), key: "n"))
        menu.addItem(menuItem(title: "Список задач…",   action: #selector(showTasksWindow), key: "l"))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Дёрни Скрепыша",  action: #selector(tickleAction), key: "t"))
        menu.addItem(menuItem(title: paused ? "Включить напоминания" : "Пауза напоминаний",
                              action: #selector(togglePause), key: "p", tag: 100))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Спрятать Скрепыша",
                              action: #selector(toggleClippyVisibility), key: "h", tag: 101))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Выход", action: #selector(quit), key: "q"))
        statusItem.menu = menu
    }

    private func menuItem(title: String, action: Selector, key: String, tag: Int = 0) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.tag = tag
        return item
    }

    // MARK: - Actions

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func tickleAction() { tickle() }

    private func tickle() {
        let pending = store.pending
        let line: String
        let mood: ClippyMood
        if pending.isEmpty {
            line = Quips.randomEmpty()
            mood = .smug
        } else {
            line = Quips.random(forTasks: pending)
            mood = .sassy
        }
        show(quip: line, mood: mood, linger: 7)
    }

    @objc private func togglePause(_ sender: NSMenuItem) {
        paused.toggle()
        sender.title = paused ? "Включить напоминания" : "Пауза напоминаний"
        if paused {
            nudgeTimer?.invalidate()
            nudgeTimer = nil
            show(quip: "Ладно, помолчу. Но осуждать буду молча.", mood: .smug, linger: 4)
        } else {
            scheduleNudges()
            show(quip: "Я вернулся. Соскучился?", mood: .sassy, linger: 4)
        }
    }

    @objc private func toggleClippyVisibility(_ sender: NSMenuItem) {
        if clippyWindow.isVisible {
            clippyWindow.orderOut(nil)
            sender.title = "Показать Скрепыша"
        } else {
            clippyWindow.orderFrontRegardless()
            sender.title = "Спрятать Скрепыша"
        }
    }

    @objc private func showTasksWindow() {
        if let win = tasksWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = TasksWindowView(
            store: store,
            onAdded: { [weak self] _ in
                self?.show(quip: Quips.randomOnAdd(), mood: .smug, linger: 4)
            },
            onToggled: { [weak self] task in
                guard let self else { return }
                self.store.toggle(task.id)
                if let updated = self.store.tasks.first(where: { $0.id == task.id }), updated.done {
                    self.show(quip: Quips.randomOnDone(), mood: .smug, linger: 5)
                }
            }
        )

        let host = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: host)
        win.title = "Скрепыш — задачи"
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.isReleasedWhenClosed = false
        win.center()
        win.delegate = WindowCloseObserver.shared
        WindowCloseObserver.shared.onClose = { [weak self] in self?.tasksWindow = nil }

        tasksWindow = win
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }

    // MARK: - Nudge scheduling

    private func scheduleNudges() {
        nudgeTimer?.invalidate()
        let timer = Timer(timeInterval: nudgeIntervalSeconds, repeats: true) { [weak self] _ in
            self?.tickle()
        }
        RunLoop.main.add(timer, forMode: .common)
        nudgeTimer = timer
    }

    // MARK: - Speech bubble lifecycle

    private func show(quip: String, mood: ClippyMood, linger: TimeInterval) {
        quipClearTimer?.invalidate()
        viewModel.mood = mood
        viewModel.quip = quip
        let timer = Timer(timeInterval: linger, repeats: false) { [weak self] _ in
            self?.viewModel.quip = nil
            self?.viewModel.mood = .neutral
        }
        RunLoop.main.add(timer, forMode: .common)
        quipClearTimer = timer
    }
}

// MARK: - Helpers

/// Bridges Clippy's transient state (current quip, mood) to SwiftUI.
final class ClippyViewModel: ObservableObject {
    @Published var quip: String? = nil
    @Published var mood: ClippyMood = .neutral
}

/// Borderless windows are not key by default; we override so the user can interact
/// with our SwiftUI controls (clicks register reliably across macOS versions).
final class TransparentWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Small utility so closing the tasks window clears our reference.
final class WindowCloseObserver: NSObject, NSWindowDelegate {
    static let shared = WindowCloseObserver()
    var onClose: (() -> Void)?
    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
