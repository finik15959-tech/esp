-- =====================================================
-- ESP LocalScript | StarterPlayerScripts
-- Fix: скрытие стандартного имени Roblox, цвета ESP
-- =====================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- =====================================================
-- ЦВЕТА ESP по префиксу ника
-- =====================================================

local function getESPColors(name)
	local p = string.lower(string.sub(name, 1, 3))
	if p == "tg_" then
		return Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 200, 255)   -- голубой
	elseif p == "yt_" then
		return Color3.fromRGB(220, 30, 30), Color3.fromRGB(0, 0, 0)       -- красный + чёрная обводка
	elseif p == "tt_" then
		return Color3.fromRGB(0, 0, 0), Color3.fromRGB(20, 20, 20)        -- чёрный
	else
		return Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255) -- белый
	end
end

local function getTextColor(name)
	local p = string.lower(string.sub(name, 1, 3))
	if p == "tg_" then return Color3.fromRGB(0, 200, 255)
	elseif p == "yt_" then return Color3.fromRGB(255, 60, 60)
	elseif p == "tt_" then return Color3.fromRGB(180, 180, 180)
	else return Color3.fromRGB(255, 255, 255)
	end
end

-- =====================================================
-- СОСТОЯНИЕ
-- =====================================================

local espEnabled  = true
local listVisible = true

local espHighlights        = {}
local espBillboards        = {}
local characterConnections = {}

-- =====================================================
-- СКРЫТЬ СТАНДАРТНЫЙ ROBLOX NAME TAG
-- =====================================================

local function hideDefaultNametag(character)
	-- Roblox хранит имя в Humanoid > HumanoidRootPart > billboard или
	-- в специальном Billboard под именем "OverheadGui" / нейминге через humanoid
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

-- =====================================================
-- BILLBOARD (наш ник над головой)
-- =====================================================

local function applyBillboard(player, character)
	if espBillboards[player] then
		espBillboards[player]:Destroy()
		espBillboards[player] = nil
	end
	if not character then return end

	local head = character:WaitForChild("Head", 5)
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name           = "ESP_Billboard"
	billboard.Size           = UDim2.new(0, 190, 0, 36)
	billboard.StudsOffset    = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop    = true
	billboard.LightInfluence = 0
	billboard.Adornee        = head
	billboard.Enabled        = espEnabled
	billboard.Parent         = head

	local bg = Instance.new("Frame")
	bg.Size                   = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.4
	bg.BorderSizePixel        = 0
	bg.Parent                 = billboard
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.new(1, -8, 1, 0)
	label.Position               = UDim2.new(0, 4, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3             = getTextColor(player.Name)
	label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.2
	label.Text                   = player.DisplayName .. " (@" .. player.Name .. ")"
	label.TextScaled             = true
	label.Font                   = Enum.Font.GothamBold
	label.Parent                 = bg

	espBillboards[player] = billboard
end

-- =====================================================
-- HIGHLIGHT
-- =====================================================

local function applyESP(player, character)
	if espHighlights[player] then
		espHighlights[player]:Destroy()
		espHighlights[player] = nil
	end
	if not character then return end

	-- Скрываем стандартное имя Roblox
	hideDefaultNametag(character)

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

	applyBillboard(player, character)
end

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

local function setESPEnabled(state)
	espEnabled = state
	for _, h in pairs(espHighlights) do h.Enabled = state end
	for _, b in pairs(espBillboards) do b.Enabled = state end
end

-- =====================================================
-- SETUP PER PLAYER
-- =====================================================

local function setupPlayerESP(player)
	if player.Character then
		applyESP(player, player.Character)
	end
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
	end
	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		task.wait(0.15)
		applyESP(player, character)
	end)
end

-- =====================================================
-- GUI
-- =====================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ESP_GUI"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent         = PlayerGui

-- =====================================================
-- ФУНКЦИЯ ПЕРЕТАСКИВАНИЯ
-- =====================================================

local function makeDraggable(handle, frame)
	local drag, startMouse, startFrame = false, nil, nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			drag       = true
			startMouse = input.Position
			startFrame = frame.Position
		end
	end)

	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			drag = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not drag then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local d = input.Position - startMouse
		frame.Position = UDim2.new(
			startFrame.X.Scale, startFrame.X.Offset + d.X,
			startFrame.Y.Scale, startFrame.Y.Offset + d.Y
		)
	end)
