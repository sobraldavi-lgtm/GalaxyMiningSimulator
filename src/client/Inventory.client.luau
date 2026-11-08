-- HUD principal: telemetria, navegação, notificações, menus (Mochila, Missões e
-- Configurações) e celebração de resgate. Só apresenta e pede ações:
-- saldo, carga, poder e posse continuam decididos pelo servidor.
local Theme = require(script.Parent.VisualTheme)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local remote = ReplicatedStorage:WaitForChild("InventoryState")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local C = Theme.Color

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Camada acima da loja para celebrações e boas-vindas.
local stage = Instance.new("ScreenGui")
stage.Name = "GalaxyCelebration"
stage.ResetOnSpawn = false
stage.DisplayOrder = 30
stage.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
stage.Parent = playerGui

local oreList = {}
for id, ore in pairs(Config.Ores) do
	table.insert(oreList, { id = id, ore = ore, color = Color3.fromHex(ore.Color or "#FFFFFF") })
end
table.sort(oreList, function(a, b) return a.ore.Value < b.ore.Value end)

local function findPet(id)
	for _, pet in ipairs(Config.Pets) do
		if pet.Id == id then return pet end
	end
	return nil
end

local function isGamepad()
	return UserInputService:GetLastInputType().Name:match("^Gamepad") ~= nil
end

-- ---------- Telemetria (topo) ----------
local header = Instance.new("Frame")
header.Name = "Telemetry"
header.BackgroundTransparency = 1
header.AnchorPoint = Vector2.new(0.5, 0)
header.Position = UDim2.new(0.5, 0, 0, 8)
header.Size = UDim2.new(1, -24, 0, 58)
header.Parent = gui
local headerLimit = Instance.new("UISizeConstraint")
headerLimit.MaxSize = Vector2.new(500, 58)
headerLimit.Parent = header
local counters = Instance.new("UIListLayout")
counters.FillDirection = Enum.FillDirection.Horizontal
counters.SortOrder = Enum.SortOrder.LayoutOrder
counters.HorizontalAlignment = Enum.HorizontalAlignment.Center
counters.Padding = UDim.new(0, 6)
counters.Parent = header

local tiles = {}
local function counter(order, name, accent, kind)
	local tile = Instance.new("Frame")
	tile.Name = name
	Theme.panel(tile, accent)
	tile.LayoutOrder = order
	tile.Size = UDim2.new(1 / 3, -4, 1, 0)
	tile.Parent = header
	local badge = Theme.badge(tile, kind, accent, 34)
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, 7, 0.5, -1)
	local caption = Theme.label(tile, name, 11, accent)
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.Position = UDim2.fromOffset(48, 6)
	caption.Size = UDim2.new(1, -54, 0, 13)
	Theme.fitText(caption, 11, 7)
	local value = Theme.label(tile, "…", 22)
	value.Font = Theme.Font.Display
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextStrokeTransparency = 0.2
	value.Position = UDim2.fromOffset(48, 19)
	value.Size = UDim2.new(1, -54, 0, 24)
	Theme.fitText(value, 22, 10)
	local entry = { tile = tile, badge = badge, caption = caption, value = value, accent = accent }
	table.insert(tiles, entry)
	return entry
end

local function meter(entry, color)
	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 48, 1, -11)
	track.Size = UDim2.new(1, -56, 0, 6)
	track.Parent = entry.tile
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = color
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = track
	Theme.meter(track, fill)
	entry.track = track
	return fill
end

local creditsTile = counter(1, "CRÉDITOS", C.Gold, "coin")
local cargoTile = counter(2, "CARGA", C.Cyan, "pack")
local powerTile = counter(3, "PODER", C.Violet, "bolt")
local cargoFill = meter(cargoTile, C.Cyan)
local trainingFill = meter(powerTile, C.Violet)
local cargoStroke = cargoTile.tile:FindFirstChildOfClass("UIStroke")

-- ---------- Navegação ----------
local navigation = Instance.new("Frame")
navigation.Name = "Navigation"
navigation.BackgroundTransparency = 1
navigation.Parent = gui
local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 8)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.Parent = navigation
local navLimit = Instance.new("UISizeConstraint")
navLimit.MaxSize = Vector2.new(660, 300)
navLimit.Parent = navigation

-- ---------- Notificações empilhadas ----------
local toasts = Instance.new("Frame")
toasts.Name = "Toasts"
toasts.BackgroundTransparency = 1
toasts.ZIndex = 20
toasts.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 6)
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Parent = toasts

