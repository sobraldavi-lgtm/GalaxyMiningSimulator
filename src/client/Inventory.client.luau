-- HUD principal v5: moedas, navegação, próxima meta, notificações, menus
-- (Mochila, Missões e Ajustes) e celebrações. Só apresenta e pede ações:
-- saldo, carga, poder e posse continuam decididos pelo servidor.
local Theme = require(script.Parent.VisualTheme)
local Sound = require(script.Parent.Sound)
local ArtStyle = require(script.Parent.ArtStyle)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local remote = ReplicatedStorage:WaitForChild("InventoryState")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local C = Theme.Color
local persistSettings -- definida na seção de Ajustes

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Vinheta escura nas bordas: deixa a cena com cara de espaço profundo.
-- Não intercepta cliques (a mineração ignora esta camada).
local vignette = Instance.new("ScreenGui")
vignette.Name = "GalaxyVignette"
vignette.IgnoreGuiInset = true
vignette.ResetOnSpawn = false
vignette.DisplayOrder = -1
vignette.Parent = playerGui
for _, edge in ipairs({
	{ Vector2.new(0, 0), UDim2.new(1, 0, 0.2, 0), 90 },
	{ Vector2.new(0, 1), UDim2.new(1, 0, 0.22, 0), -90 },
	{ Vector2.new(0, 0), UDim2.new(0.16, 0, 1, 0), 0 },
	{ Vector2.new(1, 0), UDim2.new(0.16, 0, 1, 0), 180 },
}) do
	local shade = Instance.new("Frame")
	shade.AnchorPoint = edge[1]
	shade.Position = UDim2.fromScale(edge[1].X, edge[1].Y)
	shade.Size = edge[2]
	shade.BackgroundColor3 = Color3.fromHex("#05030F")
	shade.BorderSizePixel = 0
	local fade = Instance.new("UIGradient")
	fade.Rotation = edge[3]
	fade.Transparency = NumberSequence.new(0.35, 1)
	fade.Parent = shade
	shade.Parent = vignette
end

-- Camada acima da loja para celebrações e boas-vindas.
local stage = Instance.new("ScreenGui")
stage.Name = "GalaxyCelebration"
stage.ResetOnSpawn = false
stage.DisplayOrder = 30
stage.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
stage.Parent = playerGui

-- ---------- Catálogo para apresentação ----------
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

local goals = {}
for _, backpack in ipairs(Config.Backpacks) do
	if backpack.Price > 0 then
		table.insert(goals, { Kind = "Backpack", Id = backpack.Id, Name = backpack.Name, Price = backpack.Price,
			Icon = "pack", Color = Color3.fromHex(backpack.Color), Detail = "Mochila · carga " .. Theme.format(backpack.Capacity) })
	end
end
for id, upgrade in pairs(Config.Upgrades) do
	table.insert(goals, { Kind = "Tool", Id = id, Name = upgrade.Name, Price = upgrade.Price, Power = upgrade.Power,
		Icon = ArtStyle.ToolIcon[ArtStyle.toolFamily(upgrade.Name)], Color = Color3.fromHex(upgrade.Color or "#22E1FF"), Detail = "Ferramenta · poder " .. Theme.format(upgrade.Power) })
end
for _, pet in ipairs(Config.Pets) do
	table.insert(goals, { Kind = "Pet", Id = pet.Id, Name = pet.Name, Price = pet.Price, Icon = ArtStyle.petIcon(pet.Look),
		Color = Color3.fromHex(pet.Color), Detail = "Pet · +" .. math.round(pet.Bonus * 100) .. "% de poder" })
end
table.sort(goals, function(a, b) return a.Price < b.Price end)

-- Item mais barato ainda não obtido (ferramentas só se forem melhores).
local function nextGoal(s)
	for _, goal in ipairs(goals) do
		local owned
		if goal.Kind == "Backpack" then
			owned = s.OwnedBackpacks[goal.Id]
		elseif goal.Kind == "Pet" then
			owned = s.OwnedPets[goal.Id]
		else
			owned = s.OwnedUpgrades[goal.Id] or goal.Power <= s.ToolPower
		end
		if not owned then return goal end
	end
	return nil
end

local function isGamepad()
	return UserInputService:GetLastInputType().Name:match("^Gamepad") ~= nil
end

-- ---------- Moedas (topo) ----------
local currencies = Instance.new("Frame")
currencies.Name = "Currencies"
currencies.BackgroundTransparency = 1
currencies.AnchorPoint = Vector2.new(0.5, 0)
currencies.Position = UDim2.new(0.5, 0, 0, 10)
currencies.Size = UDim2.new(1, -24, 0, 54)
currencies.Parent = gui
local currencyLimit = Instance.new("UISizeConstraint")
currencyLimit.MaxSize = Vector2.new(640, 54)
currencyLimit.Parent = currencies
local currencyPadding = Instance.new("UIPadding")
currencyPadding.PaddingLeft = UDim.new(0, 18)
currencyPadding.Parent = currencies
local currencyLayout = Instance.new("UIListLayout")
currencyLayout.FillDirection = Enum.FillDirection.Horizontal
currencyLayout.SortOrder = Enum.SortOrder.LayoutOrder
currencyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
currencyLayout.Padding = UDim.new(0, 24)
currencyLayout.Parent = currencies

local pills = {}
local function pill(order, name, accent, kind)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1 / 3, -18, 1, 0)
	Theme.panel(frame, accent, 27)
	frame.Parent = currencies
	local badge = Theme.badge(frame, kind, accent, 56)
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, -18, 0.5, 0)
	badge.ZIndex = 3
	local caption = Theme.label(frame, name, 10, accent:Lerp(C.White, 0.2))
	caption.Font = Theme.Font.Display
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.Position = UDim2.fromOffset(44, 5)
	caption.Size = UDim2.new(1, -52, 0, 12)
	Theme.fitText(caption, 11, 7)
	local value = Theme.title(frame, "…", 26, C.White)
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Position = UDim2.fromOffset(44, 16)
	value.Size = UDim2.new(1, -52, 0, 26)
	Theme.fitText(value, 26, 11)
	local entry = { frame = frame, badge = badge, caption = caption, value = value, accent = accent }
	table.insert(pills, entry)
	return entry
end

local function pillMeter(entry, color)
	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 44, 1, -11)
	track.Size = UDim2.new(1, -60, 0, 7)
	track.Parent = entry.frame
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = color
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = track
	Theme.meter(track, fill)
	entry.track = track
	return fill
end

local creditsPill = pill(1, "CRÉDITOS", C.Gold, "coin")
local cargoPill = pill(2, "CARGA", C.Cyan, "pack")
local powerPill = pill(3, "PODER", C.Violet, "bolt")
local cargoFill = pillMeter(cargoPill, C.Cyan)
local trainingFill = pillMeter(powerPill, C.Violet)
local cargoStroke = cargoPill.frame:FindFirstChildOfClass("UIStroke")

