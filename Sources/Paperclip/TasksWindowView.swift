import SwiftUI

/// A small, simple management window: add tasks, see the list, mark done, delete.
struct TasksWindowView: View {
    @ObservedObject var store: TaskStore
    var onAdded: (String) -> Void
    var onToggled: (Task) -> Void

    @State private var newTitle: String = ""
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

            HStack(spacing: 6) {
                TextField("Что не сделать сегодня?", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputFocused)
                    .onSubmit(add)
                Button("Добавить", action: add)
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
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
                        ForEach(store.tasks) { task in
                            HStack(alignment: .top, spacing: 8) {
                                Button {
                                    onToggled(task)
                                } label: {
                                    Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.done ? .green : .secondary)
                                        .font(.system(size: 16))
                                }
                                .buttonStyle(.plain)

                                Text(task.title)
                                    .font(.system(size: 13))
                                    .strikethrough(task.done, color: .secondary)
                                    .foregroundColor(task.done ? .secondary : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button {
                                    store.remove(task.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.plain)
                                .help("Удалить")
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                .frame(minHeight: 60, maxHeight: 220)
            }
        }
        .padding(14)
        .frame(width: 320)
        .onAppear { inputFocused = true }
    }

    private func add() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.add(trimmed)
        onAdded(trimmed)
        newTitle = ""
    }
}
