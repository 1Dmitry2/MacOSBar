# Ручная проверка MacOS Hub

## Smart Cleaner
- [ ] Sidebar остаётся видимым при переходе в «Умная очистка»
- [ ] Нет сырых ключей `cleaner.cat.*`
- [ ] Сканирование с прогрессом и отменой
- [ ] Очистка с подтверждением и отчётом
- [ ] Защищённые папки (Документы, Фото, Keychain) не затрагиваются

## System Monitor
- [ ] Полные имена процессов (Chrome, Xcode)
- [ ] Сортировка, поиск, PID, детали

## Dynamic Island

**Автоматизировано (CI / `swift test --filter HubDynamicIslandTests`):**
- Раскрытие с фиксированным верхом (`expandedFrameKeepsBottomAnchor`)
- Горизонтальное центрирование у `islandCenterX` (`expandedFrameStaysHorizontallyCentered`)
- Старт / toggle / stop панели (`islandPanelStartToggleStop`)
- Подсказки `SystemEventSnapshot` (`SystemEventAggregationTests`)

**Частично (скриншоты, без Computer Use):**
- Компактный остров у menu bar: `docs/qa-screenshots/menu-bar-crop.png`, `island-compact-20261110.png`

**Нужна ручная проверка на MacBook:**
- [ ] Старт у физического выреза (визуально, без щели / перекрытия)
- [ ] Hover-expand, click-expand, auto-collapse
- [ ] Несколько одновременных активностей + `islandMultiActivityEnabled`
- [ ] Микрофон (Voice Memos), смена аудиовыхода (AirPods), Now Playing
- [ ] Режим «встроенный дисплей» при двух мониторах
- [ ] Подключение / отключение внешнего монитора
- [ ] Live Preview в настройках vs плавающий остров
- [ ] Reduce Motion в Системных настройках

Запуск для проверки: `swift run MacOSHub` или `.build/debug/MacOSHub` после  
`defaults write MacOSHub island.enabled -bool true`

## Menu Bar
- [ ] Индикаторы CPU/RAM/Disk/Temp в label
- [ ] Popover с мини-графиками

## Monitor Sidebar
- [ ] Левая / правая панель
- [ ] Сохранение на выбранном дисплее

## Global Shortcuts
- [ ] Работа в фоне
- [ ] Конфликты в настройках
- [ ] Сброс по умолчанию