-- ---------- Navegação ----------
local navigation = Instance.new("Frame")
navigation.Name = "Navigation"
navigation.BackgroundTransparency = 1
navigation.Parent = gui
local navGrid = Instance.new("UIGridLayout")
navGrid.SortOrder = Enum.SortOrder.LayoutOrder
navGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
navGrid.Parent = navigation

-- ---------- Próxima meta ----------
local goalCard = Instance.new("Frame")
goalCard.Name = "NextGoal"
Theme.panel(goalCard, C.Gold, 18)
goalCard.Visible = false
goalCard.Parent = gui
local goalStroke = goalCard:FindFirstChildOfClass("UIStroke")
local goalHeader = Theme.title(goalCard, "PRÓXIMA META", 13, C.Gold)
goalHeader.TextXAlignment = Enum.TextXAlignment.Left
local goalBadgeHolder = Instance.new("Frame")
goalBadgeHolder.BackgroundTransparency = 1
goalBadgeHolder.Size = UDim2.fromOffset(52, 52)
goalBadgeHolder.Parent = goalCard
local goalName = Theme.title(goalCard, "", 17, C.White)
goalName.TextXAlignment = Enum.TextXAlignment.Left
Theme.fitText(goalName, 17, 9)
local goalDetail = Theme.label(goalCard, "", 11, C.Muted)
goalDetail.Font = Theme.Font.Body
goalDetail.TextXAlignment = Enum.TextXAlignment.Left
Theme.fitText(goalDetail, 11, 7)
local goalTrack = Instance.new("Frame")
goalTrack.Parent = goalCard
local goalFill = Instance.new("Frame")
goalFill.BackgroundColor3 = C.Gold
goalFill.Size = UDim2.fromScale(0, 1)
goalFill.Parent = goalTrack
Theme.meter(goalTrack, goalFill)
local goalAmount = Theme.title(goalTrack, "", 12, C.White)
goalAmount.Size = UDim2.fromScale(1, 1)
goalAmount.ZIndex = 3
local goalButton = Theme.action(goalCard, "ABRIR LOJA", C.Gold, { Size = UDim2.new(1, -24, 0, 38), TextSize = 16 })
local goalBadge
local goalBadgeKey
local goalMode = "goal"

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
	toast.Size = UDim2.new(1, -20, 0, 46)
	Theme.panel(toast, style[1], 23)
	toast.Parent = toasts
	local badge = Theme.badge(toast, style[2], style[1], 48)
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, -12, 0.5, 0)
	local text = Theme.title(toast, message, 15, C.White)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Position = UDim2.fromOffset(44, 4)
	text.Size = UDim2.new(1, -56, 1, -8)
	Theme.fitText(text, 15, 9)
	local scale = Instance.new("UIScale")
	scale.Parent = toast
	if not Theme.reducedMotion(toast) then
		scale.Scale = 0.5
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

-- Texto que sobe e some a partir de uma pílula (ganhos e coletas).
local function floatFrom(entry, text, color)
	local label = Theme.title(entry.frame, text, 18, color)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 1, 2)
	label.Size = UDim2.new(1.5, 0, 0, 22)
	label.ZIndex = 8
	if Theme.reducedMotion(label) then
		Debris:AddItem(label, 1.2)
		return
	end
	local scale = Instance.new("UIScale")
	scale.Scale = 1.4
	scale.Parent = label
	TweenService:Create(scale, Theme.Motion.Pop, { Scale = 1 }):Play()
	TweenService:Create(label, Theme.Motion.Float, {
		Position = UDim2.new(0.5, 0, 1, 34),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(label, 1)
end

-- ---------- Janelas de menu ----------
local windowStyles = {
	["Mochila"] = { Title = "MOCHILA", Accent = C.Cyan, Icon = "pack" },
	["Missões"] = { Title = "MISSÕES", Accent = C.Violet, Icon = "mission" },
	["Configurações"] = { Title = "AJUSTES", Accent = C.Mint, Icon = "settings" },
	["Renascer"] = { Title = "RENASCER", Accent = C.Pink, Icon = "rebirth" },
}
local windows = {}
local state
local currentMenu
local view = {}
local marker
local backpackTab = "Minérios"

local function closeMenu(onClosed)
	local parts = currentMenu and windows[currentMenu]
	if not parts or not parts.Overlay.Visible then
		if onClosed then onClosed() end
		return
	end
	Theme.closeWindow(parts, function()
		currentMenu = nil
		playerGui:SetAttribute("GalaxyMenuOpen", false)
		if onClosed then onClosed() end
	end)
end

local function getWindow(name)
	if windows[name] then return windows[name] end
	local style = windowStyles[name]
	local parts = Theme.window(gui, style.Title, {
		MaxSize = Vector2.new(660, 460), ZIndex = 5, Accent = style.Accent, Icon = style.Icon,
	})
	local tabsBar = Instance.new("Frame")
	tabsBar.Name = "Tabs"
	tabsBar.BackgroundTransparency = 1
	tabsBar.Size = UDim2.new(1, 0, 0, 46)
	tabsBar.Parent = parts.Body
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.CanvasSize = UDim2.new()
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.ScrollBarThickness = 6
	content.ScrollBarImageColor3 = C.Frost
	content.Parent = parts.Body
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = content
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = content
	parts.Tabs = tabsBar
	parts.Content = content
	parts.Close.Activated:Connect(function() closeMenu() end)
	parts.Overlay.Activated:Connect(function() closeMenu() end)
	windows[name] = parts
	return parts
end

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
	highlight.OutlineColor = C.White
	highlight.FillTransparency = 0.6
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = target
	marker = highlight
	Debris:AddItem(highlight, 18)
	closeMenu()
	notify("Siga o destaque até " .. label .. ".", "warning")
end

-- Construtores de conteúdo (recebem o ScrollingFrame da janela).
local function sectionWell(body, order, height)
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, height)
	Theme.panel(frame, C.Violet, 16)
	frame.Parent = body
	return frame
end

local function gridHolder(body, order, cell)
	local holder = Instance.new("Frame")
	holder.LayoutOrder = order
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Parent = body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = cell
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = holder
	return holder
end

local function wideAction(body, order, text, kind, tint, callback)
	local button = Theme.action(body, text, tint, { Size = UDim2.new(1, 0, 0, 54), Icon = kind, TextSize = 19 })
	button.LayoutOrder = order
	button.Activated:Connect(callback)
	return button
end

local function statBox(parent, order, caption, kind, accent)
	local box = Instance.new("Frame")
	box.LayoutOrder = order
	box.Size = UDim2.new(1 / 3, -7, 1, 0)
	Theme.panel(box, accent, 16)
	box.Parent = parent
	local badge = Theme.badge(box, kind, accent, 42)
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, 8, 0.5, 0)
	local cap = Theme.label(box, caption, 10, accent:Lerp(C.White, 0.2))
	cap.Font = Theme.Font.Display
	cap.TextXAlignment = Enum.TextXAlignment.Left
	cap.Position = UDim2.fromOffset(56, 9)
	cap.Size = UDim2.new(1, -62, 0, 13)
	Theme.fitText(cap, 11, 7)
	local value = Theme.title(box, "…", 21, C.White)
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Position = UDim2.fromOffset(56, 24)
	value.Size = UDim2.new(1, -62, 0, 30)
	Theme.fitText(value, 21, 9)
	return value, cap