local tones = {
	success = { C.Mint, "star" },
	error = { C.Red, "lock" },
	warning = { C.Amber, "pin" },
	sale = { C.Gold, "coin" },
	power = { C.Violet, "bolt" },
	pet = { C.Pink, "pet" },
	info = { C.Cyan, "robot" },
}
local toastOrder = 0
local liveToasts = {}

local function dismiss(toast)
	if not toast.Parent then return end
	local scale = toast:FindFirstChildOfClass("UIScale")
	if scale and not Theme.reducedMotion(toast) then
		local tween = TweenService:Create(scale, Theme.Motion.Exit, { Scale = 0 })
		tween.Completed:Once(function() toast:Destroy() end)
		tween:Play()
	else
		toast:Destroy()
	end
end

local function notify(message, tone)
	if not message or message == "" then return end
	local style = tones[tone] or tones.info
	toastOrder += 1
	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.LayoutOrder = toastOrder
	toast.Size = UDim2.new(1, 0, 0, 44)
	Theme.panel(toast, style[1])
	toast.Parent = toasts
	local badge = Theme.badge(toast, style[2], style[1], 30)
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, 7, 0.5, 0)
	local text = Theme.label(toast, message, 14)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Position = UDim2.fromOffset(44, 4)
	text.Size = UDim2.new(1, -52, 1, -8)
	Theme.fitText(text, 14, 9)
	local scale = Instance.new("UIScale")
	scale.Parent = toast
	if not Theme.reducedMotion(toast) then
		scale.Scale = 0.6
		TweenService:Create(scale, Theme.Motion.Pop, { Scale = 1 }):Play()
	end
	table.insert(liveToasts, toast)
	while #liveToasts > 3 do
		dismiss(table.remove(liveToasts, 1))
	end
	task.delay(3.2, function()
		local index = table.find(liveToasts, toast)
		if index then table.remove(liveToasts, index) end
		dismiss(toast)
	end)
end

