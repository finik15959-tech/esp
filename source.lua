-- =====================================================
-- ESP LocalScript | StarterPlayerScripts
-- Полностью работает без ServerScript / ModuleScript / RemoteEvent
-- Добавлены: BillboardGui с ником над головой, перетаскиваемое меню
-- =====================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- =====================================================
-- НАСТРОЙКИ ЦВЕТОВ ESP
-- =====================================================

local DEFAULT_FILL_COLOR    = Color3.fromRGB(255, 255, 255)
local DEFAULT_OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)

local TG_FILL_COLOR    = Color3.fromRGB(0, 200, 255)
local TG_OUTLINE_COLOR = Color3.fromRGB(0, 200, 255)

local YT_FILL_COLOR    = Color3.fromRGB(220, 30, 30)
local YT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)

local TT_FILL_COLOR    = Color3.fromRGB(0, 0, 0)
local TT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)

-- =====================================================
-- СОСТОЯНИЕ
-- =====================================================

local espEnabled  = true
local listVisible = true

local espHighlights      = {} -- [Player] = Highlight
local espBillboards      = {} -- [Player] = BillboardGui
local characterConnections = {} -- [Player] = RBXScriptConnection

-- =====================================================
-- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ: определить цвет по нику
-- =====================================================

local function getESPColors(playerName)
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
-- BILLBOARD: создать ник над головой игрока
-- Формат: DisplayName (@username)
-- =====================================================

local function applyBillboard(player, character)
	-- Удаляем старый billboard, если есть
	if espBillboards[player] then
		espBillboards[player]:Destroy()
		espBillboards[player] = nil
	end

	if not character then return end

	-- Ищем голову персонажа
	local head = character:WaitForChild("Head", 5)
	if not head then return end

	local fillColor, _ = getESPColors(player.Name)

	-- Для tt_ делаем текст серым (чёрный не виден)
	local textColor = fillColor
	local prefix = string.lower(string.sub(player.Name, 1, 3))
	if prefix == "tt_" then
		textColor = Color3.fromRGB(200, 200, 200)
	end

	-- Создаём BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name            = "ESP_Billboard"
	billboard.Size            = UDim2.new(0, 160, 0, 40)
	billboard.StudsOffset     = Vector3.new(0, 3.2, 0) -- Над головой
	billboard.AlwaysOnTop     = true                   -- Сквозь стены
	billboard.LightInfluence  = 0                      -- Не зависит от освещения
	billboard.Adornee         = head
	billboard.Parent          = head

	-- Фон лейбла (полупрозрачный)
	local bg = Instance.new("Frame")
	bg.Size                   = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.5
	bg.BorderSizePixel        = 0
	bg.Parent                 = billboard

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 6)
	bgCorner.Parent = bg

	-- Текст ника: DisplayName (@username)
	local label = Instance.new("TextLabel")
	label.Size                = UDim2.new(1, -6, 1, 0)
	label.Position            = UDim2.new(0, 3, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3          = textColor
	label.TextStrokeColor3    = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.4
	label.Text                = player.DisplayName .. " (@" .. player.Name .. ")"
	label.TextScaled          = true
	label.Font                = Enum.Font.GothamBold
	label.Parent              = bg

	espBillboards[player] = billboard
	billboard.Enabled = espEnabled
end

-- =====================================================
-- ESP: создать Highlight для персонажа
-- =====================================================

local function applyESP(player, character)
	if espHighlights[player] then
		espHighlights[player]:Destroy()
		espHighlights[player] = nil
	end

	if not character then return end

	local fillColor, outlineColor = getESPColors(player.Name)

	local highlight = Instance.new("Highlight")
	highlight.Name                = "ESP_Highlight"
	highlight.Adornee             = character
	highlight.FillColor           = fillColor
	highlight.OutlineColor        = outlineColor
	highlight.FillTransparency    = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled             = espEnabled
	highlight.Parent              = character

	espHighlights[player] = highlight

	-- Применяем billboard вместе с highlight
	applyBillboard(player, character)
end

-- =====================================================
-- ESP: удалить Highlight и Billboard игрока
-- =====================================================

local function removeESP(player)
	if espHighlights[player] then
		espHighlights[player]:Destroy()
		espHighlights[player] = nil
	end
	if espBillboards[player] then
		espBillboards[player]:Destroy()
		espBillboards[player] = nil
	end
end

-- =====================================================
-- ESP: включить / выключить все подсветки и ники
-- =====================================================

local function setESPEnabled(state)
	espEnabled = state
	for _, highlight in pairs(espHighlights) do
		highlight.Enabled = state
	end
	for _, billboard in pairs(espBillboards) do
		billboard.Enabled = state
	end
end

-- =====================================================
-- ПОДПИСКА НА СОБЫТИЯ ПЕРСОНАЖА ИГРОКА
-- =====================================================

local function setupPlayerESP(player)
	if player.Character then
		applyESP(player, player.Character)
	end

	if characterConnections[player] then
		characterConnections[player]:Disconnect()
	end

	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		applyESP(player, character)
	end)