end

-- ----- Mochila: Minérios -----
local function buildOres(body)
	local summary = Instance.new("Frame")
	summary.LayoutOrder = 1
	summary.BackgroundTransparency = 1
	summary.Size = UDim2.new(1, 0, 0, 66)
	summary.Parent = body
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = summary
	local cargoValue, cargoCaption = statBox(summary, 1, "CARGA", "pack", C.Cyan)
	local worthValue = statBox(summary, 2, "VALOR NA VENDA", "coin", C.Gold)
	local gearValue = statBox(summary, 3, "FERRAMENTA", "drill", C.Violet)

	local holder = gridHolder(body, 2, UDim2.fromOffset(112, 136))
	local slots = {}
	for index, entry in ipairs(oreList) do
		local slot = Instance.new("Frame")
		slot.Name = entry.id
		slot.LayoutOrder = index
		slot.BackgroundColor3 = Color3.new(1, 1, 1)
		slot.BorderSizePixel = 0
		Theme.round(slot, 16)
		Theme.stroke(slot, C.Ink, 3)
		Theme.gradient(slot, entry.color:Lerp(C.Plum, 0.55), C.Night)
		slot.Parent = holder
		local badge = Theme.badge(slot, ArtStyle.oreIcon(entry.id), entry.color, 54)
		badge.AnchorPoint = Vector2.new(0.5, 0)
		badge.Position = UDim2.new(0.5, 0, 0, 8)
		local count = Theme.title(slot, "", 15, C.White)
		count.BackgroundColor3 = C.Ink
		count.BackgroundTransparency = 0.2
		count.AnchorPoint = Vector2.new(1, 0)
		count.Position = UDim2.new(1, -6, 0, 6)
		count.Size = UDim2.fromOffset(42, 20)
		count.ZIndex = 4
		Theme.round(count, 10)
		local name = Theme.title(slot, entry.ore.Name, 13, C.White)
		name.Position = UDim2.fromOffset(4, 66)
		name.Size = UDim2.new(1, -8, 0, 32)
		Theme.fitText(name, 13, 8)
		local price = Theme.label(slot, "✦ " .. Theme.format(entry.ore.Value) .. " cada", 11, C.Gold)
		price.Font = Theme.Font.Display
		price.Position = UDim2.fromOffset(4, 100)
		price.Size = UDim2.new(1, -8, 0, 16)
		local weight = Theme.label(slot, "Peso " .. entry.ore.Weight, 10, C.Muted)
		weight.Font = Theme.Font.Body
		weight.Position = UDim2.fromOffset(4, 116)
		weight.Size = UDim2.new(1, -8, 0, 14)
		slots[entry.id] = { frame = slot, count = count, badge = badge }
	end
	wideAction(body, 3, "IR ATÉ A ESTAÇÃO DE VENDA", "pin", C.Blue, function()
		locate("SaleStation", "Counter", "a Estação de Venda")
	end)

	view.update = function(s)
		cargoValue.Text = Theme.compact(s.Weight) .. "/" .. Theme.compact(s.Capacity)
		cargoValue.TextColor3 = s.Weight >= s.Capacity and C.Red or C.White
		cargoCaption.Text = string.upper(s.BackpackName or "CARGA")
		local worth = 0
		for _, entry in ipairs(oreList) do
			local amount = s.Items[entry.id] or 0
			worth += amount * entry.ore.Value
			local slot = slots[entry.id]
			slot.count.Visible = amount > 0
			slot.count.Text = "×" .. Theme.compact(amount)
			slot.frame.BackgroundTransparency = amount > 0 and 0 or 0.45
			slot.badge.BackgroundTransparency = amount > 0 and 0 or 0.5
		end
		worthValue.Text = "✦ " .. Theme.compact(worth)
		gearValue.Text = s.ToolName
	end
end

-- ----- Mochila: Pets -----
local function buildPets(body)
	local intro = sectionWell(body, 1, 50)
	local introText = Theme.label(intro, "Um pet equipado por vez. O bônus é somado ao poder da ferramenta.", 14, C.Frost)
	introText.Font = Theme.Font.Body
	introText.Position = UDim2.fromOffset(14, 4)
	introText.Size = UDim2.new(1, -28, 1, -8)
	Theme.fitText(introText, 14, 9)

	local holder = gridHolder(body, 2, UDim2.fromOffset(156, 196))
	local cards = {}
	for index, pet in ipairs(Config.Pets) do
		local color = Color3.fromHex(pet.Color)
		local card = Instance.new("Frame")
		card.Name = pet.Id
		card.LayoutOrder = index
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		card.BorderSizePixel = 0
		Theme.round(card, 18)
		local edge = Theme.stroke(card, C.Ink, 3)
		Theme.gradient(card, color:Lerp(C.Plum, 0.45), C.Night)
		card.Parent = holder
		local rays = Theme.rays(card, { Color = color, Alt = C.Gold, Length = 120, Width = 14, Position = UDim2.new(0.5, 0, 0, 46) })
		local portrait = Theme.badge(card, ArtStyle.petIcon(pet.Look), color, 74)
		portrait.AnchorPoint = Vector2.new(0.5, 0)
		portrait.Position = UDim2.new(0.5, 0, 0, 10)
		portrait.ZIndex = 2
		local locked = Theme.badge(card, "lock", C.Gray, 74)
		locked.AnchorPoint = Vector2.new(0.5, 0)
		locked.Position = UDim2.new(0.5, 0, 0, 10)
		locked.ZIndex = 2
		local name = Theme.title(card, pet.Name, 19, color:Lerp(C.White, 0.3))
		name.Position = UDim2.fromOffset(4, 88)
		name.Size = UDim2.new(1, -8, 0, 24)
		local bonus = Theme.title(card, "+" .. math.round(pet.Bonus * 100) .. "% de poder", 13, C.Mint)
		bonus.Position = UDim2.fromOffset(4, 112)
		bonus.Size = UDim2.new(1, -8, 0, 18)
		local button = Theme.action(card, "", C.Blue, { Size = UDim2.new(1, -16, 0, 44), TextSize = 15 })
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.new(0.5, 0, 1, -8)
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
		cards[pet.Id] = { pet = pet, portrait = portrait, locked = locked, button = button, edge = edge, name = name, rays = rays }
	end
	wideAction(body, 3, "IR ATÉ O OVNI DE RESGATE", "pin", C.Violet, function()
		locate("PetShop", "Terminal", "o OVNI de resgate")
	end)

	view.update = function(s)
		for id, entry in pairs(cards) do
			local owned = s.OwnedPets[id] == true
			local equipped = s.EquippedPet == id
			entry.portrait.Visible = owned
			entry.locked.Visible = not owned
			entry.rays.Visible = equipped
			entry.name.Text = owned and entry.pet.Name or "???"
			entry.edge.Color = equipped and C.Gold or C.Ink
			entry.edge.Thickness = equipped and 5 or 3
			if equipped then
				Theme.setText(entry.button, "✔ GUARDAR")
				Theme.setTint(entry.button, C.Gold)
			elseif owned then
				Theme.setText(entry.button, "EQUIPAR")
				Theme.setTint(entry.button, C.Blue)
			else
				Theme.setText(entry.button, "✦ " .. Theme.format(entry.pet.Price) .. " no OVNI")
				Theme.setTint(entry.button, C.Gray)
			end
		end
	end