-- Texto que sobe e some a partir de um elemento (ganhos de Créditos e coletas).
local function floatFrom(entry, text, color)
	local label = Theme.label(entry.tile, text, 16, color)
	label.Font = Theme.Font.Display
	label.TextStrokeTransparency = 0
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 1, 4)
	label.Size = UDim2.new(1.4, 0, 0, 20)
	label.ZIndex = entry.tile.ZIndex + 5
	if Theme.reducedMotion(label) then
		Debris:AddItem(label, 1.2)
		return
	end
	TweenService:Create(label, Theme.Motion.Float, {
		Position = UDim2.new(0.5, 0, 1, 30),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(label, 1)
end

-- ---------- Janela de menus ----------
local menu = Theme.window(gui, "MOCHILA", { MaxSize = Vector2.new(640, 450), ZIndex = 5 })
local tabsBar = Instance.new("Frame")
tabsBar.Name = "Tabs"
tabsBar.BackgroundTransparency = 1
tabsBar.Size = UDim2.new(1, 0, 0, 42)
tabsBar.Parent = menu.Body
local body = Instance.new("ScrollingFrame")
body.Name = "Content"
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.ScrollBarThickness = 6
body.ScrollBarImageColor3 = C.Frost
body.Parent = menu.Body
local bodyPadding = Instance.new("UIPadding")
bodyPadding.PaddingTop = UDim.new(0, 4)
bodyPadding.PaddingBottom = UDim.new(0, 8)
bodyPadding.PaddingLeft = UDim.new(0, 4)
bodyPadding.PaddingRight = UDim.new(0, 10)
bodyPadding.Parent = body
local rows = Instance.new("UIListLayout")
rows.Padding = UDim.new(0, 10)
rows.SortOrder = Enum.SortOrder.LayoutOrder
rows.HorizontalAlignment = Enum.HorizontalAlignment.Center
rows.Parent = body

local state
local currentMenu
local view = {}
local marker
local backpackTab = "Minérios"

local function closeMenu(onClosed)
	if not menu.Overlay.Visible then
		if onClosed then onClosed() end
		return
	end
	Theme.closeWindow(menu, function()
		currentMenu = nil
		playerGui:SetAttribute("GalaxyMenuOpen", false)
		if onClosed then onClosed() end
	end)
end
menu.Close.Activated:Connect(function() closeMenu() end)
menu.Overlay.Activated:Connect(function() closeMenu() end)

local function locate(groupName, partName, label)
	local world = workspace:FindFirstChild("TerraNova")
	local group = world and world:FindFirstChild(groupName)
	local target = group and group:FindFirstChild(partName)
	if not target then
		notify("Terminal fora da área carregada. Aproxime-se e tente novamente.", "warning")
		return
	end
	if marker then marker:Destroy() end
	local highlight = Instance.new("Highlight")
	highlight.Adornee = target
	highlight.FillColor = C.Cyan
	highlight.OutlineColor = C.Cyan
	highlight.FillTransparency = 0.72
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = target
	marker = highlight
	Debris:AddItem(highlight, 18)
	closeMenu()
	notify("Siga o destaque ciano até " .. label .. ".", "warning")
end

local function clearBody()
	for _, child in ipairs(body:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	for _, child in ipairs(tabsBar:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	table.clear(view)
end

local function sectionWell(order, height)
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, height)
	Theme.well(frame)
	frame.Parent = body
	return frame
end

local function gridHolder(order, cell)
	local holder = Instance.new("Frame")
	holder.LayoutOrder = order
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Parent = body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = cell
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = holder
	return holder
end

local function wideAction(order, text, kind, tint, callback)
	local button = Theme.action(body, text, tint)
	button.LayoutOrder = order
	button.Size = UDim2.new(1, 0, 0, 48)
	button.Font = Theme.Font.Display
	button.TextSize = 17
	local icon = Theme.illustration(button, kind, C.Frost)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 12, 0.5, 0)
	button.Activated:Connect(callback)
	return button
end

local function statBox(parent, order, caption, kind, accent)
	local box = Instance.new("Frame")
	box.LayoutOrder = order
	box.Size = UDim2.new(1 / 3, -6, 1, 0)
	Theme.panel(box, accent)
	box.Parent = parent
	local badge = Theme.badge(box, kind, accent, 34)
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, 8, 0.5, 0)
	local cap = Theme.label(box, caption, 11, accent)
	cap.TextXAlignment = Enum.TextXAlignment.Left
	cap.Position = UDim2.fromOffset(50, 8)
	cap.Size = UDim2.new(1, -56, 0, 14)
	Theme.fitText(cap, 11, 7)
	local value = Theme.label(box, "…", 20)
	value.Font = Theme.Font.Display
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Position = UDim2.fromOffset(50, 24)
	value.Size = UDim2.new(1, -56, 0, 30)
	Theme.fitText(value, 20, 9)
	return value, cap
end

-- ----- Mochila: Minérios -----
local function buildOres()
	local summary = Instance.new("Frame")
	summary.LayoutOrder = 1
	summary.BackgroundTransparency = 1
	summary.Size = UDim2.new(1, 0, 0, 64)
	summary.Parent = body
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = summary
	local cargoValue, cargoCaption = statBox(summary, 1, "CARGA", "pack", C.Cyan)
	local worthValue = statBox(summary, 2, "VALOR NA VENDA", "coin", C.Gold)
	local gearValue = statBox(summary, 3, "FERRAMENTA", "drill", C.Violet)

	local holder = gridHolder(2, UDim2.fromOffset(108, 128))
	local slots = {}
	for index, entry in ipairs(oreList) do
		local slot = Instance.new("Frame")
		slot.Name = entry.id
		slot.LayoutOrder = index
		Theme.well(slot)
		slot.Parent = holder
		local badge = Theme.badge(slot, "gem", entry.color, 46)
		badge.AnchorPoint = Vector2.new(0.5, 0)
		badge.Position = UDim2.new(0.5, 0, 0, 8)
		local name = Theme.label(slot, entry.ore.Name, 12)
		name.Position = UDim2.fromOffset(4, 57)
		name.Size = UDim2.new(1, -8, 0, 26)
		Theme.fitText(name, 12, 8)
		local count = Theme.label(slot, "—", 18, C.Gold)
		count.Font = Theme.Font.Display
		count.Position = UDim2.fromOffset(4, 83)
		count.Size = UDim2.new(1, -8, 0, 22)
		local price = Theme.label(slot, "✦ " .. Theme.format(entry.ore.Value) .. " cada", 10, C.Muted)
		price.Font = Theme.Font.Body
		price.Position = UDim2.fromOffset(4, 106)
		price.Size = UDim2.new(1, -8, 0, 14)
		slots[entry.id] = { frame = slot, count = count, badge = badge }
	end
	wideAction(3, "Ir até a Estação de Venda", "pin", C.Blue, function()
		locate("SaleStation", "Counter", "a Estação de Venda")
	end)

	view.update = function(s)
		cargoValue.Text = Theme.compact(s.Weight) .. "/" .. Theme.compact(s.Capacity)
		cargoValue.TextColor3 = s.Weight >= s.Capacity and C.Red or C.Text
		cargoCaption.Text = string.upper(s.BackpackName or "CARGA")
		local worth = 0
		for _, entry in ipairs(oreList) do
			local amount = s.Items[entry.id] or 0
			worth += amount * entry.ore.Value
			local slot = slots[entry.id]
			slot.count.Text = amount > 0 and ("×" .. Theme.format(amount)) or "—"
			slot.count.TextColor3 = amount > 0 and C.Gold or C.Muted
			slot.frame.BackgroundTransparency = amount > 0 and 0.3 or 0.7
			slot.badge.BackgroundTransparency = amount > 0 and 0 or 0.6
		end
		worthValue.Text = "✦ " .. Theme.compact(worth)
		gearValue.Text = s.ToolName
	end
end

-- ----- Mochila: Pets -----
local function buildPets()
	local intro = sectionWell(1, 46)
	local introText = Theme.label(intro, "Um pet equipado por vez. O bônus é somado ao poder da ferramenta.", 13, C.Frost)
	introText.Font = Theme.Font.Body
	introText.Position = UDim2.fromOffset(12, 4)
	introText.Size = UDim2.new(1, -24, 1, -8)
	Theme.fitText(introText, 13, 9)

	local holder = gridHolder(2, UDim2.fromOffset(150, 178))
	local cards = {}
	for index, pet in ipairs(Config.Pets) do
		local color = Color3.fromHex(pet.Color)
		local card = Instance.new("Frame")
		card.Name = pet.Id
		card.LayoutOrder = index
		Theme.well(card)
		card.Parent = holder
		local edge = card:FindFirstChildOfClass("UIStroke")
		local portrait = Theme.badge(card, "pet", color, 64)
		portrait.AnchorPoint = Vector2.new(0.5, 0)
		portrait.Position = UDim2.new(0.5, 0, 0, 8)
		local locked = Theme.badge(card, "lock", C.Gray, 64)
		locked.AnchorPoint = Vector2.new(0.5, 0)
		locked.Position = UDim2.new(0.5, 0, 0, 8)
		local name = Theme.label(card, pet.Name, 17, color)
		name.Font = Theme.Font.Display
		name.TextStrokeTransparency = 0
		name.Position = UDim2.fromOffset(4, 76)
		name.Size = UDim2.new(1, -8, 0, 22)
		local bonus = Theme.label(card, "+" .. math.round(pet.Bonus * 100) .. "% de poder", 12, C.Mint)
		bonus.Position = UDim2.fromOffset(4, 98)
		bonus.Size = UDim2.new(1, -8, 0, 18)
		local button = Theme.action(card, "", C.Blue)
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.new(0.5, 0, 1, -8)
		button.Size = UDim2.new(1, -16, 0, 40)
		button.Font = Theme.Font.Display
		Theme.fitText(button, 15, 9)
		button.Activated:Connect(function()
			if not state then return end
			if not state.OwnedPets[pet.Id] then
				locate("PetShop", "Terminal", "o OVNI de resgate")
			elseif state.EquippedPet == pet.Id then
				remote:FireServer("UnequipPet")
			else
				remote:FireServer("EquipPet", pet.Id)
			end
		end)
		cards[pet.Id] = { pet = pet, portrait = portrait, locked = locked, button = button, edge = edge, name = name }
	end
	wideAction(3, "Ir até o OVNI de resgate", "pin", C.Violet, function()
		locate("PetShop", "Terminal", "o OVNI de resgate")
	end)

	view.update = function(s)
		for id, entry in pairs(cards) do
			local owned = s.OwnedPets[id] == true
			local equipped = s.EquippedPet == id
			entry.portrait.Visible = owned
			entry.locked.Visible = not owned
			entry.name.Text = owned and entry.pet.Name or "???"
			entry.edge.Color = equipped and C.Gold or C.Deep
			entry.edge.Thickness = equipped and 4 or 3
			if equipped then
				entry.button.Text = "✔ GUARDAR"
				Theme.setTint(entry.button, C.Gold:Lerp(C.Deep, 0.15))
			elseif owned then
				entry.button.Text = "EQUIPAR"
				Theme.setTint(entry.button, C.Blue)
			else
				entry.button.Text = "✦ " .. Theme.format(entry.pet.Price) .. " no OVNI"
				Theme.setTint(entry.button, C.Gray)
			end
		end
	end
end

-- ----- Missões (prévia; o sistema de missões ainda não existe) -----
local missionTitles = {
	{ "Primeiro contato", "Minerar cinco unidades de ferro espacial." },
	{ "Primeira venda", "Vender recursos na estação." },
	{ "Tecnologia aprimorada", "Comprar a primeira melhoria." },
	{ "Amigo alienígena", "Descobrir e equipar Lumini." },
	{ "Sinal desconhecido", "Encontrar a caverna azul e reativar o transmissor." },
}
local function buildMissions()
	local orbi = sectionWell(1, 92)
	local badge = Theme.badge(orbi, "robot", C.Cyan, 64)
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, 12, 0.5, 0)
	local name = Theme.label(orbi, "ORBI · Assistente de exploração", 17, C.Cyan)
	name.Font = Theme.Font.Display
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Position = UDim2.fromOffset(88, 10)
	name.Size = UDim2.new(1, -100, 0, 22)
	Theme.fitText(name, 17, 10)
	local speech = Theme.label(orbi,
		"“Transmissões chegando em breve! Enquanto isso: minere, venda e melhore seu equipamento.”", 13, C.Frost)
	speech.Font = Theme.Font.Body
	speech.TextXAlignment = Enum.TextXAlignment.Left
	speech.Position = UDim2.fromOffset(88, 34)
	speech.Size = UDim2.new(1, -100, 0, 50)
	Theme.fitText(speech, 13, 9)
	for index, mission in ipairs(missionTitles) do
		local row = sectionWell(index + 1, 58)
		row.BackgroundTransparency = 0.6
		local lock = Theme.badge(row, "lock", C.Gray, 38)
		lock.AnchorPoint = Vector2.new(0, 0.5)
		lock.Position = UDim2.new(0, 10, 0.5, 0)
		local title = Theme.label(row, index .. ". " .. mission[1], 15, C.Text)
		title.Font = Theme.Font.Display
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Position = UDim2.fromOffset(58, 7)
		title.Size = UDim2.new(1, -150, 0, 20)
		Theme.fitText(title, 15, 9)
		local detail = Theme.label(row, mission[2], 12, C.Muted)
		detail.Font = Theme.Font.Body
		detail.TextXAlignment = Enum.TextXAlignment.Left
		detail.Position = UDim2.fromOffset(58, 28)
		detail.Size = UDim2.new(1, -150, 0, 22)
		Theme.fitText(detail, 12, 8)
		local soon = Theme.label(row, "EM BREVE", 12, C.Amber)
		soon.Font = Theme.Font.Display
		soon.AnchorPoint = Vector2.new(1, 0.5)
		soon.Position = UDim2.new(1, -12, 0.5, 0)
		soon.Size = UDim2.fromOffset(80, 22)
	end