end

-- =====================================================
-- МЕНЮ УПРАВЛЕНИЯ
-- =====================================================

local controlFrame = Instance.new("Frame")
controlFrame.Size                   = UDim2.new(0, 210, 0, 92)
controlFrame.Position               = UDim2.new(0, 10, 0, 10)
controlFrame.BackgroundColor3       = Color3.fromRGB(18, 18, 18)
controlFrame.BackgroundTransparency = 0.1
controlFrame.BorderSizePixel        = 0
controlFrame.Active                 = true
controlFrame.Parent                 = screenGui
Instance.new("UICorner", controlFrame).CornerRadius = UDim.new(0, 10)

local dragCtrl = Instance.new("TextButton")
dragCtrl.Size                   = UDim2.new(1, 0, 0, 24)
dragCtrl.Position               = UDim2.new(0, 0, 0, 0)
dragCtrl.BackgroundColor3       = Color3.fromRGB(35, 35, 35)
dragCtrl.BackgroundTransparency = 0
dragCtrl.BorderSizePixel        = 0
dragCtrl.Text                   = "⠿  ESP Menu"
dragCtrl.TextColor3             = Color3.fromRGB(180, 180, 180)
dragCtrl.TextScaled             = true
dragCtrl.Font                   = Enum.Font.GothamBold
dragCtrl.AutoButtonColor        = false
dragCtrl.ZIndex                 = 3
dragCtrl.Parent                 = controlFrame
Instance.new("UICorner", dragCtrl).CornerRadius = UDim.new(0, 10)
makeDraggable(dragCtrl, controlFrame)

local espButton = Instance.new("TextButton")
espButton.Size             = UDim2.new(0, 92, 0, 30)
espButton.Position         = UDim2.new(0, 6, 0, 30)
espButton.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
espButton.TextColor3       = Color3.fromRGB(255, 255, 255)
espButton.Text             = "ESP: ON"
espButton.TextScaled       = true
espButton.Font             = Enum.Font.GothamBold
espButton.BorderSizePixel  = 0
espButton.ZIndex           = 2
espButton.Parent           = controlFrame
Instance.new("UICorner", espButton).CornerRadius = UDim.new(0, 6)

local listButton = Instance.new("TextButton")
listButton.Size             = UDim2.new(0, 92, 0, 30)
listButton.Position         = UDim2.new(0, 112, 0, 30)
listButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
listButton.TextColor3       = Color3.fromRGB(255, 255, 255)
listButton.Text             = "List: ON"
listButton.TextScaled       = true
listButton.Font             = Enum.Font.GothamBold
listButton.BorderSizePixel  = 0
listButton.ZIndex           = 2
listButton.Parent           = controlFrame
Instance.new("UICorner", listButton).CornerRadius = UDim.new(0, 6)

local hotkeyLabel = Instance.new("TextLabel")
hotkeyLabel.Size                   = UDim2.new(1, -12, 0, 16)
hotkeyLabel.Position               = UDim2.new(0, 6, 0, 70)
hotkeyLabel.BackgroundTransparency = 1
hotkeyLabel.TextColor3             = Color3.fromRGB(120, 120, 120)
hotkeyLabel.Text                   = "F4 — ESP   |   F5 — List"
hotkeyLabel.TextScaled             = true
hotkeyLabel.Font                   = Enum.Font.Gotham
hotkeyLabel.ZIndex                 = 2
hotkeyLabel.Parent                 = controlFrame

-- =====================================================
-- СПИСОК ИГРОКОВ
-- =====================================================

local listFrame = Instance.new("Frame")
listFrame.Size                   = UDim2.new(0, 230, 0, 300)
listFrame.Position               = UDim2.new(1, -240, 0, 10)
listFrame.BackgroundColor3       = Color3.fromRGB(15, 15, 15)
listFrame.BackgroundTransparency = 0.15
listFrame.BorderSizePixel        = 0
listFrame.Visible                = listVisible
listFrame.Active                 = true
listFrame.Parent                 = screenGui
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 10)

