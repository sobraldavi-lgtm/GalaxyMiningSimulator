-- Loja Orion v5: janela com categorias e grade de cartões 3D.
-- O cliente só apresenta e pede ações; saldo, preços e posse são validados no servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Theme = require(script.Parent.VisualTheme)
local Sound = require(script.Parent.Sound)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local remote = ReplicatedStorage:WaitForChild("InventoryState")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = Theme.Color

-- ---------- Catálogo (derivado da configuração compartilhada) ----------
local categories = {
	{ Id = "Backpacks", Name = "Mochilas", Icon = "pack", Accent = C.Violet },
	{ Id = "Tools", Name = "Ferramentas", Icon = "drill", Accent = C.Cyan },
	{ Id = "Pets", Name = "Pets", Icon = "pet", Accent = C.Mint },
}

local items = {}
for index, backpack in ipairs(Config.Backpacks) do
	table.insert(items, {
		Id = backpack.Id, Category = "Backpacks", Kind = "Backpack", Order = index,
		Name = backpack.Name, Color = Color3.fromHex(backpack.Color), Icon = "pack",
		Price = backpack.Price, Capacity = backpack.Capacity, PowerCap = backpack.PowerCap,
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
		Name = entry.upgrade.Name, Color = Color3.fromHex(entry.upgrade.Color or "#22E1FF"), Icon = "drill",
		Price = entry.upgrade.Price, Power = entry.upgrade.Power,
	})
end
local petBonus = {}
for index, pet in ipairs(Config.Pets) do
	petBonus[pet.Id] = pet.Bonus
	table.insert(items, {
		Id = pet.Id, Category = "Pets", Kind = "Pet", Order = index,
		Name = pet.Name, Color = Color3.fromHex(pet.Color), Icon = "pet",
		Price = pet.Price, Bonus = pet.Bonus,
	})
end

-- ---------- Janela ----------
local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyShop"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local shop = Theme.window(gui, "LOJA ORION", { MaxSize = Vector2.new(860, 520), Accent = C.Gold, Icon = "shop" })
local header = shop.Header
local body = shop.Body

-- Saldo no cabeçalho
local pill = Instance.new("Frame")
pill.AnchorPoint = Vector2.new(1, 0.5)
pill.Position = UDim2.new(1, -62, 0.5, 0)
pill.Size = UDim2.fromOffset(170, 38)
pill.BackgroundColor3 = C.Ink
pill.BackgroundTransparency = 0.15
pill.BorderSizePixel = 0
pill.ZIndex = 3
Theme.round(pill, 19)
Theme.stroke(pill, C.Ink, 3)
pill.Parent = header
local coin = Theme.badge(pill, "coin", C.Gold, 42)
coin.AnchorPoint = Vector2.new(0, 0.5)
coin.Position = UDim2.new(0, -10, 0.5, 0)
local creditsLabel = Theme.title(pill, "0", 22, C.Gold)
creditsLabel.TextXAlignment = Enum.TextXAlignment.Left
creditsLabel.Position = UDim2.fromOffset(38, 0)
creditsLabel.Size = UDim2.new(1, -46, 1, 0)
Theme.fitText(creditsLabel, 22, 10)
shop.Title.Size = UDim2.new(1, -300, 1, -4)

-- Categorias
local sidebar = Instance.new("Frame")
sidebar.BackgroundTransparency = 1
sidebar.Size = UDim2.new(0, 112, 1, 0)
sidebar.Parent = body
local sideList = Instance.new("UIListLayout")
sideList.Padding = UDim.new(0, 12)
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Parent = sidebar

-- Grade de itens
local panel = Instance.new("Frame")
panel.Position = UDim2.fromOffset(124, 0)
panel.Size = UDim2.new(1, -124, 1, -42)
Theme.well(panel, 18)
panel.Parent = body

local scroller = Instance.new("ScrollingFrame")
scroller.BackgroundTransparency = 1
scroller.BorderSizePixel = 0
scroller.Size = UDim2.fromScale(1, 1)
scroller.CanvasSize = UDim2.new()
scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroller.ScrollBarThickness = 6
scroller.ScrollBarImageColor3 = C.Frost
scroller.Parent = panel
Theme.padding(scroller, 10)
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(156, 226)
grid.CellPadding = UDim2.fromOffset(12, 12)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.Parent = scroller