end

-- ----- Configurações (preferências locais desta sessão) -----
local function buildSettings()
	local options = {
		{ "Movimento reduzido", "Desliga animações de menus, números e contadores.", "GalaxyReduceMotion", false },
		{ "Números de dano", "Mostra o dano de cada golpe acima do minério.", "GalaxyHideDamage", true },
		{ "Poeira cósmica", "Partículas brilhantes flutuando ao seu redor.", "GalaxyHideDust", true },
	}
	for index, option in ipairs(options) do
		local attribute, inverted = option[3], option[4]
		local current = playerGui:GetAttribute(attribute) == true
		local row = Theme.toggle(body, option[1], option[2], if inverted then not current else current, function(value)
			playerGui:SetAttribute(attribute, if inverted then not value else value)
		end)
		row.LayoutOrder = index
	end
	local keys = sectionWell(10, 64)
	local text = Theme.label(keys,
		"Atalhos  ·  L Loja  ·  B Mochila  ·  M Missões  ·  P Configurações\nNo controle, B fecha a janela aberta.", 13, C.Frost)
	text.Font = Theme.Font.Body
	text.Position = UDim2.fromOffset(12, 4)
	text.Size = UDim2.new(1, -24, 1, -8)
	Theme.fitText(text, 13, 9)
end

