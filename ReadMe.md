# Event Calendar

Plasmoid для календаря с повесткой дня, погодой и синхронизацией с Google Calendar.

**Plasma 6 / KDE Frameworks 6 / Qt 6** — Работает на Wayland и X11.

## Скриншоты

![](https://i.imgur.com/qdJ71sb.jpg)
![](https://i.imgur.com/Ow8UlFj.jpg)

## Требования

### Минимальные версии

| Компонент                          | Версия | Описание                                 |
| ---------------------------------- | ------ | ---------------------------------------- |
| KDE Plasma                         | ≥ 6.0  | Окружение рабочего стола                 |
| KDE Frameworks                     | ≥ 6.0  | Основные библиотеки KDE                  |
| Qt                                 | ≥ 6.6  | Фреймворк Qt                             |
| X-Plasma-API-Minimum-Version       | 6.0    | API Plasma (указано в metadata.json)     |

### Runtime зависимости

#### Обязательные Qt/QML модули

- `QtQuick` (Qt 6)
- `QtQuick.Controls`
- `QtQuick.Layouts`
- `Qt5Compat.GraphicalEffects` — Модуль совместимости для графических эффектов

#### Обязательные KDE модули

- `org.kde.plasma.plasmoid`
- `org.kde.plasma.core` (PlasmaCore)
- `org.kde.plasma.components` (PlasmaComponents3)
- `org.kde.plasma.plasma5support` (Plasma5Support) — для DataSource
- `org.kde.plasma.calendar` (PlasmaCalendar) — **обязательно**, предоставляется пакетом `plasma-calendar-addons`
- `org.kde.kirigami` (Kirigami)
- `org.kde.ksvg` (KSvg) — для SVG тем
- `org.kde.config` (KConfig)
- `org.kde.kcmutils` (KCMUtils) — для страниц конфигурации

#### Обязательные пакеты

| Пакет                    | Описание                                                              |
| ------------------------ | --------------------------------------------------------------------- |
| `plasma-calendar-addons` | **Обязательно!** Модуль `org.kde.plasma.calendar` для работы виджета  |

### Инструменты установки

| Пакет           | Описание                                      |
| --------------- | --------------------------------------------- |
| `git`           | Система контроля версий                       |
| `kpackagetool6` | Установщик пакетов KDE (входит в Plasma 6)    |

### Опциональные зависимости

| Пакет              | Описание                                           |
| ------------------ | -------------------------------------------------- |
| `plasma-sdk`       | Инструмент `plasmoidviewer` для отладки            |
| `kdeplasma-addons` | Дополнительные плагины календаря (праздники и др.) |
| `plasma-nm`        | Мониторинг сети (NetworkMonitor)                   |

> ⚠️ **Важно:** Пакет `plasma-calendar-addons` является **обязательным**! Без него виджет не запустится и будет показывать только иконку вместо времени.

### Python скрипты (включены в проект)

- `package/contents/scripts/icsjson.py` — Парсинг iCal календарей
- `package/contents/scripts/google_oauth.py` — OAuth-вход в Google через локальный loopback callback и PKCE
- `package/contents/scripts/konsolekalendar.py` — Интеграция с konsolekalendar
- `package/contents/scripts/notification.py` — Уведомления о событиях

### Установка зависимостей по дистрибутивам

**Arch Linux / Manjaro:**

```bash
sudo pacman -S plasma-desktop qt6-5compat git plasma-nm kdeplasma-addons plasma-calendar-addons
```

**Debian 13 (Trixie) / Ubuntu 24.04+:**

```bash
sudo apt install kde-plasma-desktop qml6-module-qt5compat-graphicaleffects git plasma-nm plasma-calendar-addons
```

**Fedora:**

```bash
sudo dnf install plasma-desktop qt6-qt5compat git kf6-kpackage plasma-nm plasma-calendar-addons
```

**openSUSE:**

```bash
sudo zypper install plasma6-desktop qt6-qt5compat-imports git plasma-nm plasma-calendar-addons
```

## Установка из GitHub

```bash
git clone https://github.com/Apophuy/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install
```

Скрипт установки использует `kpackagetool6` для установки plasmoid. Если виджет уже установлен, будет выполнено обновление с автоматическим перезапуском plasmashell.

### Параметры установки

```bash
sh ./install           # Установить или обновить виджет
sh ./install --restart # Установить и принудительно перезапустить plasmashell
sh ./install -r        # То же, что --restart
```

## Обновление

Для обновления из GitHub используйте скрипт обновления:

```bash
cd eventcalendar
sh ./update
```

Скрипт выполняет `git pull` и переустановку виджета с автоматическим перезапуском plasmashell.

Альтернативный способ (ручное обновление):

```bash
cd eventcalendar
git pull
sh ./install --restart
```

## Удаление

Для удаления виджета:

```bash
cd eventcalendar
sh ./uninstall
```

Или вручную используя kpackagetool6:

```bash
kpackagetool6 -t Plasma/Applet -r org.kde.plasma.eventcalendar
```

## Разработка и отладка

### Установка для тестирования

Если вы тестируете код из разработки:

1. Сначала удалите версию из пакетного менеджера
2. Клонируйте и установите из GitHub:

```bash
git clone https://github.com/Apophuy/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install --restart
```

### Отладка с plasmoidviewer

Для отладки используйте `plasmoidviewer` из пакета `plasma-sdk`:

```bash
# Запуск на Wayland
plasmoidviewer -a org.kde.plasma.eventcalendar

# Запуск на X11
plasmoidviewer -a org.kde.plasma.eventcalendar
```

### Просмотр логов

Включите отладку в настройках виджета:
- Правый клик на Calendar → **Event Calendar Settings** → **General** → `debugging = true`

Логи будут отображаться в журнале:

```bash
journalctl --user -f | grep eventcalendar
```

### После завершения тестирования

Удалите тестовую версию с помощью `sh ./uninstall` и установите предпочтительную версию.

## Настройка

### Google Calendar

1. Правый клик на Calendar → **Event Calendar Settings** → **Google Calendar**
2. Нажмите **Login with Google** — браузер откроется автоматически
3. Войдите в Google и разрешите доступ к Calendar и Tasks; после локального перенаправления вернитесь в настройки виджета
4. После того, как окно настроек покажет статус синхронизации, нажмите **Apply**

Авторизация использует loopback callback на `127.0.0.1` и PKCE. Для запуска локального callback требуется `python3`; вход одинаково работает в сеансах Wayland и X11.

### Google Tasks

1. В той же вкладке **Google Calendar** включите интеграцию с Tasks
2. Выберите списки задач для отображения

### Погода (OpenWeatherMap)

1. Перейдите на вкладку **Weather**
2. Введите ID вашего города для OpenWeatherMap
3. Если поиск не находит ваш город, используйте Google: [site:openweathermap.org/city название_города](https://www.google.com/search?q=site%3Aopenweathermap.org%2Fcity)

**Альтернатива:** Weather Canada (для городов Канады)

### iCal Calendar

1. Перейдите на вкладку **Events**
2. Добавьте URL вашего iCal календаря (поддерживаются .ics файлы)

### Плагины календарей Plasma

Виджет поддерживает плагины календаря Plasma (например, для праздников):

1. Установите `kdeplasma-addons`
2. В настройках **Events** → включите нужные плагины
3. Доступные плагины (обычно находятся в `/usr/lib/qt/plugins/plasmacalendarplugins/` или `/usr/lib64/qt5/plugins/plasmacalendarplugins/`):
   - `holidaysevents.so` — праздники (включен по умолчанию)

## Возможности

### Основные функции

- **Календарь** — месячный вид с отображением событий
- **Повестка дня** — список событий на следующие 14 дней
- **Погода** — текущая погода и прогноз (OpenWeatherMap / Weather Canada)
- **Метеограмма** — почасовой график температуры и осадков
- **Таймер** — встроенный таймер с предустановками

### Интеграция с календарями

- Google Calendar (события и задачи)
- iCal календари (.ics)
- Плагины календаря Plasma (праздники и др.)

### Уведомления

- За 15 минут до начала события (настраивается)
- При начале события
- Завершение таймера
- Настраиваемые звуковые эффекты

### Настройки отображения

- Двухколоночный или одноколоночный режим
- Настройка размеров виджета
- Кастомные цвета и стили
- Формат времени (12/24 часа)
- Первый день недели
- Границы ячеек календаря
- Радиус закругления ячеек

## Устранение неполадок

### Виджет не появляется после установки

Перезапустите plasmashell:

```bash
# Через systemd (рекомендуется)
systemctl --user restart plasma-plasmashell.service

# Альтернативный способ
killall plasmashell && kstart plasmashell
```

### Ошибки синхронизации Google Calendar

1. Проверьте подключение к интернету
2. Выйдите и войдите заново в Google Calendar через настройки
3. Убедитесь, что виджет обновлен до последней версии

### Погода не обновляется

1. Проверьте правильность City ID в настройках
2. Убедитесь, что есть интернет-соединение
3. OpenWeatherMap может ограничивать запросы (HTTP 429) — подождите час

### Проблемы после обновления Plasma

После обновления с Plasma 5 на Plasma 6:

```bash
cd eventcalendar
sh ./uninstall
sh ./install --restart
```

## Структура проекта

```
package/
├── metadata.json              # Метаданные плагина (ID, версия, авторы)
├── contents/
│   ├── config/
│   │   ├── config.qml        # Категории настроек
│   │   └── main.xml          # Схема конфигурации (все параметры)
│   ├── ui/
│   │   ├── main.qml          # Точка входа (PlasmoidItem)
│   │   ├── Logic.qml         # Оркестрация обновлений
│   │   ├── EventModel.qml    # Модель событий
│   │   ├── AgendaModel.qml   # Модель повестки дня
│   │   ├── PopupView.qml     # Основной UI виджета
│   │   ├── ClockView.qml     # Компактное представление (часы)
│   │   ├── calendars/        # Интеграция с календарями
│   │   │   ├── CalendarManager.qml
│   │   │   ├── GoogleCalendarManager.qml
│   │   │   ├── GoogleTasksManager.qml
│   │   │   ├── PlasmaCalendarManager.qml
│   │   │   └── ICalManager.qml
│   │   ├── weather/          # API погоды
│   │   ├── config/           # UI настроек
│   │   └── lib/              # Вспомогательные библиотеки
│   └── scripts/
│       ├── icsjson.py        # Парсинг iCal
│       ├── konsolekalendar.py
│       └── notification.py   # Уведомления
└── translate/                 # Переводы (18 языков)
```

## Архитектура

### Поток данных

```
CalendarManagers → EventModel → AgendaModel → UI Views
     ↓
GoogleCalendarManager, PlasmaCalendarManager, ICalManager
```

### Ключевые компоненты

- **CalendarManager** — базовый класс для менеджеров календарей
- **EventModel** — агрегация событий из всех источников
- **AgendaModel** — преобразование событий для отображения в повестке
- **Logic.qml** — обновление данных, опрос, получение погоды

### Конфигурация

- `Plasmoid.configuration.*` — доступ к настройкам из `main.xml`
- `AppletConfig` — хелперы для конфигурации
- `ConfigMigration.qml` — миграция старых настроек при обновлении

## Локализация

Поддерживаемые языки:
- Русский (ru)
- Английский (по умолчанию)
- Немецкий (de)
- Испанский (es)
- Финский (fi)
- Французский (fr)
- Иврит (he)
- Итальянский (it)
- Японский (ja)
- Корейский (ko)
- Голландский (nl)
- Польский (pl)
- Португальский BR (pt_BR)
- Португальский PT (pt_PT)
- Словенский (sl)
- Шведский (sv)
- Турецкий (tr)
- Украинский (uk)
- Китайский (zh_CN)

### Для переводчиков

```bash
cd package/translate
sh ./merge  # Обновить template.pot из i18n() вызовов
sh ./build  # Скомпилировать .po → .mo файлы
sh ./plasmoidlocaletest  # Тестирование с plasmoidviewer
```

## Лицензия

GPL — см. исходный код для деталей

## Авторы

- **Chris Holland** — основной разработчик
- Email: zrenfire@gmail.com
- GitHub: https://github.com/Apophuy/plasma-applet-eventcalendar

## Благодарности

Переводчики, контрибьюторы и сообщество KDE за поддержку проекта.

## Версия

Текущая версия: **77** (см. `package/metadata.json`)

История изменений: [Changelog.md](Changelog.md)
