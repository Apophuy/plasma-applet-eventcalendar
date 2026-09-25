# Текущее состояние работы

Дата: 2026-09-25  
Базовый commit рабочего дерева: `68787b7`  
Исходная версия для визуального и функционального сравнения: `564348e`

## Главная цель

Сделать для Plasma 6 полный визуальный и функциональный аналог исходного Event Calendar: сохранить привычную компоновку и поведение, обеспечить адаптивность при разных размерах и масштабах, полноценную работу в Wayland и отсутствие регрессий в X11. Устаревшие механизмы заменять современными эквивалентами без произвольного изменения внешнего вида.

Эта цель и правила адаптивности также добавлены в локальный `AGENTS.md`. Файл игнорируется Git, но используется агентами в этом рабочем каталоге.

## Что уже сделано

### Интерфейс, адаптивность и Wayland

- Удалено ошибочное умножение QML-размеров на `devicePixelRatio`: Qt Quick уже использует логические пиксели.
- `PopupView.qml` перестроен на адаптивный `GridLayout` без хрупких состояний и смешивания anchors с Layout.
- Восстановлена исходная компоновка: метеограмма сверху слева, таймер сверху справа, календарь слева, повестка справа.
- Добавлен автоматический переход в одну колонку, если экран или desktop-виджет слишком узок.
- Учтены все сочетания включённых блоков; размеры popup ограничиваются геометрией экрана.
- Возвращены исходные визуальные значения: отступ 10 логических пикселей, исходный цвет рамки метеограммы, `PlasmaExtras.Heading` в календаре.
- Исправлены размеры tooltip, метеограммы, таймера, форм ввода, диалогов погоды и страниц настроек.
- Восстановлено копирование даты через `DigitalClock.ClipboardMenu`, работающее без X11 clipboard-команд.
- Исправлен жизненный цикл лениво создаваемого popup и обращения к нему из `Logic.qml`.
- Исправлен монитор сети PlasmaNM: используется числовой `connectivity`, а не разбор локализованного текста.
- Обновлены устаревшие обработчики сигналов `Connections` для Qt 6.

### Google Calendar и Tasks

- Удалён заблокированный Google OAuth OOB flow с ручным копированием кода.
- Добавлен `package/contents/scripts/google_oauth.py`: loopback callback на `127.0.0.1`, случайный порт, PKCE S256, проверка state, открытие браузера через `xdg-open`/`gio open`.
- Токены передаются в QML через JSON stdout и не пишутся в лог.
- Исправлен тип `accessTokenExpiresAt`: `uint` заменён на `double`, потому что epoch milliseconds не помещаются в 32 бита.
- Обновление access token объединяет параллельные запросы Calendar и Tasks и корректно сообщает об ошибках.
- Операции больше не продолжаются со старым токеном после неудачного refresh.
- Исправлены зависающие счётчики асинхронных запросов и отсутствовавший обработчик ошибок Google Tasks.
- Улучшена обработка JSON/HTTP ошибок в `Requests.js`, callback теперь вызывается ровно один раз.
- Обновлены инструкции Google-входа в `ReadMe.md`.

Официальные основания для замены flow:

- https://developers.google.com/identity/protocols/oauth2/resources/oob-migration
- https://developers.google.com/identity/protocols/oauth2/resources/loopback-migration
- https://developers.google.com/identity/protocols/oauth2/limited-input-device

### Скрипт переводов

- Старый `package/translate/merge` был проверен до повторного запуска.
- Исправлена несовместимость `/bin/sh` с Bash-синтаксисом.
- Удалены автоматический `sudo apt install` и зависимость от устаревшего `kreadconfig5`.
- Запуск теперь не зависит от текущего каталога и безопасно завершается при отсутствии gettext.
- Добавлен KDE format recognition (`xgettext --kde`), чтобы `%1` не ошибочно считался C format.
- Устранены предупреждения парсера из `ExecUtil.qml` без изменения shell escaping.
- Исправлены некорректные plural headers в старых каталогах es/it/ja/pl/sv и формы единственного plural-сообщения ja/pl.
- Обновлены POT/PO, таблица состояния переводов и metadata; источник website исправлен на репозиторий Apophuy.

## Выполненные проверки

- `git diff --check` — успешно.
- `PYTHONPYCACHEPREFIX=/tmp/eventcalendar-pycache python3 -m py_compile package/contents/scripts/*.py` — успешно.
- `xmllint --noout package/contents/config/main.xml` — успешно.
- `sh -n package/translate/merge` — успешно.
- `sh package/translate/merge` — успешно, без прежних parser warnings.
- `msgfmt --check` для всех `package/translate/*.po` — успешно; остались только нефатальные предупреждения о неполных старых заголовках fi/ja/pt_PT/sv.
- OAuth URL assertions — успешно: loopback redirect, PKCE S256, state, offline access и consent присутствуют.
- `qmllint --bare` для изменённых QML — exit 0. Он выдаёт ожидаемые предупреждения из-за того, что вне runtime Plasma не разрешает `PlasmoidItem`, `Plasmoid`, `PlasmaCore.Action` и контекстные свойства; синтаксических ошибок нет.
- Живой запуск исходников в текущей Wayland-сессии:
  `timeout 18s plasmawindowed /home/ismailov/Projects/plasma-applet-eventcalendar/package`
  — приложение работало до штатного timeout, QML/runtime errors отсутствовали.
- При живом запуске остались только внешние предупреждения:
  отсутствует необязательный `holidaysevents.so`; Qt сообщил о stale cached device pixel ratio.

## Текущее состояние рабочего дерева

Изменения не закоммичены. Изменены UI/QML, Google managers, конфигурация, README, metadata, скрипт и каталоги переводов. Новый файл: `package/contents/scripts/google_oauth.py`. Пользовательские изменения не откатывались. Сгенерированный `__pycache__` удалён.

## План продолжения

1. Просмотреть итоговый `git diff`, особенно большой механический diff PO-файлов; не откатывать остальные пользовательские изменения.
2. Добавить русские переводы для новых сообщений Google OAuth и новых действий интерфейса в `package/translate/ru.po`; после этого снова выполнить `msgfmt --check`.
3. Вручную проверить адаптивность в `plasmawindowed`: широкий двухколоночный режим, узкий одноколоночный режим, calendar-only, timer-only и разные наборы блоков.
4. По возможности выполнить настоящий Google login с пользовательским аккаунтом: callback, выдача refresh token, загрузка Calendar/Tasks и refresh после истечения access token. Автоматически завершить это без участия пользователя невозможно.
5. Повторить финальные проверки: QML lint, Python compile, XML, shell syntax, PO, `git diff --check`, затем изучить `git status --short`.
6. Не запускать установку виджета и не перезапускать `plasmashell` без явного запроса пользователя.