end

-- ----- Missões de ORBI (dados do servidor) -----
local function buildMissions(body)
	local orbi = sectionWell(body, 1, 104)
	local badge = Theme.badge(orbi, "robot", C.Cyan, 76)
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, 12, 0.5, 0)
	local name = Theme.title(orbi, "ORBI · Assistente de exploração", 19, C.Cyan)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Position = UDim2.fromOffset(100, 10)
	name.Size = UDim2.new(1, -112, 0, 24)
	Theme.fitText(name, 19, 10)
	local bubble = Instance.new("Frame")
	bubble.Position = UDim2.fromOffset(100, 38)
	bubble.Size = UDim2.new(1, -112, 0, 56)
	bubble.BackgroundColor3 = C.Frost
	bubble.BorderSizePixel = 0
	Theme.round(bubble, 14)
	Theme.stroke(bubble, C.Ink, 3)
	bubble.Parent = orbi
	local speech = Theme.label(bubble, "", 13, C.Ink)
	speech.Font = Theme.Font.Label
	speech.Position = UDim2.fromOffset(10, 4)
	speech.Size = UDim2.new(1, -20, 1, -8)
	Theme.fitText(speech, 13, 8)

	local rows = {}
	for index, mission in ipairs(Config.Missions) do
		local row = Instance.new("Frame")
		row.LayoutOrder = index + 1
		row.Size = UDim2.new(1, 0, 0, 74)
		Theme.well(row, 16)
		row.Parent = body
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0, 0.5)
		holder.Position = UDim2.new(0, 10, 0.5, 0)
		holder.Size = UDim2.fromOffset(48, 48)
		holder.Parent = row
		local title = Theme.title(row, index .. ". " .. mission.Title, 17, C.White)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Position = UDim2.fromOffset(68, 8)
		title.Size = UDim2.new(1, -190, 0, 22)
		Theme.fitText(title, 17, 9)
		local detail = Theme.label(row, mission.Goal, 12, C.Muted)
		detail.Font = Theme.Font.Body
		detail.TextXAlignment = Enum.TextXAlignment.Left
		detail.Position = UDim2.fromOffset(68, 30)
		detail.Size = UDim2.new(1, -190, 0, 16)
		Theme.fitText(detail, 12, 8)
		local track = Instance.new("Frame")
		track.Position = UDim2.fromOffset(68, 50)
		track.Size = UDim2.new(1, -190, 0, 12)
		track.Parent = row
		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = C.Cyan
		fill.Size = UDim2.fromScale(0, 1)
		fill.Parent = track
		Theme.meter(track, fill)
		local reward = Theme.title(row, "✦ " .. mission.Credits .. "  ◆ " .. mission.Fragments, 13, C.Gold)
		reward.AnchorPoint = Vector2.new(1, 0)
		reward.Position = UDim2.new(1, -12, 0, 10)
		reward.Size = UDim2.fromOffset(110, 18)
		reward.TextXAlignment = Enum.TextXAlignment.Right
		local status = Theme.title(row, "", 12, C.Ink)
		status.TextStrokeTransparency = 1
		status.AnchorPoint = Vector2.new(1, 1)
		status.Position = UDim2.new(1, -12, 1, -10)
		status.Size = UDim2.fromOffset(104, 24)
		Theme.round(status, 12)
		Theme.stroke(status, C.Ink, 2)
		rows[index] = { holder = holder, track = track, fill = fill, status = status, mission = mission, row = row }
	end

	view.update = function(s)
		local active = Config.Missions[s.MissionIndex]
		speech.Text = active and active.Orbi
			or "Campanha concluída! Você reativou o transmissor. Novos sinais chegarão nas próximas expedições."
		for index, entry in ipairs(rows) do
			local done = index < s.MissionIndex
			local current = index == s.MissionIndex
			local key = done and "done" or current and "active" or "locked"
			if entry.key ~= key then
				entry.key = key
				entry.holder:ClearAllChildren()
				local icon = done and "star" or current and ArtStyle.missionIcon(entry.mission.Kind) or "lock"
				local color = done and C.Mint or current and C.Cyan or C.Gray
				local badge = Theme.badge(entry.holder, icon, color, 48)
				badge.Position = UDim2.fromOffset(0, 0)
			end
			entry.status.Text = done and "✔ CONCLUÍDA" or current and "EM ANDAMENTO" or "BLOQUEADA"
			entry.status.BackgroundColor3 = done and C.Mint or current and C.Gold or C.Gray
			entry.row.BackgroundTransparency = current and 0.1 or 0.35
			local ratio = done and 1 or current and math.clamp(s.MissionProgress / entry.mission.Count, 0, 1) or 0
			if current and entry.mission.Kind == "Transmitter" and s.Level < Config.Progression.CaveLevel then
				ratio = math.clamp(s.Level / Config.Progression.CaveLevel, 0, 1)
			end
			entry.fill.Size = UDim2.fromScale(ratio, 1)
			entry.fill.BackgroundColor3 = done and C.Mint or C.Cyan
		end
	end
end

