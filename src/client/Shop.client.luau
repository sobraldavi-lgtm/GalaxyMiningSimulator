-- Loja Orion: janela com categorias e grade de itens (estilo loja de simulador).
-- O cliente só apresenta e pede ações; saldo, preços e posse são validados no servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.VisualTheme)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local remote = ReplicatedStorage:WaitForChild("InventoryState")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = Theme.Color
local GOLD = Color3.fromHex("#FFB800")
local GREEN = Color3.fromHex("#2FD16B")
local GRAY = Color3.fromHex("#6B6F8F")
local RED = Color3.fromHex("#FF3B4E")

local function stroke(object, color, thickness)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color
	s.Thickness = thickness
	s.Parent = object
	return s
end

local function gradient(object, top, bottom, rotation)
	local g = Instance.new("UIGradient")
	g.Rotation = rotation or 90
	g.Color = ColorSequence.new(top, bottom)
	g.Parent = object
	return g
end

-- ---------- Catálogo (derivado da configuração do servidor/compartilhada) ----------
local categories = {
	{ Id = "Backpacks", Name = "Mochilas", Icon = "pack", Accent = C.Violet },
	{ Id = "Tools", Name = "Ferramentas", Icon = "drill", Accent = C.Cyan },
	{ Id = "Pets", Name = "Pets", Icon = "mission", Accent = C.Green },
}

local items = {}
for index, backpack in ipairs(Config.Backpacks) do
	table.insert(items, {
		Id = backpack.Id, Category = "Backpacks", Kind = "Backpack", Order = index,
		Name = backpack.Name, Color = Color3.fromHex(backpack.Color), Icon = "pack",
		Lines = string.format("Carga %d\nPoder máx +%d", backpack.Capacity, backpack.PowerCap),
		Price = backpack.Price,
	})
end
local tools = {}
for id, upgrade in pairs(Config.Upgrades) do
	table.insert(tools, { id = id, upgrade = upgrade })
end
table.sort(tools, function(a, b) return a.upgrade.Price < b.upgrade.Price end)
for index, entry in ipairs(tools) do
	table.insert(items, {
		Id = entry.id, Category = "Tools", Kind = "Tool", Order = index,
		Name = entry.upgrade.Name, Color = Color3.fromHex(entry.upgrade.Color or "#00D8FF"), Icon = "drill",
		Lines = string.format("Poder %d\nFerramenta", entry.upgrade.Power),
		Price = entry.upgrade.Price, Power = entry.upgrade.Power,
	})
end

for index, pet in ipairs(Config.Pets) do
	table.insert(items, {
		Id = pet.Id, Category = "Pets", Kind = "Pet", Order = index,
		Name = pet.Name, Color = Color3.fromHex(pet.Color), Icon = "mission",
		Lines = string.format("+%d%% de poder\nPet", math.round(pet.Bonus * 100)),
		Price = pet.Price,
	})
end

-- ---------- Janela ----------
local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyShop"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.4
overlay.Size = UDim2.fromScale(1, 1)
overlay.Active = true
overlay.Visible = false
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "ShopWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.52)
window.Size = UDim2.fromScale(0.94, 0.84)
window.BackgroundColor3 = Color3.new(1, 1, 1)
window.BorderSizePixel = 0
Theme.round(window, 20)
stroke(window, C.Deep, 5)
gradient(window, Color3.fromHex("#6A4BFF"), Color3.fromHex("#25157A"))
window.Parent = overlay
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(780, 480)
limit.Parent = window
local windowScale = Instance.new("UIScale")
windowScale.Parent = window

-- Faixa de título
local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.new(0.5, 0, 0, 4)
banner.Size = UDim2.fromOffset(250, 52)
banner.BackgroundColor3 = Color3.new(1, 1, 1)
banner.BorderSizePixel = 0
banner.ZIndex = 3
Theme.round(banner, 14)
stroke(banner, C.Deep, 4)
gradient(banner, Color3.fromHex("#FFE066"), Color3.fromHex("#FF9F1C"))
banner.Parent = window
local title = Theme.label(banner, "LOJA ORION", 28, Color3.new(1, 1, 1))
title.Font = Theme.Font.Display
title.Size = UDim2.fromScale(1, 1)
title.TextStrokeTransparency = 0
title.TextStrokeColor3 = C.Deep
title.ZIndex = 4
title.TextScaled = true
Instance.new("UITextSizeConstraint", title).MaxTextSize = 28