local listTitleBar = Instance.new("TextButton")
listTitleBar.Size                   = UDim2.new(1, 0, 0, 30)
listTitleBar.Position               = UDim2.new(0, 0, 0, 0)
listTitleBar.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
listTitleBar.BackgroundTransparency = 0
listTitleBar.TextColor3             = Color3.fromRGB(255, 255, 255)
listTitleBar.Text                   = "Players: 0"
listTitleBar.TextScaled             = true
listTitleBar.Font                   = Enum.Font.GothamBold
listTitleBar.BorderSizePixel        = 0
listTitleBar.AutoButtonColor        = false
listTitleBar.ZIndex                 = 3
listTitleBar.Parent                 = listFrame
Instance.new("UICorner", listTitleBar).CornerRadius = UDim.new(0, 10)
makeDraggable(listTitleBar, listFrame)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size                  = UDim2.new(1, -8, 1, -36)
scrollFrame.Position              = UDim2.new(0, 4, 0, 32)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel       = 0
scrollFrame.ScrollBarThickness    = 4
scrollFrame.ScrollBarImageColor3  = Color3.fromRGB(100, 100, 100)
scrollFrame.CanvasSize            = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize   = Enum.AutomaticSize.Y
scrollFrame.Parent                = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding   = UDim.new(0, 3)
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Parent    = scrollFrame

local listPad = Instance.new("UIPadding")
listPad.PaddingTop    = UDim.new(0, 2)
listPad.PaddingBottom = UDim.new(0, 2)
listPad.PaddingLeft   = UDim.new(0, 2)
listPad.PaddingRight  = UDim.new(0, 2)
listPad.Parent        = scrollFrame

-- =====================================================
-- ЗАПИСИ В СПИСКЕ
-- =====================================================

local playerListEntries = {}

local function addPlayerEntry(player)
	if playerListEntries[player] then return end
	local label = Instance.new("TextLabel")
	label.Name                   = player.Name
	label.Size                   = UDim2.new(1, -4, 0, 26)
	label.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
	label.BackgroundTransparency = 0.35
	label.TextColor3             = getTextColor(player.Name)
	label.Text                   = "  " .. player.DisplayName .. " (@" .. player.Name .. ")"
	label.TextXAlignment         = Enum.TextXAlignment.Left
	label.TextScaled             = true
	label.Font                   = Enum.Font.Gotham
	label.BorderSizePixel        = 0
	label.Parent                 = scrollFrame
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 4)
	playerListEntries[player] = label
end

local function removePlayerEntry(player)
	if playerListEntries[player] then
		playerListEntries[player]:Destroy()
		playerListEntries[player] = nil
	end
end

local function updateListTitle()
	listTitleBar.Text = "Players: " .. #Players:GetPlayers()
end

-- =====================================================
-- ИНИЦИАЛИЗАЦИЯ
-- =====================================================

local function initPlayer(player)
	if player ~= LocalPlayer then
		setupPlayerESP(player)
	end
	addPlayerEntry(player)
	updateListTitle()
end

for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end

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
-- КНОПКИ
-- =====================================================

espButton.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	setESPEnabled(espEnabled)
	espButton.Text             = espEnabled and "ESP: ON"  or "ESP: OFF"
	espButton.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 50, 50)
end)

listButton.MouseButton1Click:Connect(function()
	listVisible = not listVisible
	listFrame.Visible = listVisible
	listButton.Text             = listVisible and "List: ON"  or "List: OFF"
	listButton.BackgroundColor3 = listVisible and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(100, 100, 100)
end)

-- =====================================================
-- БИНДЫ F4 / F5 (gameProcessed игнорируется намеренно)
-- =====================================================

UserInputService.InputBegan:Connect(function(input, _)
	if input.KeyCode == Enum.KeyCode.F4 then
		espEnabled = not espEnabled
		setESPEnabled(espEnabled)
		espButton.Text             = espEnabled and "ESP: ON"  or "ESP: OFF"
		espButton.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 50, 50)

	elseif input.KeyCode == Enum.KeyCode.F5 then
		listVisible = not listVisible
		listFrame.Visible = listVisible
		listButton.Text             = listVisible and "List: ON"  or "List: OFF"
		listButton.BackgroundColor3 = listVisible and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(100, 100, 100)
	end
end)

-- =====================================================
-- КОНЕЦ СКРИПТА
-- =====================================================