-- ----- Renascer (o servidor valida custo e reinício) -----
local function buildRebirth(body)
	local hero = sectionWell(body, 1, 150)
	Theme.rays(hero, { Color = C.Pink, Alt = C.Violet, Length = 200, Width = 18, Position = UDim2.new(0, 70, 0.5, 0) })
	local badge = Theme.badge(hero, "rebirth", C.Pink, 96)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.new(0, 70, 0.5, 0)
	badge.ZIndex = 3
	local count = Theme.title(hero, "", 30, C.White)
	count.TextXAlignment = Enum.TextXAlignment.Left
	count.Position = UDim2.fromOffset(136, 12)
	count.Size = UDim2.new(1, -150, 0, 34)
	Theme.fitText(count, 30, 12)
	local bonus = Theme.title(hero, "", 18, C.Mint)
	bonus.RichText = true
	bonus.TextXAlignment = Enum.TextXAlignment.Left
	bonus.Position = UDim2.fromOffset(136, 50)
	bonus.Size = UDim2.new(1, -150, 0, 24)
	Theme.fitText(bonus, 18, 10)
	local track = Instance.new("Frame")
	track.Position = UDim2.fromOffset(136, 84)
	track.Size = UDim2.new(1, -150, 0, 24)
	track.Parent = hero
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = C.Pink
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = track
	Theme.meter(track, fill)
	local cost = Theme.title(track, "", 13, C.White)
	cost.Size = UDim2.fromScale(1, 1)
	cost.ZIndex = 3
	local note = Theme.label(hero, "", 12, C.Muted)
	note.Font = Theme.Font.Body
	note.TextXAlignment = Enum.TextXAlignment.Left
	note.Position = UDim2.fromOffset(136, 114)
	note.Size = UDim2.new(1, -150, 0, 28)
	Theme.fitText(note, 12, 8)

	local columns = Instance.new("Frame")
	columns.LayoutOrder = 2
	columns.BackgroundTransparency = 1
	columns.Size = UDim2.new(1, 0, 0, 150)
	columns.Parent = body
	local function column(x, title, color, lines)
		local box = Instance.new("Frame")
		box.Position = UDim2.new(x, x > 0 and 5 or 0, 0, 0)
		box.Size = UDim2.new(0.5, -5, 1, 0)
		Theme.panel(box, color, 16)
		box.Parent = columns
		local head = Theme.title(box, title, 16, color)
		head.Position = UDim2.fromOffset(12, 8)
		head.Size = UDim2.new(1, -24, 0, 22)
		head.TextXAlignment = Enum.TextXAlignment.Left
		local text = Theme.label(box, table.concat(lines, "\n"), 13, C.Frost)
		text.Font = Theme.Font.Body
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.TextYAlignment = Enum.TextYAlignment.Top
		text.Position = UDim2.fromOffset(12, 34)
		text.Size = UDim2.new(1, -24, 1, -42)
		Theme.fitText(text, 13, 8)
	end
	column(0, "VOCÊ PERDE", C.Red, { "• Créditos e carga", "• Ferramentas compradas", "• Mochilas compradas", "• Treino da sessão" })
	column(0.5, "VOCÊ MANTÉM", C.Mint, { "• Pets resgatados", "• Nível e XP", "• Missões e Fragmentos", "• Bônus de venda (acumula!)" })

	local confirmUntil = 0
	local button = Theme.action(body, "RENASCER", C.Pink, { Size = UDim2.new(1, 0, 0, 60), Icon = "rebirth", TextSize = 24 })
	button.LayoutOrder = 3
	local function paint(s)
		local ready = s.Credits >= s.RebirthCost
		if os.clock() < confirmUntil then
			Theme.setText(button, "TOQUE DE NOVO PARA CONFIRMAR")
			Theme.setTint(button, C.Red)
		else
			Theme.setText(button, ready and "RENASCER" or ("FALTAM ✦ " .. Theme.compact(s.RebirthCost - s.Credits)))
			Theme.setTint(button, ready and C.Pink or C.Gray)
		end
	end
	button.Activated:Connect(function()
		if not state or state.Credits < state.RebirthCost then return end
		if os.clock() < confirmUntil then
			confirmUntil = 0
			remote:FireServer("Rebirth")
		else
			confirmUntil = os.clock() + 4
			task.delay(4.1, function() if state then paint(state) end end)
		end
		paint(state)
	end)

	view.update = function(s)
		local now = math.round((s.SaleMultiplier - 1) * 100)
		local nextBonus = math.round(Config.Rebirth.SaleBonus * 100)
		count.Text = s.Rebirths == 0 and "Nenhum renascimento ainda" or (s.Rebirths .. (s.Rebirths == 1 and " renascimento" or " renascimentos"))
		bonus.Text = string.format("Bônus de venda: +%d%%  →  <font color=\"#FFC531\">+%d%%</font>", now, now + nextBonus)
		local ratio = math.clamp(s.Credits / s.RebirthCost, 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		cost.Text = "✦ " .. Theme.compact(s.Credits) .. " / " .. Theme.compact(s.RebirthCost)
		note.Text = "Renascer reinicia sua partida em troca de um bônus permanente em todas as vendas."
		paint(s)
	end
end

-- ----- Ajustes (salvos no servidor junto com o progresso) -----
-- Envia as preferências com um pequeno atraso: vários toques viram um envio.
local settingsToken = 0
function persistSettings()
	settingsToken += 1
	local token = settingsToken
	task.delay(1.5, function()
		if token ~= settingsToken then return end
		local values = {}
		for _, key in ipairs(Config.ClientSettings) do
			values[key] = playerGui:GetAttribute(key) == true
		end
		remote:FireServer("SaveSettings", values)
	end)
end

local function buildSettings(body)
	local options = {
		{ "Movimento reduzido", "Desliga animações de menus, números e do cenário.", "GalaxyReduceMotion", false, "motion" },
		{ "Sons", "Cliques, golpes e recompensas.", "GalaxyMute", true, "sound" },
		{ "Números de dano", "Mostra o dano de cada golpe acima do minério.", "GalaxyHideDamage", true, "bolt" },
		{ "Placas dos minérios", "Nome, resistência e golpes necessários.", "GalaxyHideOrePlates", true, "gem" },
		{ "Poeira cósmica", "Partículas brilhantes flutuando ao seu redor.", "GalaxyHideDust", true, "sparkle" },
		{ "Guia de objetivo", "Feixe e marcador até o objetivo da missão atual.", "GalaxyHideGuide", true, "pin" },
		{ "Efeitos do cenário", "Galáxia, animações e decoração dos minérios. Desligue em aparelhos lentos.",
			"GalaxyLowGraphics", true, "star" },
	}
	for index, option in ipairs(options) do
		local attribute, inverted = option[3], option[4]
		local current = playerGui:GetAttribute(attribute) == true
		local row = Theme.toggle(body, option[1], option[2], if inverted then not current else current, function(value)
			playerGui:SetAttribute(attribute, if inverted then not value else value)
			persistSettings()
		end, option[5])
		row.LayoutOrder = index
	end
	local keys = sectionWell(body, 20, 66)
	local text = Theme.label(keys,
		"Atalhos  ·  L Loja  ·  B Mochila  ·  M Missões  ·  R Renascer  ·  P Ajustes\nNo controle, B fecha a janela aberta.", 13, C.Frost)
	text.Font = Theme.Font.Body
	text.Position = UDim2.fromOffset(14, 4)
	text.Size = UDim2.new(1, -28, 1, -8)
	Theme.fitText(text, 13, 9)
end

local function render()
	if state and view.update then
		view.update(state)
	end
end

local function clear(parts)
	for _, container in ipairs({ parts.Content, parts.Tabs }) do
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end
	end
	table.clear(view)
end

local function openMenu(name)
	if name == "Loja" then
		-- A loja tem interface própria (Shop.client.luau).
		closeMenu(function()
			playerGui:SetAttribute("GalaxyShopRequest", os.clock())
		end)
		return
	end
	if playerGui:GetAttribute("GalaxyShopOpen") or playerGui:GetAttribute("GalaxyHangarOpen") then return end
	if currentMenu and currentMenu ~= name then
		-- Troca de menu: fecha o atual e abre o pedido em seguida.
		closeMenu(function() openMenu(name) end)
		return
	end
	local parts = getWindow(name)
	if parts.Closing then return end
	local wasOpen = parts.Overlay.Visible
	currentMenu = name
	clear(parts)
	local body = parts.Content
	body.CanvasPosition = Vector2.zero
	local hasTabs = name == "Mochila"
	parts.Tabs.Visible = hasTabs
	body.Position = UDim2.fromOffset(0, hasTabs and 54 or 0)
	body.Size = UDim2.new(1, 0, 1, hasTabs and -54 or 0)
	if hasTabs then
		for index, tab in ipairs({ { "Minérios", "gem" }, { "Pets", "pet" } }) do
			local active = backpackTab == tab[1]
			local button = Theme.action(parts.Tabs, string.upper(tab[1]), active and C.Cyan or C.Plum,
				{ Size = UDim2.new(0.5, -5, 1, 0), Icon = tab[2], TextSize = 19 })
			button.Position = UDim2.new((index - 1) * 0.5, index == 1 and 0 or 5, 0, 0)
			button.Activated:Connect(function()
				if backpackTab ~= tab[1] then
					backpackTab = tab[1]
					openMenu("Mochila")
				end
			end)
		end
		if backpackTab == "Minérios" then buildOres(body) else buildPets(body) end
	elseif name == "Missões" then
		buildMissions(body)
	elseif name == "Renascer" then
		buildRebirth(body)
	elseif name == "Configurações" then
		buildSettings(body)
	end
	render()
	if not wasOpen then
		playerGui:SetAttribute("GalaxyMenuOpen", true)
		Theme.openWindow(parts)
	end
	if isGamepad() then
		task.defer(function()
			local first = parts.Tabs:FindFirstChildWhichIsA("TextButton") or body:FindFirstChildWhichIsA("TextButton", true)
			if first then GuiService.SelectedObject = first end
		end)
	end
end

local function toggleMenu(name)
	if currentMenu == name and windows[name] and windows[name].Overlay.Visible then
		closeMenu()
	else
		openMenu(name)
	end
end

goalButton.Activated:Connect(function()
	if goalMode == "full" then
		locate("SaleStation", "Counter", "a Estação de Venda")
	else
		toggleMenu("Loja")
	end
end)

local buttons = {}
for index, entry in ipairs({
	{ "shop", "Loja", C.Gold, "L" },
	{ "pack", "Mochila", C.Cyan, "B" },
	{ "mission", "Missões", C.Violet, "M" },
	{ "rebirth", "Renascer", C.Pink, "R" },
	{ "settings", "Ajustes", C.Mint, "P" },
}) do
	local target = entry[2] == "Ajustes" and "Configurações" or entry[2]
	local button = Theme.navigationAction(navigation, entry[2], entry[1], entry[3], entry[4])
	button.LayoutOrder = index
	button.Activated:Connect(function() toggleMenu(target) end)
	buttons[index] = button
end

-- Outros scripts pedem um menu com o atributo GalaxyMenuRequest = "Nome#marca".
playerGui:GetAttributeChangedSignal("GalaxyMenuRequest"):Connect(function()
	local request = tostring(playerGui:GetAttribute("GalaxyMenuRequest") or "")
	local name = request:match("^([^#]+)")
	if name and windowStyles[name] and not playerGui:GetAttribute("GalaxyShopOpen")
		and not playerGui:GetAttribute("GalaxyHangarOpen") then
		openMenu(name)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	-- B do controle fecha a janela mesmo quando a navegação de interface já usou a tecla.
	if input.KeyCode == Enum.KeyCode.ButtonB and currentMenu then
		closeMenu()
		return
	end
	if processed or UserInputService:GetFocusedTextBox() then return end
	-- Janelas próprias (loja e hangar) bloqueiam os atalhos da HUD.
	if playerGui:GetAttribute("GalaxyShopOpen") or playerGui:GetAttribute("GalaxyHangarOpen") then return end
	local shortcuts = {
		[Enum.KeyCode.L] = "Loja",
		[Enum.KeyCode.B] = "Mochila",
		[Enum.KeyCode.M] = "Missões",
		[Enum.KeyCode.P] = "Configurações",
		[Enum.KeyCode.R] = "Renascer",
	}
	local target = shortcuts[input.KeyCode]
	-- Sem menu da HUD aberto, a própria loja trata a tecla L.
	if target == "Loja" and not currentMenu then return end
	if target then toggleMenu(target) end
end)

-- ---------- Layout responsivo ----------
local wideLayout = true
local function layout()
	local size = gui.AbsoluteSize
	local wide = size.X >= 900 and size.Y >= 520
	wideLayout = wide
	navigation.AnchorPoint = wide and Vector2.new(0, 0.5) or Vector2.new(0.5, 0)
	navigation.Position = wide and UDim2.new(0, 14, 0.5, 0) or UDim2.new(0.5, 0, 0, 74)
	navigation.Size = wide and UDim2.fromOffset(182, 278) or UDim2.new(1, -24, 0, 60)
	navGrid.CellSize = wide and UDim2.fromOffset(86, 86) or UDim2.new(1 / #buttons, -8, 1, 0)
	navGrid.CellPadding = UDim2.fromOffset(10, 10)
	for _, button in ipairs(buttons) do
		local hint = button:FindFirstChild("KeyHint")
		if hint then hint.Visible = wide and not UserInputService.TouchEnabled end
		local face = button:FindFirstChild("Face")
		local icon = face and face:FindFirstChild("Illustration")
		local iconScale = icon and icon:FindFirstChild("IconScale")
		if iconScale then iconScale.Scale = wide and 1.45 or 0.95 end
	end
	toasts.AnchorPoint = Vector2.new(0.5, 0)
	toasts.Position = wide and UDim2.new(0.5, 0, 0, 108) or UDim2.new(0.5, 0, 0, 234)
	toasts.Size = UDim2.new(1, -40, 0, 160)
	local toastLimit = toasts:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint", toasts)
	toastLimit.MaxSize = Vector2.new(400, 160)

	-- Cartão de meta: completo à direita (tela larga) ou compacto no topo.
	goalCard.AnchorPoint = wide and Vector2.new(1, 0.5) or Vector2.new(0.5, 0)
	goalCard.Position = wide and UDim2.new(1, -14, 0.5, 30) or UDim2.new(0.5, 0, 0, 176)
	goalCard.Size = wide and UDim2.fromOffset(250, 178) or UDim2.new(1, -24, 0, 62)
	local cardLimit = goalCard:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint", goalCard)
	cardLimit.MaxSize = Vector2.new(wide and 250 or 420, 178)
	goalHeader.Visible = wide
	goalButton.Visible = wide
	goalHeader.Position = UDim2.fromOffset(14, 8)
	goalHeader.Size = UDim2.new(1, -28, 0, 18)
	goalBadgeHolder.Position = wide and UDim2.fromOffset(12, 30) or UDim2.fromOffset(6, 5)
	local left = wide and 74 or 62
	goalName.Position = UDim2.fromOffset(left, wide and 32 or 6)
	goalName.Size = UDim2.new(1, -(left + 10), 0, 22)
	goalDetail.Position = UDim2.fromOffset(left, wide and 54 or 26)
	goalDetail.Size = UDim2.new(1, -(left + 10), 0, 14)
	goalTrack.Position = wide and UDim2.fromOffset(14, 90) or UDim2.fromOffset(left, 42)
	goalTrack.Size = wide and UDim2.new(1, -28, 0, 20) or UDim2.new(1, -(left + 12), 0, 14)
	goalButton.AnchorPoint = Vector2.new(0.5, 1)
	goalButton.Position = UDim2.new(0.5, 0, 1, -12)

	-- Pílulas: ícones menores em telas estreitas.
	local compact = currencies.AbsoluteSize.X < 470
	currencyLayout.Padding = UDim.new(0, compact and 18 or 24)
	for _, entry in ipairs(pills) do
		local badgeSize = compact and 44 or 56
		entry.badge.Size = UDim2.fromOffset(badgeSize, badgeSize)
		entry.badge.Position = UDim2.new(0, compact and -14 or -18, 0.5, 0)
		local icon = entry.badge:FindFirstChild("Illustration")
		local scale = icon and icon:FindFirstChildOfClass("UIScale")
		if scale then scale.Scale = (badgeSize * 0.72) / 32 end
		local inset = compact and 34 or 44
		entry.caption.Position = UDim2.fromOffset(inset, 5)
		entry.caption.Size = UDim2.new(1, -(inset + 8), 0, 12)
		entry.value.Position = UDim2.fromOffset(inset, 16)
		entry.value.Size = UDim2.new(1, -(inset + 8), 0, 26)
		if entry.track then
			entry.track.Position = UDim2.new(0, inset, 1, -11)
			entry.track.Size = UDim2.new(1, -(inset + 14), 0, 7)
		end
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
currencies:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()

local function updateGoal(s)
	local full = s.Weight >= s.Capacity
	local goal = nextGoal(s)
	local key
	if full then
		goalMode = "full"
		key = "full"
		goalHeader.Text = "MOCHILA CHEIA!"
		goalHeader.TextColor3 = C.Red
		goalName.Text = "Hora de vender!"
		goalDetail.Text = "Leve os minérios à Estação de Venda"
		goalAmount.Text = Theme.format(s.Weight) .. " / " .. Theme.format(s.Capacity)
		goalFill.BackgroundColor3 = C.Red
		goalFill.Size = UDim2.fromScale(1, 1)
		goalStroke.Color = C.Red
		Theme.setText(goalButton, "IR VENDER")
		Theme.setTint(goalButton, C.Red)
	elseif goal then
		goalMode = "goal"
		key = goal.Id
		goalHeader.Text = "PRÓXIMA META"
		goalHeader.TextColor3 = C.Gold
		goalName.Text = goal.Name
		goalDetail.Text = goal.Detail
		local ratio = math.clamp(s.Credits / goal.Price, 0, 1)
		goalAmount.Text = ratio >= 1 and "PRONTO PARA COMPRAR!"
			or ("✦ " .. Theme.compact(s.Credits) .. " / " .. Theme.compact(goal.Price))
		goalFill.BackgroundColor3 = ratio >= 1 and C.Mint or C.Gold
		Theme.tween(goalFill, Theme.Motion.Enter, { Size = UDim2.fromScale(ratio, 1) })
		goalStroke.Color = ratio >= 1 and C.Mint or C.Ink
		Theme.setText(goalButton, ratio >= 1 and "COMPRAR AGORA" or "ABRIR LOJA")
		Theme.setTint(goalButton, ratio >= 1 and C.Mint or C.Gold)
	else
		goalMode = "goal"
		key = "done"
		goalHeader.Text = "COLEÇÃO COMPLETA"
		goalName.Text = "Tudo comprado!"
		goalDetail.Text = "Você é uma lenda de Terra Nova"
		goalAmount.Text = "100%"
		goalFill.Size = UDim2.fromScale(1, 1)
		goalFill.BackgroundColor3 = C.Gold
	end
	if key ~= goalBadgeKey then
		goalBadgeKey = key
		if goalBadge then goalBadge:Destroy() end
		local kind = full and "pack" or goal and goal.Icon or "star"
		local color = full and C.Red or goal and goal.Color or C.Gold
		goalBadge = Theme.badge(goalBadgeHolder, kind, color, 52)
		Theme.pop(goalCard, 0.06)
	end
	-- Em telas estreitas o cartão só aparece quando a mochila enche.
	goalCard.Visible = wideLayout or full
end

-- ---------- Boas-vindas (depois da tela de carregamento) ----------
task.spawn(function()
	local waited = 0
	while playerGui:FindFirstChild("GalaxyLoading") and waited < 20 do
		waited += task.wait(0.2)
	end
	local title = Theme.title(stage, "TERRA NOVA", 64, C.Gold)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.3)
	title.Size = UDim2.new(1, -40, 0, 74)
	Theme.fitText(title, 64, 26)
	local subtitle = Theme.title(stage, "Planeta inicial  ·  Galáxia de Asterion", 22, C.Cyan)
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.Position = UDim2.new(0.5, 0, 0.3, 40)
	subtitle.Size = UDim2.new(1, -40, 0, 28)
	Theme.fitText(subtitle, 22, 12)
	local scale = Instance.new("UIScale")
	scale.Parent = title
	if not Theme.reducedMotion(title) then
		scale.Scale = 0.4
		TweenService:Create(scale, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	task.delay(3.5, function()
		local fade = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, label in ipairs({ title, subtitle }) do
			Theme.tween(label, fade, { TextTransparency = 1, TextStrokeTransparency = 1 })
		end
		Debris:AddItem(title, 1.4)
		Debris:AddItem(subtitle, 1.4)
	end)
end)

-- ---------- Celebração de resgate de pet ----------
local function celebrate(petId)
	local pet = findPet(petId)
	if not pet then return end
	local color = Color3.fromHex(pet.Color)
	Sound.play("reward", 1.2)
	Theme.confetti(stage, 60)
	local holder = Instance.new("Frame")
	holder.Name = "PetReveal"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.45)
	holder.Size = UDim2.fromOffset(360, 360)
	holder.BackgroundTransparency = 1
	holder.Parent = stage
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	Theme.rays(holder, { Color = color, Alt = C.Gold, Length = 380, Width = 30, Count = 10,
		Position = UDim2.fromScale(0.5, 0.4), Transparency = 0.45 })
	local portrait = Theme.badge(holder, ArtStyle.petIcon(pet.Look), color, 140)
	portrait.AnchorPoint = Vector2.new(0.5, 0.5)
	portrait.Position = UDim2.fromScale(0.5, 0.4)
	portrait.ZIndex = 3
	local headline = Theme.title(holder, "PET RESGATADO!", 40, C.Gold)
	headline.AnchorPoint = Vector2.new(0.5, 0)
	headline.Position = UDim2.new(0.5, 0, 0.4, 82)
	headline.Size = UDim2.fromOffset(460, 46)
	headline.ZIndex = 4
	local detail = Theme.title(holder, pet.Name .. "  ·  +" .. math.round(pet.Bonus * 100) .. "% de poder  ·  Equipado", 20, C.White)
	detail.AnchorPoint = Vector2.new(0.5, 0)
	detail.Position = UDim2.new(0.5, 0, 0.4, 128)
	detail.Size = UDim2.fromOffset(460, 26)
	detail.ZIndex = 4
	if not Theme.reducedMotion(holder) then
		scale.Scale = 0.2
		TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	task.delay(3, function()
		if Theme.reducedMotion(holder) then
			holder:Destroy()
			return
		end
		local out = TweenService:Create(scale, Theme.Motion.Exit, { Scale = 0 })
		out.Completed:Once(function() holder:Destroy() end)
		out:Play()
	end)
end

-- ---------- Estado vindo do servidor ----------
local displayedCredits = Instance.new("NumberValue")
displayedCredits.Changed:Connect(function(value)
	creditsPill.value.Text = Theme.compact(math.floor(value + 0.5))
end)
local creditsTween
local fullPulse
local cargoRatio
local lastCredits

local function setFill(fill, ratio)
	Theme.tween(fill, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1),
	})