end

-- =====================================================
-- СОЗДАНИЕ GUI
-- =====================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ESP_GUI"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = false
screenGui.Parent         = PlayerGui

-- =====================================================
-- ПЕРЕТАСКИВАЕМОЕ МЕНЮ УПРАВЛЕНИЯ
-- =====================================================

local controlFrame = Instance.new("Frame")
controlFrame.Name                 = "ControlFrame"
controlFrame.Size                 = UDim2.new(0, 210, 0, 90)
controlFrame.Position             = UDim2.new(0, 10, 0, 10)
controlFrame.BackgroundColor3     = Color3.fromRGB(18, 18, 18)
controlFrame.BackgroundTransparency = 0.15
controlFrame.BorderSizePixel      = 0
controlFrame.Active               = true  -- Обязательно для перетаскивания
controlFrame.Parent               = screenGui

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 10)
controlCorner.Parent = controlFrame

-- Полоска заголовка (за неё тащим)
local dragBar = Instance.new("Frame")
dragBar.Name              = "DragBar"
dragBar.Size              = UDim2.new(1, 0, 0, 22)
dragBar.Position          = UDim2.new(0, 0, 0, 0)
dragBar.BackgroundColor3  = Color3.fromRGB(35, 35, 35)
dragBar.BackgroundTransparency = 0.1
dragBar.BorderSizePixel   = 0
dragBar.ZIndex            = 2
dragBar.Parent            = controlFrame

local dragBarCorner = Instance.new("UICorner")
dragBarCorner.CornerRadius = UDim.new(0, 10)
dragBarCorner.Parent = dragBar

local dragLabel = Instance.new("TextLabel")
dragLabel.Size              = UDim2.new(1, 0, 1, 0)
dragLabel.BackgroundTransparency = 1
dragLabel.TextColor3        = Color3.fromRGB(180, 180, 180)
dragLabel.Text              = "⠿  ESP Menu"
dragLabel.TextScaled        = true
dragLabel.Font              = Enum.Font.GothamBold
dragLabel.ZIndex            = 3
dragLabel.Parent            = dragBar

-- Кнопка ESP
local espButton = Instance.new("TextButton")
espButton.Name              = "ESPButton"
espButton.Size              = UDim2.new(0, 92, 0, 28)
espButton.Position          = UDim2.new(0, 6, 0, 28)
espButton.BackgroundColor3  = Color3.fromRGB(0, 180, 80)
espButton.TextColor3        = Color3.fromRGB(255, 255, 255)
espButton.Text              = "ESP: ON"
espButton.TextScaled        = true
espButton.Font              = Enum.Font.GothamBold
espButton.BorderSizePixel   = 0
espButton.ZIndex            = 2
espButton.Parent            = controlFrame

local espBtnCorner = Instance.new("UICorner")
espBtnCorner.CornerRadius = UDim.new(0, 6)
espBtnCorner.Parent = espButton

-- Кнопка Список
local listButton = Instance.new("TextButton")
listButton.Name             = "ListButton"
listButton.Size             = UDim2.new(0, 92, 0, 28)
listButton.Position         = UDim2.new(0, 112, 0, 28)
listButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
listButton.TextColor3       = Color3.fromRGB(255, 255, 255)
listButton.Text             = "List: ON"
listButton.TextScaled       = true
listButton.Font             = Enum.Font.GothamBold
listButton.BorderSizePixel  = 0
listButton.ZIndex           = 2
listButton.Parent           = controlFrame

local listBtnCorner = Instance.new("UICorner")
listBtnCorner.CornerRadius = UDim.new(0, 6)
listBtnCorner.Parent = listButton

-- Подсказка горячих клавиш
local hotkeyLabel = Instance.new("TextLabel")
hotkeyLabel.Size                  = UDim2.new(1, -12, 0, 16)
hotkeyLabel.Position              = UDim2.new(0, 6, 0, 68)
hotkeyLabel.BackgroundTransparency = 1
hotkeyLabel.TextColor3            = Color3.fromRGB(140, 140, 140)
hotkeyLabel.Text                  = "F4 — ESP   |   F5 — List"
hotkeyLabel.TextScaled            = true
hotkeyLabel.Font                  = Enum.Font.Gotham
hotkeyLabel.ZIndex                = 2
hotkeyLabel.Parent                = controlFrame

