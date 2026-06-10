-- =====================================================
-- ESP LocalScript | StarterPlayerScripts
-- Полностью работает без ServerScript / ModuleScript / RemoteEvent
-- =====================================================

local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")

local LocalPlayer   = Players.LocalPlayer

-- =====================================================
-- НАСТРОЙКИ ЦВЕТОВ ESP
-- =====================================================

-- Цвет по умолчанию (белый)
local DEFAULT_FILL_COLOR    = Color3.fromRGB(255, 255, 255)
local DEFAULT_OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)

-- Голубой (tg_ / TG_ / tG_ / Tg_)
local TG_FILL_COLOR    = Color3.fromRGB(0, 200, 255)
local TG_OUTLINE_COLOR = Color3.fromRGB(0, 200, 255)

-- Красно-чёрный (yt_ / YT_ / yT_ / Yt_)
local YT_FILL_COLOR    = Color3.fromRGB(220, 30, 30)
local YT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)

-- Чёрный (tt_ / TT_ / tT_ / Tt_)
local TT_FILL_COLOR    = Color3.fromRGB(0, 0, 0)
local TT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)

-- =====================================================
-- СОСТОЯНИЕ
-- =====================================================

local espEnabled       = true   -- ESP включён по умолчанию
local listVisible      = true   -- Список игроков виден по умолчанию

-- Таблица: [Player] = Highlight instance
local espHighlights = {}

-- =====================================================
-- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ: определить цвет по нику
-- =====================================================

local function getESPColors(playerName)
	-- Проверяем первые 3 символа в нижнем регистре
	local prefix = string.lower(string.sub(playerName, 1, 3))

	if prefix == "tg_" then
		return TG_FILL_COLOR, TG_OUTLINE_COLOR
	elseif prefix == "yt_" then
		return YT_FILL_COLOR, YT_OUTLINE_COLOR
	elseif prefix == "tt_" then
		return TT_FILL_COLOR, TT_OUTLINE_COLOR
	else
		return DEFAULT_FILL_COLOR, DEFAULT_OUTLINE_COLOR
	end
end

-- =====================================================
-- ESP: создать/обновить Highlight для персонажа
-- =====================================================

local function applyESP(player, character)
	-- Убираем старый Highlight, если есть
	if espHighlights[player] then
		espHighlights[player]:Destroy()
		espHighlights[player] = nil
	end

	if not character then return end

	local fillColor, outlineColor = getESPColors(player.Name)

	local highlight = Instance.new("Highlight")
	highlight.Name            = "ESP_Highlight"
	highlight.Adornee         = character          -- Подсвечиваем весь персонаж
	highlight.FillColor       = fillColor
	highlight.OutlineColor    = outlineColor
	highlight.FillTransparency    = 0.5            -- Полупрозрачная заливка
	highlight.OutlineTransparency = 0              -- Чёткая окантовка
	highlight.DepthMode       = Enum.HighlightDepthMode.AlwaysOnTop -- Сквозь стены
	highlight.Enabled         = espEnabled
	highlight.Parent          = character          -- Храним прямо в персонаже

	espHighlights[player] = highlight
end

-- =====================================================
-- ESP: удалить Highlight игрока
-- =====================================================

local function removeESP(player)
	if espHighlights[player] then
		espHighlights[player]:Destroy()
		espHighlights[player] = nil
	end
end

-- =====================================================
-- ESP: включить / выключить все подсветки
-- =====================================================

local function setESPEnabled(state)
	espEnabled = state
	for _, highlight in pairs(espHighlights) do
		highlight.Enabled = state
	end
end

-- =====================================================
-- ПОДПИСКА НА СОБЫТИЯ ПЕРСОНАЖА ИГРОКА
-- =====================================================

local characterConnections = {} -- [Player] = RBXScriptConnection

local function setupPlayerESP(player)
	-- Если у игрока уже есть персонаж — сразу вешаем ESP
	if player.Character then
		applyESP(player, player.Character)
	end

	-- При каждом возрождении заново применяем ESP
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
	end

	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		-- Небольшая задержка, чтобы персонаж полностью загрузился
		task.wait(0.1)
		applyESP(player, character)
	end)
end

-- =====================================================
-- СОЗДАНИЕ GUI
-- =====================================================

-- Ждём полной загрузки LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name              = "ESP_GUI"
screenGui.ResetOnSpawn      = false   -- Не уничтожать при возрождении
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset    = false
screenGui.Parent            = PlayerGui