end

local settingsApplied = false
remote.OnClientEvent:Connect(function(snapshot)
	local previous = state
	state = snapshot
	-- Primeira mensagem: aplica as preferências salvas (só chaves conhecidas).
	if not settingsApplied and snapshot.Settings then
		settingsApplied = true
		for _, key in ipairs(Config.ClientSettings) do
			if snapshot.Settings[key] ~= nil then
				playerGui:SetAttribute(key, snapshot.Settings[key] == true)
			end
		end
	end

	-- Créditos: contagem animada e "+N" flutuante nos ganhos.
	if lastCredits == nil or Theme.reducedMotion(gui) then
		if creditsTween then creditsTween:Cancel() end
		displayedCredits.Value = snapshot.Credits
		creditsPill.value.Text = Theme.compact(snapshot.Credits)
	elseif snapshot.Credits ~= lastCredits then
		if creditsTween then creditsTween:Cancel() end
		creditsTween = TweenService:Create(displayedCredits, Theme.Motion.Count, { Value = snapshot.Credits })
		creditsTween:Play()
		Theme.pop(creditsPill.frame, 0.12)
		local delta = snapshot.Credits - lastCredits
		floatFrom(creditsPill, (delta > 0 and "+" or "") .. Theme.format(delta), delta > 0 and C.Gold or C.Red)
		if delta > 0 then Sound.play("reward") end
	end
	lastCredits = snapshot.Credits

	-- Carga: medidor, aviso de mochila cheia e coletas.
	local full = snapshot.Weight >= snapshot.Capacity
	cargoPill.value.Text = Theme.compact(snapshot.Weight) .. "/" .. Theme.compact(snapshot.Capacity)
	cargoPill.value.TextColor3 = full and C.Red or C.White
	cargoPill.caption.Text = full and "CARGA · CHEIA!" or "CARGA"
	cargoPill.caption.TextColor3 = full and C.Red or C.Cyan:Lerp(C.White, 0.2)
	local ratio = snapshot.Capacity > 0 and snapshot.Weight / snapshot.Capacity or 0
	if ratio ~= cargoRatio then
		cargoRatio = ratio
		setFill(cargoFill, ratio)
	end
	cargoFill.BackgroundColor3 = full and C.Red or ratio >= 0.8 and C.Amber or C.Cyan
	if full and not fullPulse and not Theme.reducedMotion(gui) then
		fullPulse = TweenService:Create(cargoStroke,
			TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Color = C.Red })
		fullPulse:Play()
	elseif not full and fullPulse then
		fullPulse:Cancel()
		fullPulse = nil
		cargoStroke.Color = C.Ink
	end
	if previous then
		for _, entry in ipairs(oreList) do
			local gained = (snapshot.Items[entry.id] or 0) - (previous.Items[entry.id] or 0)
			if gained > 0 then
				floatFrom(cargoPill, "+" .. gained .. " " .. entry.ore.Name, entry.color:Lerp(C.White, 0.2))
				Theme.pop(cargoPill.frame, 0.07)
			end
		end
	end

	-- Poder: valor total e progresso do treino até o limite da mochila.
	powerPill.value.Text = Theme.format(snapshot.Power)
	local maxed = snapshot.TrainingPower >= snapshot.PowerCap
	powerPill.caption.Text = string.format("PODER · TREINO +%d/%d", snapshot.TrainingPower, snapshot.PowerCap)
	setFill(trainingFill, maxed and 1 or snapshot.TrainingClicks / Config.TrainingClicksPerPoint)
	trainingFill.BackgroundColor3 = maxed and C.Gold or C.Violet
	if previous and snapshot.Power > previous.Power then
		Theme.pop(powerPill.frame, 0.14)
	end

	playerGui:SetAttribute("GalaxyToolName", snapshot.ToolName)
	-- Poder atual para as placas dos minérios (apresentação; o servidor calcula o dano).
	playerGui:SetAttribute("GalaxyPower", snapshot.Power)
	updateGoal(snapshot)

	-- Notificações: coletas já aparecem no contador; a loja mostra as próprias mensagens.
	if snapshot.PetReveal then
		celebrate(snapshot.PetReveal)
	elseif snapshot.Message and snapshot.Tone ~= "pickup" and not playerGui:GetAttribute("GalaxyShopOpen") then
		notify(snapshot.Message, snapshot.Tone)
	end
	render()
end)
remote:FireServer()