-- Créditos
local pill = Instance.new("Frame")
pill.Position = UDim2.fromOffset(14, 14)
pill.Size = UDim2.fromOffset(150, 36)
pill.BackgroundColor3 = C.Deep
pill.BorderSizePixel = 0
Theme.round(pill, 18)
stroke(pill, GOLD, 2)
pill.Parent = window
local creditsLabel = Theme.label(pill, "✦ 0", 18, GOLD)
creditsLabel.Font = Theme.Font.Display
creditsLabel.Size = UDim2.fromScale(1, 1)

-- Fechar
local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -10, 0, 8)
closeButton.Size = UDim2.fromOffset(42, 42)
closeButton.Text = "X"
closeButton.TextSize = 22
closeButton.Font = Theme.Font.Display
Theme.button(closeButton)
closeButton.AutoButtonColor = true
closeButton.BackgroundColor3 = RED
closeButton.ZIndex = 5
closeButton.Parent = window

-- Categorias
local sidebar = Instance.new("Frame")
sidebar.BackgroundTransparency = 1
sidebar.Position = UDim2.fromOffset(12, 64)
sidebar.Size = UDim2.new(0, 108, 1, -76)
sidebar.Parent = window
local sideList = Instance.new("UIListLayout")
sideList.Padding = UDim.new(0, 8)
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Parent = sidebar

-- Grade de itens
local panel = Instance.new("Frame")
panel.Position = UDim2.fromOffset(130, 64)
panel.Size = UDim2.new(1, -142, 1, -112)
panel.BackgroundColor3 = C.Deep
panel.BackgroundTransparency = 0.45
panel.BorderSizePixel = 0
Theme.round(panel, 14)
stroke(panel, C.Deep, 3)
panel.Parent = window

local scroller = Instance.new("ScrollingFrame")
scroller.BackgroundTransparency = 1
scroller.BorderSizePixel = 0
scroller.Size = UDim2.fromScale(1, 1)
scroller.CanvasSize = UDim2.new()
scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroller.ScrollBarThickness = 6
scroller.Parent = panel
local pad = Instance.new("UIPadding")
pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
pad.Parent = scroller
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(142, 188)
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.Parent = scroller

-- Mensagem de retorno do servidor
local toast = Theme.label(window, "", 14, GOLD)
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 60, 1, -8)
toast.Size = UDim2.new(1, -160, 0, 30)
toast.Visible = false
toast.ZIndex = 4

-- ---------- Estado ----------
local state
local selected = "Backpacks"
local cards = {}
local tabs = {}
local toastId = 0

local function say(message)
	toastId += 1
	local id = toastId
	toast.Text = message
	toast.Visible = true
	task.delay(2.6, function()
		if id == toastId then toast.Visible = false end
	end)
end

local function makeCard(item)
	local card = Instance.new("Frame")
	card.Name = item.Id
	card.LayoutOrder = item.Order
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.BorderSizePixel = 0
	Theme.round(card, 14)
	stroke(card, C.Deep, 3)
	gradient(card, item.Color:Lerp(Color3.new(1, 1, 1), 0.3), item.Color:Lerp(C.Deep, 0.6))

	local name = Theme.label(card, item.Name, 14, Color3.new(1, 1, 1))
	name.Font = Theme.Font.Display
	name.Position = UDim2.fromOffset(4, 4)
	name.Size = UDim2.new(1, -8, 0, 34)
	name.TextScaled = true
	local nameLimit = Instance.new("UITextSizeConstraint")
	nameLimit.MaxTextSize = 15
	nameLimit.MinTextSize = 9
	nameLimit.Parent = name

	local icon = Theme.illustration(card, item.Icon, item.Color)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 52)
	Instance.new("UIScale", icon).Scale = 2.1

	local stats = Theme.label(card, item.Lines, 12, C.Text)
	stats.Position = UDim2.fromOffset(4, 114)
	stats.Size = UDim2.new(1, -8, 0, 32)

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -8)
	button.Size = UDim2.new(1, -16, 0, 34)
	button.TextSize = 14
	button.TextWrapped = true
	button.Font = Theme.Font.Label
	Theme.button(button)
	button.AutoButtonColor = true
	button.Parent = card

	button.Activated:Connect(function()
		if not state then return end
		if item.Kind == "Backpack" then
			if state.BackpackId == item.Id then return end
			remote:FireServer(state.OwnedBackpacks[item.Id] and "EquipBackpack" or "BuyBackpack", item.Id)
		elseif item.Kind == "Pet" then
			if state.EquippedPet == item.Id then
				remote:FireServer("UnequipPet")
			elseif state.OwnedPets[item.Id] then
				remote:FireServer("EquipPet", item.Id)
			else
				remote:FireServer("BuyPet", item.Id)
			end
		elseif not state.OwnedUpgrades[item.Id] then
			remote:FireServer("BuyUpgrade", item.Id)
		end
	end)
	card.Parent = scroller
	return { item = item, frame = card, button = button }