local function render()
	if state and view.update then
		view.update(state)
	end
end

local titles = { ["Mochila"] = "MOCHILA", ["Missões"] = "MISSÕES", ["Configurações"] = "AJUSTES" }

local function openMenu(name)
	if name == "Loja" then
		-- A loja tem interface própria (Shop.client.luau).
		closeMenu(function()
			playerGui:SetAttribute("GalaxyShopRequest", os.clock())
		end)
		return
	end
	if playerGui:GetAttribute("GalaxyShopOpen") or menu.Closing then return end
	local wasOpen = menu.Overlay.Visible
	currentMenu = name
	menu.Title.Text = titles[name] or string.upper(name)
	clearBody()
	body.CanvasPosition = Vector2.zero
	local hasTabs = name == "Mochila"
	tabsBar.Visible = hasTabs
	body.Position = UDim2.fromOffset(0, hasTabs and 50 or 0)
	body.Size = UDim2.new(1, 0, 1, hasTabs and -50 or 0)
	if hasTabs then
		for index, tab in ipairs({ "Minérios", "Pets" }) do
			local active = backpackTab == tab
			local button = Theme.action(tabsBar, tab, active and C.Cyan:Lerp(C.Deep, 0.25) or C.Navy)
			button.Font = Theme.Font.Display
			button.TextSize = 17
			button.Position = UDim2.new((index - 1) * 0.5, index == 1 and 0 or 4, 0, 0)
			button.Size = UDim2.new(0.5, -4, 1, 0)
			local edge = button:FindFirstChildOfClass("UIStroke")
			edge.Color = active and C.Frost or C.Deep
			button.Activated:Connect(function()
				if backpackTab ~= tab then
					backpackTab = tab
					openMenu("Mochila")
				end
			end)
		end
		if backpackTab == "Minérios" then buildOres() else buildPets() end
	elseif name == "Missões" then
		buildMissions()
	elseif name == "Configurações" then
		buildSettings()
	end
	render()
	if not wasOpen then
		playerGui:SetAttribute("GalaxyMenuOpen", true)
		Theme.openWindow(menu)
	end
	if isGamepad() then
		task.defer(function()
			local first = tabsBar:FindFirstChildWhichIsA("TextButton") or body:FindFirstChildWhichIsA("TextButton", true)
			if first then GuiService.SelectedObject = first end
		end)
	end