-- Faixa inferior: mensagem do servidor ou dica
local toast = Instance.new("Frame")
toast.AnchorPoint = Vector2.new(0, 1)
toast.Position = UDim2.new(0, 124, 1, 0)
toast.Size = UDim2.new(1, -124, 0, 34)
toast.Visible = false
Theme.panel(toast, C.Gold, 17)
local toastStroke = toast:FindFirstChildOfClass("UIStroke")
toast.Parent = body
local toastText = Theme.title(toast, "", 15, C.Gold)
toastText.Position = UDim2.fromOffset(12, 0)
toastText.Size = UDim2.new(1, -24, 1, 0)
Theme.fitText(toastText, 15, 9)

local hint = Theme.label(body, "Compras no balcão da Loja Orion  ·  pets no OVNI de resgate", 12, C.Muted)
hint.Font = Theme.Font.Body
hint.AnchorPoint = Vector2.new(0, 1)
hint.Position = UDim2.new(0, 124, 1, 0)
hint.Size = UDim2.new(1, -124, 0, 34)
Theme.fitText(hint, 12, 8)

-- ---------- Estado ----------
local state
local selected = "Backpacks"
local cards = {}
local tabs = {}
local toastId = 0
local toneColors = { success = C.Mint, error = C.Red, warning = C.Amber, sale = C.Gold }

local function say(message, tone)
	toastId += 1
	local id = toastId
	local color = toneColors[tone] or C.Gold
	toastText.Text = message
	toastText.TextColor3 = color
	toastStroke.Color = color
	toast.Visible = true
	hint.Visible = false
	Theme.pop(toast, 0.08)
	if tone == "success" then
		Sound.play("reward", 1.1)
		Theme.confetti(gui, 30)
	end
	task.delay(2.8, function()
		if id == toastId then
			toast.Visible = false
			hint.Visible = true
		end
	end)
end

local function textLine(parent, y, size, color)
	local label = Theme.label(parent, "", size, color)
	label.Font = Theme.Font.Display
	label.TextStrokeTransparency = 0.2
	label.Position = UDim2.fromOffset(6, y)
	label.Size = UDim2.new(1, -12, 0, size + 4)
	label.RichText = true
	Theme.fitText(label, size, 8)
	return label
end

-- Cartão 3D: base escura + face colorida que recebe o conteúdo.
local function makeCard(item)
	local card = Instance.new("Frame")
	card.Name = item.Id
	card.LayoutOrder = item.Order
	card.BackgroundTransparency = 1
	local base = Instance.new("Frame")
	base.Name = "Base"
	base.Size = UDim2.fromScale(1, 1)
	base.BackgroundColor3 = item.Color:Lerp(C.Ink, 0.6)
	base.BorderSizePixel = 0
	base.ZIndex = 1
	Theme.round(base, 18)
	Theme.stroke(base, C.Ink, 3)
	base.Parent = card
	local face = Instance.new("Frame")
	face.Name = "Face"
	face.Size = UDim2.new(1, 0, 1, -6)
	face.BackgroundColor3 = Color3.new(1, 1, 1)
	face.BorderSizePixel = 0
	face.ZIndex = 2
	Theme.round(face, 18)
	local edge = Theme.stroke(face, C.Ink, 3)
	Theme.gradient(face, item.Color:Lerp(C.White, 0.15):Lerp(C.Royal, 0.35), item.Color:Lerp(C.Ink, 0.7))
	face.Parent = card

	local rays = Theme.rays(face, { Color = item.Color:Lerp(C.White, 0.4), Alt = C.Gold, Length = 130, Width = 14,
		Position = UDim2.new(0.5, 0, 0, 62), Transparency = 0.55 })
	rays.Visible = false

	local number = Theme.title(face, "Nº " .. item.Order, 11, C.White)
	number.BackgroundColor3 = C.Ink
	number.BackgroundTransparency = 0.3
	number.Position = UDim2.fromOffset(7, 7)
	number.Size = UDim2.fromOffset(38, 18)
	number.ZIndex = 3
	Theme.round(number, 9)

	local ribbon = Theme.title(face, "PRÓXIMA", 11, C.Ink)
	ribbon.TextStrokeTransparency = 1
	ribbon.BackgroundColor3 = C.Gold
	ribbon.AnchorPoint = Vector2.new(1, 0)
	ribbon.Position = UDim2.new(1, -7, 0, 7)
	ribbon.Size = UDim2.fromOffset(68, 18)
	ribbon.Visible = false
	ribbon.ZIndex = 3
	Theme.round(ribbon, 9)
	Theme.stroke(ribbon, C.Ink, 2)

	local badge = Theme.badge(face, item.Icon, item.Color:Lerp(C.White, 0.2), 76)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.new(0.5, 0, 0, 62)
	badge.ZIndex = 2

	local name = Theme.title(face, item.Name, 16, C.White)
	name.Position = UDim2.fromOffset(4, 104)
	name.Size = UDim2.new(1, -8, 0, 22)
	Theme.fitText(name, 16, 9)

	local primary = textLine(face, 128, 14, C.White)
	local secondary = textLine(face, 147, 12, C.Muted)

	-- Progresso até poder comprar (só quando falta saldo).
	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 12, 1, -60)
	track.Size = UDim2.new(1, -24, 0, 8)
	track.Visible = false
	track.Parent = face
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = C.Gold
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = track
	Theme.meter(track, fill)

	local button = Theme.action(face, "", C.Blue, { Size = UDim2.new(1, -16, 0, 42), TextSize = 17, Radius = 12 })
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -8)
	button.ZIndex = 3

	-- Brilho abaixo do botão para não cobrir o preço.
	local shimmer = Theme.shimmer(face, 18)
	shimmer.ZIndex = 2
	shimmer.Visible = false

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
	return {
		item = item, frame = card, button = button, edge = edge, ribbon = ribbon, rays = rays, shimmer = shimmer,
		primary = primary, secondary = secondary, track = track, fill = fill,
	}
