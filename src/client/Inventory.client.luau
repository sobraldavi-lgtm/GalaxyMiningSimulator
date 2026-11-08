local Theme = require(script.Parent.VisualTheme)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local remote = ReplicatedStorage:WaitForChild("InventoryState")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = playerGui

local function surface(parent, name, accent)
	local frame = Instance.new("Frame")
	frame.Name = name
	Theme.panel(frame, accent)
	frame.Parent = parent
	return frame
end

local header = Instance.new("Frame", gui)
header.Name = "Telemetry"
header.BackgroundTransparency = 1
header.AnchorPoint = Vector2.new(0.5, 0)
header.Position = UDim2.new(0.5, 0, 0, 8)
header.Size = UDim2.new(1, -24, 0, 52)
Instance.new("UISizeConstraint", header).MaxSize = Vector2.new(384, 52)
local counters = Instance.new("UIListLayout", header)
counters.FillDirection = Enum.FillDirection.Horizontal
counters.SortOrder = Enum.SortOrder.LayoutOrder
counters.Padding = UDim.new(0, 6)

local function counter(order, name, accent)
	local tile = surface(header, name, accent)
	tile.LayoutOrder = order
	tile.Size = UDim2.new(1 / 3, -4, 1, 0)
	local padding = Instance.new("UIPadding", tile)
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)
	local caption = Theme.label(tile, name, 11, accent)
	caption.Position = UDim2.fromOffset(0, 5)
	caption.Size = UDim2.new(1, 0, 0, 14)
	local value = Theme.label(tile, "…", 18)
	value.Font = Theme.Font.Display
	value.Position = UDim2.fromOffset(0, 19)
	value.Size = UDim2.new(1, 0, 0, 20)
	value.TextScaled = true
	Instance.new("UITextSizeConstraint", value).MaxTextSize = 18
	return tile, value
end

local _, credits = counter(1, "CRÉDITOS", Theme.Color.Amber)
local cargo, capacity = counter(2, "CARGA", Theme.Color.Cyan)
local powerTile, power = counter(3, "PODER", Theme.Color.Violet)
local track = Instance.new("Frame", cargo)
track.Position = UDim2.new(0.08, 0, 0, 45)
track.Size = UDim2.new(0.84, 0, 0, 3)
local fill = Instance.new("Frame", track)
fill.BackgroundColor3 = Theme.Color.Cyan
fill.Size = UDim2.fromScale(0, 1)
Theme.meter(track, fill)
local training = Theme.label(powerTile, "", 9, Theme.Color.Cyan)
training.Position = UDim2.fromOffset(0, 39)
training.Size = UDim2.new(1, 0, 0, 12)

local navigation = Instance.new("Frame", gui)
navigation.BackgroundTransparency = 1
local navLayout = Instance.new("UIListLayout", navigation)
navLayout.Padding = UDim.new(0, 6)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UISizeConstraint", navigation).MaxSize = Vector2.new(660, 300)

local notice = Theme.label(gui, "", 13, Theme.Color.Amber)
notice.BackgroundColor3 = Theme.Color.Navy
notice.BackgroundTransparency = 0.12
Theme.round(notice, 8)
notice.AnchorPoint = Vector2.new(0.5, 0)
notice.Size = UDim2.new(1, -24, 0, 32)
Instance.new("UISizeConstraint", notice).MaxSize = Vector2.new(480, 32)
notice.Visible = false

local overlay = Instance.new("Frame", gui)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.38
overlay.Size = UDim2.fromScale(1, 1)
overlay.Active = true
overlay.Visible = false
overlay.ZIndex = 3

local shadow = Instance.new("Frame", overlay)
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 7)
shadow.Size = UDim2.new(0.92, 0, 0.86, 0)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.38
shadow.ZIndex = 3
Theme.round(shadow, 14)
Instance.new("UISizeConstraint", shadow).MaxSize = Vector2.new(480, 430)