end

local function toggleMenu(name)
	if currentMenu == name and menu.Overlay.Visible then
		closeMenu()
	else
		openMenu(name)
	end
end

local buttons = {}
for index, entry in ipairs({
	{ "shop", "Loja", C.Amber, "L" },
	{ "pack", "Mochila", C.Cyan, "B" },
	{ "mission", "Missões", C.Violet, "M" },
	{ "settings", "Configurações", C.Green, "P" },
}) do
	local button = Theme.navigationAction(navigation, entry[2], entry[1], entry[3], entry[4])
	button.LayoutOrder = index
	button.Activated:Connect(function() toggleMenu(entry[2]) end)
	buttons[index] = button
end

UserInputService.InputBegan:Connect(function(input, processed)
	-- B do controle fecha a janela mesmo quando a navegação de interface já usou a tecla.
	if input.KeyCode == Enum.KeyCode.ButtonB and menu.Overlay.Visible then
		closeMenu()
		return
	end
	if processed or UserInputService:GetFocusedTextBox() then return end
	if playerGui:GetAttribute("GalaxyShopOpen") then return end
	local shortcuts = {
		[Enum.KeyCode.L] = "Loja",
		[Enum.KeyCode.B] = "Mochila",
		[Enum.KeyCode.M] = "Missões",
		[Enum.KeyCode.P] = "Configurações",
	}
	local target = shortcuts[input.KeyCode]
	-- Sem menu da HUD aberto, a própria loja trata a tecla L.
	if target == "Loja" and not menu.Overlay.Visible then return end
	if target then toggleMenu(target) end
end)

