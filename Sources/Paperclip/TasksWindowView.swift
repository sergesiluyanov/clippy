import SwiftUI

/// A small, simple management window: add tasks with optional deadlines,
/// see the list, mark done, delete.
struct TasksWindowView: View {
    @ObservedObject var store: TaskStore
    var onAdded: (String) -> Void
    var onToggled: (Task) -> Void

    @State private var newTitle: String = ""
    @State private var hasDeadline: Bool = false
    @State private var newDeadline: Date = defaultDeadline()
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Список дел")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
                if !store.tasks.filter({ $0.done }).isEmpty {
                    Button("Очистить выполненные") {
                        store.clearCompleted()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    TextField("Что не сделать сегодня?", text: $newTitle)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                        .onSubmit(add)
                    Button("Добавить", action: add)
                        .keyboardShortcut(.return, modifiers: [])
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                HStack(spacing: 8) {
                    Toggle(isOn: $hasDeadline.animation(.easeInOut(duration: 0.18))) {
                        Label("Дедлайн", systemImage: "calendar")
                            .font(.system(size: 12))
                    }
                    .toggleStyle(.checkbox)

                    if hasDeadline {
                        DatePicker(
                            "",
                            selection: $newDeadline,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .font(.system(size: 12))
                    }
                    Spacer()
                }
            }

            Divider()

            if store.tasks.isEmpty {
                VStack(spacing: 6) {
                    Text("Пока пусто.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("Скрепыш разочарованно поправляет очки.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 18)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(displayedTasks) { task in
                            TaskRow(task: task,
                                    onToggle: { onToggled(task) },
                                    onDelete: { store.remove(task.id) })
                        }
                    }
                }
                .frame(minHeight: 60, maxHeight: 260)
            }
        }
        .padding(14)
        .frame(width: 340)
        .onAppear { inputFocused = true }
    }

    /// Pending sorted (overdue first), then completed at the bottom.
    private var displayedTasks: [Task] {
        store.pendingSorted + store.tasks.filter { $0.done }
    }

    private func add() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.add(trimmed, deadline: hasDeadline ? newDeadline : nil)
        onAdded(trimmed)
        newTitle = ""
        hasDeadline = false
        newDeadline = Self.defaultDeadline()
    }

    /// Tomorrow at 18:00 — a sensible "by end of next workday" default.
    private static func defaultDeadline() -> Date {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var comps = cal.dateComponents([.year, .month, .day], from: tomorrow)
        comps.hour = 18
        comps.minute = 0
        return cal.date(from: comps) ?? tomorrow
    }
}

private struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.done ? .green : .secondary)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(.system(size: 13))
                    .strikethrough(task.done, color: .secondary)
                    .foregroundColor(task.done ? .secondary : .primary)

                if let label = task.deadlineLabel {
                    HStack(spacing: 4) {
                        Image(systemName: task.isOverdue ? "exclamationmark.circle.fill" : "clock")
                            .font(.system(size: 9))
                        Text(label)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(deadlineColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .help("Удалить")
        }
        .padding(.vertical, 3)
    }

    private var deadlineColor: Color {
        if task.done                { return .secondary }
        if task.isOverdue           { return .red }
        if task.isDueSoon           { return .orange }
        return .secondary
    }
}
