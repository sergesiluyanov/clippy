import Foundation
import Combine

struct Task: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var createdAt: Date
    var done: Bool
    /// Optional deadline.  `nil` means "no specific date".
    var deadline: Date?

    init(id: UUID = UUID(),
         title: String,
         createdAt: Date = Date(),
         done: Bool = false,
         deadline: Date? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.done = done
        self.deadline = deadline
    }

    // MARK: - Deadline helpers

    var isOverdue: Bool {
        guard let d = deadline, !done else { return false }
        return d < Date()
    }

    /// True when the deadline is set and falls within the next 24 hours
    /// (and is not already overdue).
    var isDueSoon: Bool {
        guard let d = deadline, !done, !isOverdue else { return false }
        return d.timeIntervalSinceNow < 24 * 60 * 60
    }

    /// Short human-readable label for the deadline ("сегодня",
    /// "завтра 18:00", "через 3 дня", "просрочено на 2 дня").
    var deadlineLabel: String? {
        guard let d = deadline else { return nil }
        return Self.relativeFormatter.relative(to: d)
    }

    private static let relativeFormatter = TaskDeadlineFormatter()
}

/// Formats a deadline as a short, friendly Russian phrase.
struct TaskDeadlineFormatter {
    private let calendar = Calendar.current

    private let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "HH:mm"
        return f
    }()

    private let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMM"
        return f
    }()

    func relative(to deadline: Date, now: Date = Date()) -> String {
        let isOverdue = deadline < now
        let dayDiff = daysBetween(now, deadline)

        let timePart = " " + timeFmt.string(from: deadline)

        switch (isOverdue, dayDiff) {
        case (false, 0):
            return "сегодня" + timePart
        case (false, 1):
            return "завтра" + timePart
        case (false, 2...6):
            return "через \(dayDiff) \(dayWord(dayDiff))"
        case (false, _):
            return "до " + dateFmt.string(from: deadline)
        case (true, 0):
            return "просрочено сегодня"
        case (true, -1):
            return "просрочено вчера"
        case (true, -6...(-2)):
            let d = -dayDiff
            return "просрочено \(d) \(dayWord(d)) назад"
        case (true, _):
            return "просрочено " + dateFmt.string(from: deadline)
        }
    }

    private func daysBetween(_ a: Date, _ b: Date) -> Int {
        let aDay = calendar.startOfDay(for: a)
        let bDay = calendar.startOfDay(for: b)
        return calendar.dateComponents([.day], from: aDay, to: bDay).day ?? 0
    }

    private func dayWord(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod100 >= 11 && mod100 <= 14 { return "дней" }
        switch mod10 {
        case 1:           return "день"
        case 2, 3, 4:     return "дня"
        default:          return "дней"
        }
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
    var overdue: [Task] { pending.filter { $0.isOverdue } }
    var dueSoon: [Task] { pending.filter { $0.isDueSoon } }

    /// Pending tasks sorted: overdue first (oldest deadline first), then
    /// other dated tasks by deadline ascending, then undated.
    var pendingSorted: [Task] {
        pending.sorted { lhs, rhs in
            switch (lhs.deadline, rhs.deadline) {
            case let (l?, r?): return l < r
            case (nil, _?):    return false
            case (_?, nil):    return true
            case (nil, nil):   return lhs.createdAt < rhs.createdAt
            }
        }
    }

    func add(_ title: String, deadline: Date? = nil) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(Task(title: trimmed, deadline: deadline))
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