local card = Instance.new("Frame", overlay)
card.Name = "Menu"
Theme.sheet(card)
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.new(0.92, 0, 0.86, 0)
card.ZIndex = 4
card.Active = true
Instance.new("UISizeConstraint", card).MaxSize = Vector2.new(480, 430)
local title = Theme.label(card, "", 24, Theme.Color.Navy)
title.Font = Theme.Font.Display
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -112, 0, 44)
title.ZIndex = 5
local close = Theme.action(card, "Fechar")
close.Position = UDim2.new(1, -90, 0, 8)
close.Size = UDim2.fromOffset(78, 44)
close.ZIndex = 5
local body = Instance.new("ScrollingFrame", card)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.Position = UDim2.fromOffset(12, 62)
body.Size = UDim2.new(1, -24, 1, -74)
body.CanvasSize = UDim2.fromOffset(0, 0)
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.ScrollBarThickness = 4
body.ZIndex = 5
local rows = Instance.new("UIListLayout", body)
rows.Padding = UDim.new(0, 8)
rows.SortOrder = Enum.SortOrder.LayoutOrder

local state
local marker
local toastId = 0
local menuTween
local closing = false
local function notify(message)
	toastId += 1
	local id = toastId
	notice.Text = message
	notice.Visible = true
	task.delay(3, function()
		if id == toastId then notice.Visible = false end
	end)
end

local function hideMenu()
	overlay.Visible = false
	playerGui:SetAttribute("GalaxyMenuOpen", false)
	closing = false
end

local function closeMenu()
	if closing or not overlay.Visible then return end
	closing = true
	if menuTween then menuTween:Cancel() end
	if Theme.reducedMotion(card) then
		hideMenu()
		return
	end
	menuTween = TweenService:Create(card, Theme.Motion.Exit, {
		Position = UDim2.new(0.5, 0, 0.5, 12),
	})
	menuTween.Completed:Once(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed then hideMenu() end
	end)
	menuTween:Play()
end
close.Activated:Connect(closeMenu)

local function locate(groupName, partName)
	local world = workspace:FindFirstChild("TerraNova")
	local group = world and world:FindFirstChild(groupName)
	local target = group and group:FindFirstChild(partName)
	if not target then
		notify("Terminal fora da área carregada. Aproxime-se e tente novamente.")
		return
	end
	if marker then marker:Destroy() end
	local highlight = Instance.new("Highlight")
	highlight.Adornee = target
	highlight.FillColor = Theme.Color.Cyan
	highlight.OutlineColor = Theme.Color.Cyan
	highlight.FillTransparency = 0.72
	highlight.Parent = target
	marker = highlight
	game:GetService("Debris"):AddItem(highlight, 18)
	closeMenu()
	notify("Siga o destaque ciano e use o terminal presencial.")
end

local infoLabels = {}
local motionButton
local backpackTab = "Minérios"
local oreList = {}
for id, ore in pairs(Config.Ores) do
	table.insert(oreList, { id = id, ore = ore })
end
table.sort(oreList, function(a, b) return a.ore.Value < b.ore.Value end)
local petCards = {}
local function renderState()
	if not state then return end
	if infoLabels.inventory then
		local lines = {}
		for _, entry in ipairs(oreList) do
			local count = state.Items[entry.id] or 0
			if count > 0 then
				table.insert(lines, entry.ore.Name .. "  ×" .. count)
			end
		end
		if #lines == 0 then lines[1] = "Nenhum minério na mochila." end
		table.insert(lines, string.format("Carga: %d / %d", state.Weight, state.Capacity))
		table.insert(lines, state.ToolName .. "  •  " .. state.BackpackName)
		infoLabels.inventory.Text = table.concat(lines, "\n")
	elseif infoLabels.emptyPets then
		local hasPets = false
		for _, petCard in ipairs(petCards) do
			local pet = petCard.pet
			local owned = state.OwnedPets[pet.Id] == true
			local equipped = state.EquippedPet == pet.Id
			petCard.frame.Visible = owned
			petCard.status.Text = equipped and "EQUIPADO" or "GUARDADO"
			petCard.button.Text = equipped and "Guardar" or "Equipar"
			hasPets = hasPets or owned
		end
		infoLabels.emptyPets.Text = "Nenhum pet na coleção. Visite o OVNI para resgatar seu primeiro pet."
		infoLabels.emptyPets.Visible = not hasPets
	end
