# Essential Agent Skills — Русский

<!-- i18n: lang=ru clusters=18 skills=79 -->

Курируемая и проверенная коллекция из **79 навыков для ИИ-агентов**,
охватывающая весь цикл работы над ПО: решить, что строить, построить это
по-тестовому подходу, отдать на ревью, выпустить, эксплуатировать — и писать
собственные навыки.

Каждый навык соответствует открытой спецификации
[Agent Skills](https://agentskills.io/specification), проверяется валидатором
в этом репозитории и зеркалируется во все соглашения обнаружения навыков,
поэтому работает с любым агентом без настройки.

```sh
git clone https://github.com/Alaa91H/portable-agent-skills.git
cd portable-agent-skills && ./install.sh
```

## Что внутри

| | |
| --- | --- |
| Навыков | 79, в 18 областях |
| Агентов | 14 проверенных целей установки |
| Формат | обычный Markdown, без зависимостей |
| Лицензия | MIT |

## Области

1. [Craft and process](https://agentskills.io) <!-- cluster: Craft and process -->
   Решить, что делать, сделать это по-тестовому подходу и доказать, что работает.
2. [Testing and review](https://agentskills.io) <!-- cluster: Testing and review -->
   Отдать работу на проверку, отреагировать на замечания и проверить под нагрузкой.
3. [Working in a codebase](https://agentskills.io) <!-- cluster: Working in a codebase -->
   Сориентироваться, запустить, поддерживать актуальность и сохранять структуру управляемой.
4. [Version control](https://agentskills.io) <!-- cluster: Version control -->
   Ветки, worktree, слияния — и внутренности, когда git удивляет.
5. [Interfaces and accessibility](https://agentskills.io) <!-- cluster: Interfaces and accessibility -->
   Создание и ревью интерфейсов, включая локализацию и соответствие WCAG.
6. [APIs and integrations](https://agentskills.io) <!-- cluster: APIs and integrations -->
   Контракты HTTP и GraphQL, версионирование, вебхуки, аутентификация и платежи.
7. [Data and storage](https://agentskills.io) <!-- cluster: Data and storage -->
   Запросы, изменения схемы, кэширование и фоновая обработка.
8. [Data engineering](https://agentskills.io) <!-- cluster: Data engineering -->
   Моделирование хранилища, оркестрация конвейеров, настройка распределённых вычислений.
9. [Infrastructure and operations](https://agentskills.io) <!-- cluster: Infrastructure and operations -->
   Контейнеры, оркестрация, код инфраструктуры, CI-конвейеры, хосты и инциденты.
10. [Platform operations](https://agentskills.io) <!-- cluster: Platform operations -->
    Положение и стоимость в облаке, секреты и флаги, релевантность поиска, релизы мобильных.
11. [Performance and observability](https://agentskills.io) <!-- cluster: Performance and observability -->
    Найти узкое место, рассуждать о параллелизме и понимать, здоровья ли система.
12. [Reliability and lifecycle](https://agentskills.io) <!-- cluster: Reliability and lifecycle -->
    Выпуск, восстановление, планирование и обращение с данными о людях.
13. [Security](https://agentskills.io) <!-- cluster: Security -->
    Находимые эксплуатируемые дефекты в коде, зависимостях, заголовках и вводе агента.
14. [LLM and agent engineering](https://agentskills.io) <!-- cluster: LLM and agent engineering -->
    Построение на языковых моделях, а также написание, обслуживание и рассылка навыков.
15. [Cross-cutting correctness](https://agentskills.io) <!-- cluster: Cross-cutting correctness -->
    Области, где дефекты прячутся лучше всего: журналы и метки времени.
16. [Checking your own work](https://agentskills.io) <!-- cluster: Checking your own work -->
    Проверки, которые действительно могут упасть, и лежащие под ними примитивы shell.
17. [Working within an agent's limits](https://agentskills.io) <!-- cluster: Working within an agent's limits -->
    Грамотно тратить окно контекста, пережить сжатие и не утверждать непроверенного.
18. [Producing trustworthy output](https://agentskills.io) <!-- cluster: Producing trustworthy output -->
    Последняя миля: что попадает в ответ, как это подтверждено и как заметить сломанный текст.

## Установка для конкретного агента

```sh
./install.sh claude --global     # Claude Code
./install.sh codex --global      # OpenAI Codex
./install.sh cursor --global     # Cursor
./install.sh --list              # показать 79 идентификаторов
./install.sh --update            # получить последнюю версию
```

## Почему навыки остаются на английском

Агент выбирает навык, читая его `name` и `description`. Одинаковые значения этих
полей на всех языках — именно то, что делает коллекцию маршрутизируемой независимо
от языка запроса. Переведено всё, что нужно читателю: контекст, установка и
содержание каждой области.

Указатель переводов и матрица платформ:
[`docs/i18n/README.md`](README.md) и [`docs/platforms.md`](../platforms.md).