end

-- Diferença em relação ao equipamento atual, em verde quando melhora.
local function delta(value, current, suffix)
	local difference = value - current
	if difference == 0 then return "" end
	local color = difference > 0 and "#5CFF9D" or "#FF7A85"
	return string.format(' <font color="%s">(%s%s%s)</font>', color, difference > 0 and "+" or "-",
		Theme.format(math.abs(difference)), suffix or "")
end

local function isOwned(item)
	if not state then return false end
	if item.Kind == "Backpack" then return state.OwnedBackpacks[item.Id] == true end
	if item.Kind == "Pet" then return state.OwnedPets[item.Id] == true end
	return state.OwnedUpgrades[item.Id] == true or (item.Power ~= nil and item.Power <= state.ToolPower)
end

-- Primeiro item ainda não obtido da categoria: a "próxima" meta do jogador.
local function nextGoal(category)
	local best
	for _, card in ipairs(cards) do
		local item = card.item
		if item.Category == category and not isOwned(item) and (not best or item.Order < best.item.Order) then
			best = card
		end
	end
	return best
end

local function refresh()
	creditsLabel.Text = Theme.compact(state and state.Credits or 0)
	local goal = nextGoal(selected)
	local currentBonus = state and state.EquippedPet and petBonus[state.EquippedPet] or 0
	for _, card in ipairs(cards) do
		local item = card.item
		card.frame.Visible = item.Category == selected
		if state and card.frame.Visible then
			local text, color
			local highlight = false
			if item.Kind == "Backpack" then
				card.primary.Text = "Carga " .. Theme.format(item.Capacity) .. delta(item.Capacity, state.Capacity)
				card.secondary.Text = "Treino máx. +" .. item.PowerCap .. delta(item.PowerCap, state.PowerCap)
				if state.BackpackId == item.Id then
					text, color, highlight = "✔ EQUIPADA", C.Gold, true
				elseif state.OwnedBackpacks[item.Id] then
					text, color = "EQUIPAR", C.Blue
				end
			elseif item.Kind == "Pet" then
				card.primary.Text = "+" .. math.round(item.Bonus * 100) .. "% de poder"
					.. delta(math.round(item.Bonus * 100), math.round(currentBonus * 100), "%")
				card.secondary.Text = "Companheiro"
				if state.EquippedPet == item.Id then
					text, color, highlight = "✔ GUARDAR", C.Gold, true
				elseif state.OwnedPets[item.Id] then
					text, color = "EQUIPAR", C.Blue
				end
			else
				card.primary.Text = "Poder " .. Theme.format(item.Power) .. delta(item.Power, state.ToolPower)
				card.secondary.Text = "Ferramenta"
				if state.OwnedUpgrades[item.Id] then
					local current = state.ToolPower == item.Power
					text, color, highlight = current and "✔ EM USO" or "✔ ADQUIRIDA", C.Gold, current
				elseif item.Power <= state.ToolPower then
					text, color = "SUPERADA", C.Gray
				end
			end
			local affordable = state.Credits >= item.Price
			if not text then
				text = item.Price == 0 and "GRÁTIS" or ("✦ " .. Theme.compact(item.Price))
				color = affordable and C.Mint or C.Gray
			end
			Theme.setText(card.button, text)
			Theme.setTint(card.button, color)
			local isGoal = card == goal
			card.ribbon.Visible = isGoal
			card.shimmer.Visible = isGoal or highlight
			card.rays.Visible = isGoal or highlight
			card.edge.Color = highlight and C.Gold or isGoal and C.White or C.Ink
			card.edge.Thickness = (highlight or isGoal) and 4 or 3
			local showProgress = not highlight and not isOwned(item) and not affordable
			card.track.Visible = showProgress
			if showProgress then
				card.fill.Size = UDim2.fromScale(math.clamp(state.Credits / math.max(item.Price, 1), 0, 1), 1)
			end
		end
	end
	for id, tab in pairs(tabs) do
		Theme.setTint(tab.button, id == selected and tab.accent or tab.accent:Lerp(C.Plum, 0.65))
		if state then
			local owned, total = 0, 0
			for _, card in ipairs(cards) do
				if card.item.Category == id then
					total += 1
					local item = card.item
					local has = (item.Kind == "Backpack" and state.OwnedBackpacks[item.Id])
						or (item.Kind == "Pet" and state.OwnedPets[item.Id])
						or (item.Kind == "Tool" and state.OwnedUpgrades[item.Id])
					if has then owned += 1 end
				end
			end
			tab.count.Text = owned .. "/" .. total
		end
	end
