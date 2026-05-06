import Foundation
import Combine

struct Task: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var createdAt: Date
    var done: Bool

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), done: Bool = false) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.done = done
    }
}

/// Simple JSON-backed store of tasks.
/// Lives in ~/Library/Application Support/Paperclip/tasks.json
final class TaskStore: ObservableObject {

    @Published private(set) var tasks: [Task] = []

    private let fileURL: URL

    init() {
        let fm = FileManager.default
        let support = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? URL(fileURLWithPath: NSHomeDirectory())
        let dir = support.appendingPathComponent("Paperclip", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        self.fileURL = dir.appendingPathComponent("tasks.json")
        load()
    }

    var pending: [Task] { tasks.filter { !$0.done } }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(Task(title: trimmed))
        save()
    }

    func toggle(_ id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].done.toggle()
        save()
    }

    func remove(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        save()
    }

    func clearCompleted() {
        tasks.removeAll { $0.done }
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Task].self, from: data) {
            self.tasks = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(tasks) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