-- =====================================================
-- КНОПКИ УПРАВЛЕНИЯ (ESP и Список)
-- =====================================================

-- Фрейм кнопок (верхний левый угол)
local controlFrame = Instance.new("Frame")
controlFrame.Name            = "ControlFrame"
controlFrame.Size            = UDim2.new(0, 200, 0, 70)
controlFrame.Position        = UDim2.new(0, 10, 0, 10)
controlFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
controlFrame.BackgroundTransparency = 0.3
controlFrame.BorderSizePixel = 0
controlFrame.Parent          = screenGui

-- Скруглённые углы для control frame
local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 8)
controlCorner.Parent = controlFrame

-- Кнопка ESP
local espButton = Instance.new("TextButton")
espButton.Name              = "ESPButton"
espButton.Size              = UDim2.new(0, 88, 0, 30)
espButton.Position          = UDim2.new(0, 6, 0, 6)
espButton.BackgroundColor3  = Color3.fromRGB(0, 180, 80)
espButton.TextColor3        = Color3.fromRGB(255, 255, 255)
espButton.Text              = "ESP: ON"
espButton.TextScaled        = true
espButton.Font              = Enum.Font.GothamBold
espButton.BorderSizePixel   = 0
espButton.Parent            = controlFrame

local espBtnCorner = Instance.new("UICorner")
espBtnCorner.CornerRadius = UDim.new(0, 6)
espBtnCorner.Parent = espButton

-- Кнопка Список
local listButton = Instance.new("TextButton")
listButton.Name             = "ListButton"
listButton.Size             = UDim2.new(0, 88, 0, 30)
listButton.Position         = UDim2.new(0, 106, 0, 6)
listButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
listButton.TextColor3       = Color3.fromRGB(255, 255, 255)
listButton.Text             = "List: ON"
listButton.TextScaled       = true
listButton.Font             = Enum.Font.GothamBold
listButton.BorderSizePixel  = 0
listButton.Parent           = controlFrame

local listBtnCorner = Instance.new("UICorner")
listBtnCorner.CornerRadius = UDim.new(0, 6)
listBtnCorner.Parent = listButton

-- Подсказка горячих клавиш
local hotkeyLabel = Instance.new("TextLabel")
hotkeyLabel.Name            = "HotkeyLabel"
hotkeyLabel.Size            = UDim2.new(1, -12, 0, 18)
hotkeyLabel.Position        = UDim2.new(0, 6, 0, 42)
hotkeyLabel.BackgroundTransparency = 1
hotkeyLabel.TextColor3      = Color3.fromRGB(180, 180, 180)
hotkeyLabel.Text            = "F4 — ESP   |   F5 — List"
hotkeyLabel.TextScaled      = true
hotkeyLabel.Font            = Enum.Font.Gotham
hotkeyLabel.Parent          = controlFrame

-- =====================================================
-- СПИСОК ИГРОКОВ
-- =====================================================

-- Основной фрейм списка (правый верхний угол)
local listFrame = Instance.new("Frame")
listFrame.Name              = "PlayerListFrame"
listFrame.Size              = UDim2.new(0, 220, 0, 300)
listFrame.Position          = UDim2.new(1, -230, 0, 10)
listFrame.BackgroundColor3  = Color3.fromRGB(15, 15, 15)
listFrame.BackgroundTransparency = 0.2
listFrame.BorderSizePixel   = 0
listFrame.Visible           = listVisible
listFrame.Parent            = screenGui

local listFrameCorner = Instance.new("UICorner")
listFrameCorner.CornerRadius = UDim.new(0, 8)
listFrameCorner.Parent = listFrame

-- Заголовок списка
local listTitle = Instance.new("TextLabel")
listTitle.Name              = "ListTitle"
listTitle.Size              = UDim2.new(1, 0, 0, 30)
listTitle.Position          = UDim2.new(0, 0, 0, 0)
listTitle.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
listTitle.BackgroundTransparency = 0.1
listTitle.TextColor3        = Color3.fromRGB(255, 255, 255)
listTitle.Text              = "Players on Server"
listTitle.TextScaled        = true
listTitle.Font              = Enum.Font.GothamBold
listTitle.BorderSizePixel   = 0
listTitle.Parent            = listFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = listTitle

-- ScrollingFrame для записей игроков
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name                = "ScrollFrame"
scrollFrame.Size                = UDim2.new(1, -8, 1, -38)
scrollFrame.Position            = UDim2.new(0, 4, 0, 34)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel     = 0
scrollFrame.ScrollBarThickness  = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.CanvasSize          = UDim2.new(0, 0, 0, 0) -- Обновляется динамически
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent              = listFrame

