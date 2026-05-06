import Foundation

/// Banks of ironic / passive-aggressive lines, in the spirit of the original Office assistant —
/// but with much more sass. All in Russian, since the user prefers it.
enum Quips {

    /// Generic prods when there are no tasks yet.
    static let emptyList: [String] = [
        "Выглядит так, будто ты пишешь письмо… а, нет, ты просто залип в твиттер.",
        "Список задач пуст. Притворимся, что это сознательный выбор, а не прокрастинация?",
        "Ноль задач. Либо ты гений тайм-менеджмента, либо ты меня обманываешь.",
        "Может, добавим хотя бы одну задачку, чтобы я не чувствовал себя ненужной канцелярией?",
        "Я был полезен в 1997-м. Дай мне снова почувствовать себя нужным.",
        "Знаешь, что сейчас делают продуктивные люди? Не знаю и я. Список-то пустой."
    ]

    /// Templates that wrap an actual task title. Use {task} as the placeholder.
    static let aboutTask: [String] = [
        "Похоже, ты собирался(-лась) «{task}». Или это была шутка?",
        "Маленькое напоминание: «{task}». Очень маленькое. Почти невидимое. Как твоя мотивация.",
        "«{task}» само себя не сделает. Я проверял.",
        "Твоё прошлое «я» искренне верило, что ты сделаешь «{task}». Не подведи легенду.",
        "Слушай, я не давлю, но «{task}» уже как-то странно на меня смотрит.",
        "Я знаю минимум 14 способов отложить «{task}». Сегодня попробуй пятнадцатый — сделать.",
        "Кажется, ты обещал(-а) «{task}». Подсказка: открыть редактор — уже половина дела.",
        "Если бы «{task}» платило проценты за откладывание, ты бы уже был(-а) миллионером.",
        "Может, наконец-то «{task}»? Или продолжим традицию воскресных обещаний?",
        "«{task}». Просто «{task}». Я даже шутить не буду. Ладно, буду: ты опять не сделал(-а)."
    ]

    /// Lines fired when the user just added a new task.
    static let onAdd: [String] = [
        "Записал. Теперь у нас обоих есть план, который ты не выполнишь.",
        "Добавлено. С нетерпением жду, когда ты это проигнорируешь.",
        "Запомнил. Хотя моя память лучше твоей дисциплины.",
        "Принято. Поставлю галочку в графе «иллюзия контроля».",
        "Готово. Можешь теперь со спокойной совестью открыть YouTube."
    ]

    /// Lines fired when the user marks a task done.
    static let onDone: [String] = [
        "Не может быть. Ты реально что-то сделал(-а)?",
        "Минус одна задача. Минус ноль чувства собственной важности у меня.",
        "Готово! Я бы тебя обнял, но у меня нет рук. Только проволока.",
        "Браво. Скрепыш гордится. Даже если задача была «попить воды».",
        "Ты только что сделал(-а) задачу. История запомнит этот день."
    ]

    /// Returns one prod-line, given the current task list.
    static func random(forTasks tasks: [Task]) -> String {
        guard let task = tasks.randomElement() else {
            return emptyList.randomElement() ?? "Эй."
        }
        let template = aboutTask.randomElement() ?? "{task}"
        return template.replacingOccurrences(of: "{task}", with: task.title)
    }

    static func randomEmpty() -> String {
        emptyList.randomElement() ?? "Эй."
    }

    static func randomOnAdd() -> String {
        onAdd.randomElement() ?? "Записал."
    }

    static func randomOnDone() -> String {
        onDone.randomElement() ?? "Готово."
    }
}