-- =====================================================
-- ЛОГИКА ПЕРЕТАСКИВАНИЯ МЕНЮ
-- =====================================================

local dragging       = false
local dragStartPos   = nil  -- позиция мыши в момент нажатия
local frameStartPos  = nil  -- позиция фрейма в момент нажатия

dragBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging      = true
		dragStartPos  = input.Position
		frameStartPos = controlFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (
		input.UserInputType == Enum.UserInputType.MouseMovement or
		input.UserInputType == Enum.UserInputType.Touch
	) then
		local delta = input.Position - dragStartPos
		controlFrame.Position = UDim2.new(
			frameStartPos.X.Scale,
			frameStartPos.X.Offset + delta.X,
			frameStartPos.Y.Scale,
			frameStartPos.Y.Offset + delta.Y
		)
	end
end)

-- =====================================================
-- СПИСОК ИГРОКОВ
-- =====================================================

local listFrame = Instance.new("Frame")
listFrame.Name                  = "PlayerListFrame"
listFrame.Size                  = UDim2.new(0, 230, 0, 300)
listFrame.Position              = UDim2.new(1, -240, 0, 10)
listFrame.BackgroundColor3      = Color3.fromRGB(15, 15, 15)
listFrame.BackgroundTransparency = 0.2
listFrame.BorderSizePixel       = 0
listFrame.Visible               = listVisible
listFrame.Parent                = screenGui

local listFrameCorner = Instance.new("UICorner")
listFrameCorner.CornerRadius = UDim.new(0, 10)
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
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = listTitle

-- ScrollingFrame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size                 = UDim2.new(1, -8, 1, -38)
scrollFrame.Position             = UDim2.new(0, 4, 0, 34)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel      = 0
scrollFrame.ScrollBarThickness   = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.CanvasSize           = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize  = Enum.AutomaticSize.Y
scrollFrame.Parent               = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding    = UDim.new(0, 3)
listLayout.SortOrder  = Enum.SortOrder.Name
listLayout.Parent     = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop    = UDim.new(0, 2)
listPadding.PaddingBottom = UDim.new(0, 2)
listPadding.PaddingLeft   = UDim.new(0, 2)
listPadding.PaddingRight  = UDim.new(0, 2)
listPadding.Parent        = scrollFrame

-- =====================================================
-- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ: цвет текста в списке
-- =====================================================

local function getListColor(playerName)
	local prefix = string.lower(string.sub(playerName, 1, 3))
	if prefix == "tg_" then
		return Color3.fromRGB(0, 200, 255)
	elseif prefix == "yt_" then
		return Color3.fromRGB(220, 50, 50)
	elseif prefix == "tt_" then
		return Color3.fromRGB(160, 160, 160)
	else
		return Color3.fromRGB(220, 220, 220)
	end
end

-- =====================================================
-- СПИСОК: добавить запись игрока
-- Формат: DisplayName (@username)
-- =====================================================

local playerListEntries = {}

local function addPlayerEntry(player)
	if playerListEntries[player] then return end

	local label = Instance.new("TextLabel")
	label.Name                  = player.Name
	label.Size                  = UDim2.new(1, -4, 0, 26)
	label.BackgroundColor3      = Color3.fromRGB(30, 30, 30)
	label.BackgroundTransparency = 0.4
	label.TextColor3            = getListColor(player.Name)
	-- Показываем DisplayName и username
	label.Text                  = "  " .. player.DisplayName .. " (@" .. player.Name .. ")"
	label.TextXAlignment        = Enum.TextXAlignment.Left
	label.TextScaled            = true
	label.Font                  = Enum.Font.Gotham
	label.BorderSizePixel       = 0
	label.Parent                = scrollFrame

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
	listTitle.Text = string.format("Players: %d", #Players:GetPlayers())
end

-- =====================================================
-- ИНИЦИАЛИЗАЦИЯ ИГРОКА
-- =====================================================

local function initPlayer(player)
	if player ~= LocalPlayer then
		setupPlayerESP(player)
	end
	addPlayerEntry(player)
	updateListTitle()
end

-- Все текущие игроки
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

	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end

	updateListTitle()
end)

-- =====================================================
-- КНОПКА ESP
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
-- КНОПКА СПИСОК
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
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F4 then
		espButton.MouseButton1Click:Fire()
	elseif input.KeyCode == Enum.KeyCode.F5 then
		listButton.MouseButton1Click:Fire()
	end
end)

-- =====================================================
-- КОНЕЦ СКРИПТА
-- =====================================================