local function layout()
	local size = gui.AbsoluteSize
	local wide = size.X >= 900 and size.Y >= 550
	navigation.AnchorPoint = wide and Vector2.new(0, 0.5) or Vector2.new(0.5, 0)
	navigation.Position = wide and UDim2.new(0, 12, 0.5, 0) or UDim2.new(0.5, 0, 0, 72)
	navigation.Size = wide and UDim2.fromOffset(86, 264) or UDim2.new(1, -24, 0, 54)
	navLayout.FillDirection = wide and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
	for _, button in ipairs(buttons) do
		button.Size = wide and UDim2.new(1, 0, 0, 58) or UDim2.new(1 / #buttons, -6, 1, 0)
		local hint = button:FindFirstChild("KeyHint")
		if hint then hint.Visible = wide and not UserInputService.TouchEnabled end
	end
	toasts.AnchorPoint = wide and Vector2.new(1, 1) or Vector2.new(0.5, 0)
	toasts.Position = wide and UDim2.new(1, -12, 1, -120) or UDim2.new(0.5, 0, 0, 134)
	toasts.Size = wide and UDim2.fromOffset(300, 150) or UDim2.new(1, -24, 0, 150)
	toastLayout.VerticalAlignment = wide and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top
	local toastLimit = toasts:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint", toasts)
	toastLimit.MaxSize = Vector2.new(420, 150)
	-- Em telas estreitas os ícones dos contadores somem para dar espaço aos números.
	local compactHeader = header.AbsoluteSize.X < 390
	for _, entry in ipairs(tiles) do
		entry.badge.Visible = not compactHeader
		local left = compactHeader and 8 or 48
		entry.caption.Position = UDim2.fromOffset(left, 6)
		entry.caption.Size = UDim2.new(1, -(left + 6), 0, 13)
		entry.value.Position = UDim2.fromOffset(left, 19)
		entry.value.Size = UDim2.new(1, -(left + 6), 0, 24)
		if entry.track then
			entry.track.Position = UDim2.new(0, left, 1, -11)
			entry.track.Size = UDim2.new(1, -(left + 8), 0, 6)
		end
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
header:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()

-- ---------- Boas-vindas ----------
do
	local title = Theme.label(stage, "TERRA NOVA", 54, C.Amber)
	title.Font = Theme.Font.Display
	title.TextStrokeTransparency = 0
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.32)
	title.Size = UDim2.new(1, -40, 0, 64)
	Theme.fitText(title, 54, 24)
	local subtitle = Theme.label(stage, "Planeta inicial  ·  Galáxia de Asterion", 20, C.Frost)
	subtitle.Font = Theme.Font.Display
	subtitle.TextStrokeTransparency = 0.1
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.Position = UDim2.new(0.5, 0, 0.32, 34)
	subtitle.Size = UDim2.new(1, -40, 0, 26)
	Theme.fitText(subtitle, 20, 12)
	task.delay(3.5, function()
		local fade = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, label in ipairs({ title, subtitle }) do
			Theme.tween(label, fade, { TextTransparency = 1, TextStrokeTransparency = 1 })
		end
		Debris:AddItem(title, 1.4)
		Debris:AddItem(subtitle, 1.4)
	end)
end

-- ---------- Celebração de resgate de pet ----------
local function celebrate(petId)
	local pet = findPet(petId)
	if not pet then return end
	local color = Color3.fromHex(pet.Color)
	local holder = Instance.new("Frame")
	holder.Name = "PetReveal"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.45)
	holder.Size = UDim2.fromOffset(320, 320)
	holder.BackgroundTransparency = 1
	holder.Parent = stage
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	local rays = {}
	for index = 0, 7 do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.fromScale(0.5, 0.42)
		ray.Size = UDim2.fromOffset(26, 300)
		ray.BackgroundColor3 = index % 2 == 0 and color or C.Gold
		ray.BackgroundTransparency = 0.55
		ray.BorderSizePixel = 0
		ray.Rotation = index * 22.5
		Theme.round(ray, 13)
		ray.Parent = holder
		rays[index + 1] = ray
	end
	local portrait = Theme.badge(holder, "pet", color, 120)
	portrait.AnchorPoint = Vector2.new(0.5, 0.5)
	portrait.Position = UDim2.fromScale(0.5, 0.42)
	portrait.ZIndex = 3
	local headline = Theme.label(holder, "PET RESGATADO!", 34, C.Gold)
	headline.Font = Theme.Font.Display
	headline.TextStrokeTransparency = 0
	headline.AnchorPoint = Vector2.new(0.5, 0)
	headline.Position = UDim2.new(0.5, 0, 0.42, 72)
	headline.Size = UDim2.fromOffset(420, 40)
	headline.ZIndex = 4
	local detail = Theme.label(holder, pet.Name .. "  ·  +" .. math.round(pet.Bonus * 100) .. "% de poder  ·  Equipado", 18, C.Frost)
	detail.Font = Theme.Font.Display
	detail.TextStrokeTransparency = 0.1
	detail.AnchorPoint = Vector2.new(0.5, 0)
	detail.Position = UDim2.new(0.5, 0, 0.42, 112)
	detail.Size = UDim2.fromOffset(420, 24)
	detail.ZIndex = 4
	local spin
	if not Theme.reducedMotion(holder) then
		scale.Scale = 0.2
		TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		local started = os.clock()
		spin = RunService.RenderStepped:Connect(function()
			local angle = (os.clock() - started) * 30
			for index, ray in ipairs(rays) do
				ray.Rotation = (index - 1) * 22.5 + angle
			end
		end)
	end
	task.delay(3, function()
		local function finish()
			if spin then spin:Disconnect() end
			holder:Destroy()
		end
		if Theme.reducedMotion(holder) then
			finish()
			return
		end
		local out = TweenService:Create(scale, Theme.Motion.Exit, { Scale = 0 })
		out.Completed:Once(finish)
		out:Play()
	end)