end

-- Rola a grade até a próxima meta depois que o layout se ajusta.
local function scrollToGoal()
	scroller.CanvasPosition = Vector2.zero
	local goal = nextGoal(selected)
	if not goal then return end
	task.defer(function()
		local offset = goal.frame.AbsolutePosition.Y - scroller.AbsolutePosition.Y + scroller.CanvasPosition.Y
		scroller.CanvasPosition = Vector2.new(0, math.max(0, offset - 14))
	end)
end

for _, item in ipairs(items) do
	table.insert(cards, makeCard(item))
end
for index, category in ipairs(categories) do
	local button = Theme.navigationAction(sidebar, category.Name, category.Icon, category.Accent)
	button.LayoutOrder = index
	button.Size = UDim2.new(1, 0, 0, 92)
	local face = button:FindFirstChild("Face")
	local icon = face and face:FindFirstChild("Illustration")
	local iconScale = icon and icon:FindFirstChild("IconScale")
	if iconScale then iconScale.Scale = 1.5 end
	local count = Theme.title(button, "", 12, C.Ink)
	count.Name = "Count"
	count.TextStrokeTransparency = 1
	count.BackgroundColor3 = C.Frost
	count.AnchorPoint = Vector2.new(1, 0)
	count.Position = UDim2.new(1, 6, 0, -6)
	count.Size = UDim2.fromOffset(44, 20)
	count.ZIndex = 10
	Theme.round(count, 10)
	Theme.stroke(count, C.Ink, 2)
	tabs[category.Id] = { button = button, accent = category.Accent, count = count }
	button.Activated:Connect(function()
		selected = category.Id
		refresh()
		scrollToGoal()
	end)
end

-- ---------- Abrir / fechar ----------
local function open()
	if shop.Overlay.Visible or playerGui:GetAttribute("GalaxyMenuOpen") then return end
	playerGui:SetAttribute("GalaxyMenuOpen", true)
	playerGui:SetAttribute("GalaxyShopOpen", true)
	toast.Visible = false
	hint.Visible = true
	refresh()
	Theme.openWindow(shop)
	scrollToGoal()
	if UserInputService:GetLastInputType().Name:match("^Gamepad") then
		task.defer(function()
			GuiService.SelectedObject = tabs[selected] and tabs[selected].button or nil
		end)
	end
end

local function close()
	Theme.closeWindow(shop, function()
		playerGui:SetAttribute("GalaxyShopOpen", false)
		playerGui:SetAttribute("GalaxyMenuOpen", false)
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then
			GuiService.SelectedObject = nil
		end
	end)
end

shop.Close.Activated:Connect(close)
shop.Overlay.Activated:Connect(close)
-- A tecla L abre e fecha a loja; com um menu da HUD aberto, a HUD faz a troca.
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.ButtonB and shop.Overlay.Visible then
		close()
	elseif input.KeyCode == Enum.KeyCode.L and not processed and not UserInputService:GetFocusedTextBox() then
		if shop.Overlay.Visible then
			close()
		elseif not playerGui:GetAttribute("GalaxyMenuOpen") then
			open()
		end
	end
end)
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
	if shop.Overlay.Visible then
		refresh()
		if snapshot.Message and snapshot.Tone ~= "pickup" and snapshot.Tone ~= "power" then
			say(snapshot.Message, snapshot.Tone)
		end
	end
end)

refresh()