-- Авто-список внутри scroll
local listLayout = Instance.new("UIListLayout")
listLayout.Padding         = UDim.new(0, 3)
listLayout.SortOrder       = Enum.SortOrder.Name
listLayout.Parent          = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop    = UDim.new(0, 2)
listPadding.PaddingBottom = UDim.new(0, 2)
listPadding.PaddingLeft   = UDim.new(0, 2)
listPadding.PaddingRight  = UDim.new(0, 2)
listPadding.Parent        = scrollFrame

-- =====================================================
-- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ: цвет для записи в списке
-- =====================================================

local function getListColor(playerName)
	local prefix = string.lower(string.sub(playerName, 1, 3))
	if prefix == "tg_" then
		return Color3.fromRGB(0, 200, 255)
	elseif prefix == "yt_" then
		return Color3.fromRGB(220, 50, 50)
	elseif prefix == "tt_" then
		return Color3.fromRGB(160, 160, 160) -- Серый для читаемости чёрного текста
	else
		return Color3.fromRGB(220, 220, 220)
	end
end

-- =====================================================
-- СПИСОК: добавить запись игрока
-- =====================================================

-- Таблица: [Player] = TextLabel в списке
local playerListEntries = {}

local function addPlayerEntry(player)
	if playerListEntries[player] then return end -- Уже есть

	local label = Instance.new("TextLabel")
	label.Name              = player.Name
	label.Size              = UDim2.new(1, -4, 0, 24)
	label.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
	label.BackgroundTransparency = 0.4
	label.TextColor3        = getListColor(player.Name)
	label.Text              = "  " .. player.Name
	label.TextXAlignment    = Enum.TextXAlignment.Left
	label.TextScaled        = true
	label.Font              = Enum.Font.Gotham
	label.BorderSizePixel   = 0
	label.Parent            = scrollFrame

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 4)
	entryCorner.Parent = label

	playerListEntries[player] = label
end

-- =====================================================
-- СПИСОК: удалить запись игрока
-- =====================================================

local function removePlayerEntry(player)
	if playerListEntries[player] then
		playerListEntries[player]:Destroy()
		playerListEntries[player] = nil
	end
end

-- =====================================================
-- ОБНОВЛЕНИЕ ЗАГОЛОВКА (кол-во игроков)
-- =====================================================

local function updateListTitle()
	local count = #Players:GetPlayers()
	listTitle.Text = string.format("Players: %d", count)
end

-- =====================================================
-- ИНИЦИАЛИЗАЦИЯ: все текущие игроки
-- =====================================================

local function initPlayer(player)
	-- Не применяем ESP к себе (опционально — убрать условие если нужно)
	if player ~= LocalPlayer then
		setupPlayerESP(player)
	end
	addPlayerEntry(player)
	updateListTitle()
end

-- Инициализируем уже существующих игроков
for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end

-- =====================================================
-- СОБЫТИЯ: вход и выход игроков
-- =====================================================

Players.PlayerAdded:Connect(function(player)
	initPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
	removePlayerEntry(player)

	-- Отписываемся от CharacterAdded
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end

	updateListTitle()
end)

-- =====================================================
-- КНОПКА ESP: переключатель
-- =====================================================

espButton.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	setESPEnabled(espEnabled)

	if espEnabled then
		espButton.Text             = "ESP: ON"
		espButton.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
	else
		espButton.Text             = "ESP: OFF"
		espButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	end
end)

-- =====================================================
-- КНОПКА СПИСОК: переключатель
-- =====================================================

listButton.MouseButton1Click:Connect(function()
	listVisible = not listVisible
	listFrame.Visible = listVisible

	if listVisible then
		listButton.Text             = "List: ON"
		listButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	else
		listButton.Text             = "List: OFF"
		listButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	end
end)

-- =====================================================
-- ГОРЯЧИЕ КЛАВИШИ: F4 и F5
-- =====================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Игнорируем, если игрок печатает в чате
	if gameProcessed then return end

	-- F4 — переключить ESP
	if input.KeyCode == Enum.KeyCode.F4 then
		espButton.MouseButton1Click:Fire()

	-- F5 — переключить список
	elseif input.KeyCode == Enum.KeyCode.F5 then
		listButton.MouseButton1Click:Fire()
	end
end)

-- =====================================================
-- КОНЕЦ СКРИПТА
-- =====================================================