end

-- ---------- Estado vindo do servidor ----------
local displayedCredits = Instance.new("NumberValue")
displayedCredits.Changed:Connect(function(value)
	creditsTile.value.Text = Theme.compact(math.floor(value + 0.5))
end)
local creditsTween
local fullPulse
local cargoRatio
local lastCredits

local function setFill(fill, ratio)
	Theme.tween(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1),
	})
end

remote.OnClientEvent:Connect(function(snapshot)
	local previous = state
	state = snapshot

	-- Créditos: contagem animada e "+N" flutuante nos ganhos.
	if lastCredits == nil or Theme.reducedMotion(gui) then
		if creditsTween then creditsTween:Cancel() end
		displayedCredits.Value = snapshot.Credits
		creditsTile.value.Text = Theme.compact(snapshot.Credits)
	elseif snapshot.Credits ~= lastCredits then
		if creditsTween then creditsTween:Cancel() end
		creditsTween = TweenService:Create(displayedCredits, Theme.Motion.Count, { Value = snapshot.Credits })
		creditsTween:Play()
		Theme.pop(creditsTile.tile, 0.1)
		local delta = snapshot.Credits - lastCredits
		floatFrom(creditsTile, (delta > 0 and "+" or "") .. Theme.format(delta), delta > 0 and C.Gold or C.Red)
	end
	lastCredits = snapshot.Credits

	-- Carga: medidor, aviso de mochila cheia e coletas.
	local full = snapshot.Weight >= snapshot.Capacity
	cargoTile.value.Text = Theme.compact(snapshot.Weight) .. "/" .. Theme.compact(snapshot.Capacity)
	cargoTile.value.TextColor3 = full and C.Red or C.Text
	cargoTile.caption.Text = full and "CARGA · CHEIA!" or "CARGA"
	cargoTile.caption.TextColor3 = full and C.Red or C.Cyan
	local ratio = snapshot.Capacity > 0 and snapshot.Weight / snapshot.Capacity or 0
	if ratio ~= cargoRatio then
		cargoRatio = ratio
		setFill(cargoFill, ratio)
	end
	cargoFill.BackgroundColor3 = full and C.Red or ratio >= 0.8 and C.Amber or C.Cyan
	if full and not fullPulse and not Theme.reducedMotion(gui) then
		fullPulse = TweenService:Create(cargoStroke,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Color = C.Red })
		fullPulse:Play()
	elseif not full and fullPulse then
		fullPulse:Cancel()
		fullPulse = nil
		cargoStroke.Color = C.Cyan:Lerp(C.Deep, 0.62)
	end
	if previous then
		for _, entry in ipairs(oreList) do
			local gained = (snapshot.Items[entry.id] or 0) - (previous.Items[entry.id] or 0)
			if gained > 0 then
				floatFrom(cargoTile, "+" .. gained .. " " .. entry.ore.Name, entry.color)
				Theme.pop(cargoTile.tile, 0.06)
			end
		end
	end

	-- Poder: valor total e progresso do treino até o limite da mochila.
	powerTile.value.Text = Theme.format(snapshot.Power)
	local maxed = snapshot.TrainingPower >= snapshot.PowerCap
	powerTile.caption.Text = string.format("PODER · TREINO +%d/%d", snapshot.TrainingPower, snapshot.PowerCap)
	setFill(trainingFill, maxed and 1 or snapshot.TrainingClicks / Config.TrainingClicksPerPoint)
	trainingFill.BackgroundColor3 = maxed and C.Gold or C.Violet
	if previous and snapshot.Power > previous.Power then
		Theme.pop(powerTile.tile, 0.12)
	end

	playerGui:SetAttribute("GalaxyToolName", snapshot.ToolName)

	-- Notificações: coletas já aparecem no contador; a loja mostra as próprias mensagens.
	if snapshot.PetReveal then
		celebrate(snapshot.PetReveal)
	elseif snapshot.Message and snapshot.Tone ~= "pickup" and not playerGui:GetAttribute("GalaxyShopOpen") then
		notify(snapshot.Message, snapshot.Tone)
	end
	render()
end)
remote:FireServer()