end

local function openMenu(name)
	if closing then return end
	if name == "Loja" then
		-- A loja tem interface própria (Shop.client.luau).
		playerGui:SetAttribute("GalaxyShopRequest", os.clock())
		return
	end
	title.Text = name
	body.CanvasPosition = Vector2.zero
	for _, child in ipairs(body:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	table.clear(infoLabels)
	table.clear(petCards)
	local order = 0
	local function row(text, action, height)
		order += 1
		local item = action and Theme.action(body, text) or Theme.label(body, text, 15, Theme.Color.Navy)
		item.LayoutOrder = order
		item.ZIndex = 6
		item.Size = UDim2.new(1, -9, 0, height or 50)
		if action then item.Activated:Connect(action) end
		return item
	end
	if name == "Mochila" then
		local tabs = Instance.new("Frame", body)
		tabs.BackgroundTransparency = 1
		tabs.Size = UDim2.new(1, -9, 0, 44)
		tabs.ZIndex = 6
		for index, tab in ipairs({ "Minérios", "Pets" }) do
			local button = Theme.action(tabs, (backpackTab == tab and "◆ " or "") .. tab)
			button.Position = UDim2.new((index - 1) * 0.5, 0, 0, 0)
			button.Size = UDim2.new(0.5, -4, 1, 0)
			button.ZIndex = 7
			button.Activated:Connect(function()
				if backpackTab ~= tab then
					backpackTab = tab
					openMenu("Mochila")
				end
			end)
		end
		if backpackTab == "Minérios" then
			infoLabels.inventory = row("Carregando inventário…", nil, 98)
			row("Localizar Estação de Venda", function() locate("SaleStation", "Counter") end)
		else
			infoLabels.emptyPets = row("Carregando coleção…", nil, 62)
			for _, pet in ipairs(Config.Pets) do
				order += 1
				local frame = surface(body, pet.Name, Theme.Color.Violet)
				frame.Size = UDim2.new(1, -9, 0, 132)
				frame.LayoutOrder = order
				frame.ZIndex = 6
				frame.Visible = false
				local nameLabel = Theme.label(frame, "✦  " .. pet.Name .. "  •  +" .. math.round(pet.Bonus * 100) .. "% de poder", 15, Color3.fromHex(pet.Color))
				nameLabel.Size = UDim2.new(1, -12, 0, 42)
				nameLabel.Position = UDim2.fromOffset(6, 4)
				nameLabel.ZIndex = 7
				local status = Theme.label(frame, "", 12, Theme.Color.Amber)
				status.Position = UDim2.fromOffset(0, 47)
				status.Size = UDim2.new(1, 0, 22)
				status.ZIndex = 7
				local button = Theme.action(frame, "Equipar")
				button.Position = UDim2.fromOffset(10, 77)
				button.Size = UDim2.new(1, -20, 0, 44)
				button.ZIndex = 7
				button.Activated:Connect(function()
					if state and state.OwnedPets[pet.Id] then
						if state.EquippedPet == pet.Id then
							remote:FireServer("UnequipPet")
						else
							remote:FireServer("EquipPet", pet.Id)
						end
					end
				end)
				table.insert(petCards, { pet = pet, frame = frame, status = status, button = button })
			end
			row("Localizar OVNI de resgate", function() locate("PetShop", "Terminal") end)
		end
	elseif name == "Missões" then
		row("ORBI  /  Indisponível\nAs missões ainda não estão disponíveis nesta versão.", nil, 76)
		row("Nível, XP e Fragmentos Estelares ainda indisponíveis.", nil, 50)
	elseif name == "Configurações" then
		local function motionText()
			return "Movimento reduzido  •  " .. (playerGui:GetAttribute("GalaxyReduceMotion") and "Ligado" or "Desligado")
		end
		motionButton = row(motionText(), function()
			playerGui:SetAttribute("GalaxyReduceMotion", not playerGui:GetAttribute("GalaxyReduceMotion"))
			motionButton.Text = motionText()
		end)
		row("Reduz animações da interface nesta sessão.", nil, 48)
	end
	renderState()
	overlay.Visible = true
	playerGui:SetAttribute("GalaxyMenuOpen", true)
	card.Position = UDim2.fromScale(0.5, 0.5)
	if menuTween then menuTween:Cancel() end
	if not Theme.reducedMotion(card) then
		card.Position = UDim2.new(0.5, 0, 0.5, 10)
		menuTween = TweenService:Create(card, Theme.Motion.Enter, { Position = UDim2.fromScale(0.5, 0.5) })
		menuTween:Play()
	end
end

local buttons = {}
for index, entry in ipairs({
	{ "shop", "Loja", Theme.Color.Amber },
	{ "pack", "Mochila", Theme.Color.Cyan },
	{ "mission", "Missões", Theme.Color.Violet },
	{ "settings", "Configurações", Theme.Color.Green },
}) do
	local button = Theme.navigationAction(navigation, entry[2], entry[1], entry[3])
	button.LayoutOrder = index
	button.Activated:Connect(function() openMenu(entry[2]) end)
	buttons[index] = button
end

local function layout()
	local wide = gui.AbsoluteSize.X >= 900 and gui.AbsoluteSize.Y >= 550
	navigation.AnchorPoint = wide and Vector2.new(0, 0.5) or Vector2.new(0.5, 0)
	navigation.Position = wide and UDim2.new(0, 12, 0.5, 0) or UDim2.new(0.5, 0, 0, 68)
	navigation.Size = wide and UDim2.fromOffset(86, 250) or UDim2.new(1, -24, 0, 52)
	navLayout.FillDirection = wide and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
	for _, button in ipairs(buttons) do
		button.Size = wide and UDim2.new(1, 0, 0, 56) or UDim2.new(1 / #buttons, -5, 1, 0)
	end
	notice.AnchorPoint = wide and Vector2.new(1, 1) or Vector2.new(0.5, 0)
	notice.Position = wide and UDim2.new(1, -12, 1, -18) or UDim2.new(0.5, 0, 0, 125)
	notice.Size = wide and UDim2.fromOffset(240, 40) or UDim2.new(1, -24, 0, 32)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()

local weightTween
local displayedRatio
remote.OnClientEvent:Connect(function(snapshot)
	state = snapshot
	credits.Text = tostring(snapshot.Credits)
	local progress = snapshot.TrainingPower >= snapshot.PowerCap and "MÁX."
		or string.format("%d/%d", snapshot.TrainingClicks, Config.TrainingClicksPerPoint)
	power.Text = tostring(snapshot.Power)
	training.Text = string.format("+%d/%d  ·  %s", snapshot.TrainingPower, snapshot.PowerCap, progress)
	capacity.Text = string.format("%d/%d%s", snapshot.Weight, snapshot.Capacity,
		snapshot.Weight >= snapshot.Capacity and " CHEIA" or "")
	playerGui:SetAttribute("GalaxyToolName", snapshot.ToolName)
	local ratio = math.clamp(snapshot.Weight / snapshot.Capacity, 0, 1)
	if ratio ~= displayedRatio then
		displayedRatio = ratio
		if weightTween then weightTween:Cancel() end
		local size = UDim2.fromScale(ratio, 1)
		if playerGui:GetAttribute("GalaxyReduceMotion") then
			fill.Size = size
		else
			weightTween = TweenService:Create(fill, TweenInfo.new(0.18), { Size = size })
			weightTween:Play()
		end
	end
	fill.BackgroundColor3 = ratio >= 1 and Theme.Color.Amber or Theme.Color.Cyan
	if snapshot.PetReveal then
		notify("✦  " .. string.upper(tostring(snapshot.PetReveal)) .. " RESGATADO  •  Equipado")
	elseif snapshot.Message then
		notify(snapshot.Message)
	end
	renderState()
end)
remote:FireServer()