end

local function refresh()
	creditsLabel.Text = "✦ " .. tostring(state and state.Credits or 0)
	for _, card in ipairs(cards) do
		local item = card.item
		card.frame.Visible = item.Category == selected
		if state then
			local text, color
			if item.Kind == "Backpack" then
				if state.BackpackId == item.Id then
					text, color = "✔ EQUIPADA", GOLD
				elseif state.OwnedBackpacks[item.Id] then
					text, color = "EQUIPAR", C.Blue
				end
			elseif item.Kind == "Pet" then
				if state.EquippedPet == item.Id then
					text, color = "✔ GUARDAR", GOLD
				elseif state.OwnedPets[item.Id] then
					text, color = "EQUIPAR", C.Blue
				end
			elseif state.OwnedUpgrades[item.Id] then
				text, color = "✔ ADQUIRIDA", GOLD
			elseif item.Power and item.Power <= state.ToolPower then
				text, color = "SUPERADA", GRAY
			end
			if not text then
				text = "✦ " .. item.Price
				color = state.Credits >= item.Price and GREEN or GRAY
			end
			card.button.Text = text
			card.button.BackgroundColor3 = color
		end
	end
	for id, tab in pairs(tabs) do
		local edge = tab.button:FindFirstChildOfClass("UIStroke")
		edge.Color = id == selected and Color3.new(1, 1, 1) or tab.accent
		edge.Thickness = id == selected and 4 or 2
	end
end

for _, item in ipairs(items) do
	table.insert(cards, makeCard(item))
end
for index, category in ipairs(categories) do
	local button = Theme.navigationAction(sidebar, category.Name, category.Icon, category.Accent)
	button.LayoutOrder = index
	button.Size = UDim2.new(1, 0, 0, 70)
	tabs[category.Id] = { button = button, accent = category.Accent }
	button.Activated:Connect(function()
		selected = category.Id
		scroller.CanvasPosition = Vector2.zero
		refresh()
	end)
end

-- ---------- Abrir / fechar ----------
local function open()
	if overlay.Visible or playerGui:GetAttribute("GalaxyMenuOpen") then return end
	overlay.Visible = true
	playerGui:SetAttribute("GalaxyMenuOpen", true)
	refresh()
	if Theme.reducedMotion(window) then
		windowScale.Scale = 1
	else
		windowScale.Scale = 0.85
		TweenService:Create(windowScale, Theme.Motion.Enter, { Scale = 1 }):Play()
	end
end

local function close()
	if not overlay.Visible then return end
	overlay.Visible = false
	toast.Visible = false
	playerGui:SetAttribute("GalaxyMenuOpen", false)
end

closeButton.Activated:Connect(close)
playerGui:GetAttributeChangedSignal("GalaxyShopRequest"):Connect(open)
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer ~= player then return end
	if prompt.Name == "OpenShop" then
		selected = "Backpacks"
		open()
	elseif prompt.Name == "OpenPets" then
		selected = "Pets"
		open()
	end
end)

remote.OnClientEvent:Connect(function(snapshot)
	state = snapshot
	if overlay.Visible then
		refresh()
		if snapshot.Message then say(snapshot.Message) end
	end
end)

refresh()
