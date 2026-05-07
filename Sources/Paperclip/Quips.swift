import Foundation

/// Banks of ironic / passive-aggressive lines, in the spirit of the original Office assistant —
/// but with much more sass. All in Russian, since the user prefers it.
enum Quips {

    /// Generic prods when there are no tasks yet.
    static let emptyList: [String] = [
        "Выглядит так, будто ты пишешь письмо… а, нет, ты просто залипаешь в твиттер.",
        "Список задач пуст. Притворимся, что это сознательный выбор, а не прокрастинация?",
        "Ноль задач. Либо ты гений тайм-менеджмента, либо ты меня обманываешь.",
        "Может, добавим хотя бы одну задачку, чтобы я не чувствовал себя ненужной канцелярией?",
        "Я был полезен в 1997-м. Дай мне снова почувствовать себя нужным.",
        "Знаешь, что сейчас делают продуктивные люди? Откуда мне знать, список-то пустой."
    ]

    /// Templates that wrap an actual task title. Use {task} as the placeholder.
    static let aboutTask: [String] = [
        "Похоже, у тебя есть задача «{task}». Или это была шутка?",
        "Маленькое напоминание: задача «{task}». Очень маленькое. Почти невидимое. Как твоя мотивация.",
        "«{task}» само себя не сделает. Я проверял.",
        "Твоё прошлое «я» искренне верило, что ты сделаешь «{task}». Не подведи легенду.",
        "Слушай, я не давлю, но «{task}» уже как-то странно на меня смотрит.",
        "Я знаю минимум 14 способов отложить задачу «{task}». Сегодня попробуй пятнадцатый — сделать.",
        "Кажется, есть задача «{task}». Подсказка: открыть редактор — уже половина дела.",
        "Если бы задача «{task}» платила проценты за откладывание, мы бы уже могли быть миллионерами.",
        "Может, наконец-то сдеелаешь задачу «{task}»? Или продолжим традицию воскресных обещаний?",
        "«{task}». Просто «{task}». Я даже шутить не буду. Ладно, буду: ты опять её не сделаешь."
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
        "Не может быть. Задача «{task}» сделана?",
        "Минус одна задача. Минус ноль чувства собственной важности у меня.",
        "Готово! Я бы тебя обнял, но у меня нет рук. Только проволока.",
        "Браво. Скрепыш гордится. Даже если задача была «попить воды».",
        "Задача «{task}» сделана. История запомнит этот день."
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
