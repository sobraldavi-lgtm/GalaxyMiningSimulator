-- Loja Orion: janela com categorias e grade de itens (estilo loja de simulador).
-- O cliente só apresenta e pede ações; saldo, preços e posse são validados no servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Theme = require(script.Parent.VisualTheme)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local remote = ReplicatedStorage:WaitForChild("InventoryState")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = Theme.Color

-- ---------- Catálogo (derivado da configuração compartilhada) ----------
local categories = {
	{ Id = "Backpacks", Name = "Mochilas", Icon = "pack", Accent = C.Violet },
	{ Id = "Tools", Name = "Ferramentas", Icon = "drill", Accent = C.Cyan },
	{ Id = "Pets", Name = "Pets", Icon = "pet", Accent = C.Green },
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
		Name = entry.upgrade.Name, Color = Color3.fromHex(entry.upgrade.Color or "#00D8FF"), Icon = "drill",
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

local shop = Theme.window(gui, "LOJA ORION", { MaxSize = Vector2.new(820, 500) })
local window = shop.Window
local body = shop.Body

-- Saldo
local pill = Instance.new("Frame")
pill.Position = UDim2.fromOffset(14, 14)
pill.Size = UDim2.fromOffset(160, 38)
pill.BackgroundColor3 = C.Deep
pill.BorderSizePixel = 0
pill.ZIndex = 3
Theme.round(pill, 19)
Theme.stroke(pill, C.Gold, 2)
pill.Parent = window
local coin = Theme.badge(pill, "coin", C.Gold, 30)
coin.AnchorPoint = Vector2.new(0, 0.5)
coin.Position = UDim2.new(0, 4, 0.5, 0)
local creditsLabel = Theme.label(pill, "0", 20, C.Gold)
creditsLabel.Font = Theme.Font.Display
creditsLabel.TextXAlignment = Enum.TextXAlignment.Left
creditsLabel.Position = UDim2.fromOffset(40, 0)
creditsLabel.Size = UDim2.new(1, -48, 1, 0)
Theme.fitText(creditsLabel, 20, 10)

-- Categorias
local sidebar = Instance.new("Frame")
sidebar.BackgroundTransparency = 1
sidebar.Size = UDim2.new(0, 108, 1, 0)
sidebar.Parent = body
local sideList = Instance.new("UIListLayout")
sideList.Padding = UDim.new(0, 10)
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Parent = sidebar

-- Grade de itens
local panel = Instance.new("Frame")
panel.Position = UDim2.fromOffset(118, 0)
panel.Size = UDim2.new(1, -118, 1, -40)
Theme.well(panel)
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
Theme.padding(scroller, 8)
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(150, 212)
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.Parent = scroller

-- Mensagem de retorno do servidor (faixa inferior)
local toast = Instance.new("Frame")
toast.AnchorPoint = Vector2.new(0, 1)
toast.Position = UDim2.new(0, 118, 1, 0)
toast.Size = UDim2.new(1, -118, 0, 32)
toast.BackgroundColor3 = C.Deep
toast.BackgroundTransparency = 0.3
toast.BorderSizePixel = 0
toast.Visible = false
Theme.round(toast, 10)
local toastStroke = Theme.stroke(toast, C.Gold, 2)
toast.Parent = body
local toastText = Theme.label(toast, "", 14, C.Gold)
toastText.Position = UDim2.fromOffset(10, 0)
toastText.Size = UDim2.new(1, -20, 1, 0)
Theme.fitText(toastText, 14, 9)

local hint = Theme.label(body, "Compras só no balcão da Loja Orion · pets no OVNI de resgate", 12, C.Muted)
hint.Font = Theme.Font.Body
hint.AnchorPoint = Vector2.new(0, 1)
hint.Position = UDim2.new(0, 118, 1, 0)
hint.Size = UDim2.new(1, -118, 0, 32)
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
	task.delay(2.8, function()
		if id == toastId then
			toast.Visible = false
			hint.Visible = true
		end
	end)
end

local function textLine(parent, y, size, color)
	local label = Theme.label(parent, "", size, color)
	label.Position = UDim2.fromOffset(6, y)
	label.Size = UDim2.new(1, -12, 0, size + 4)
	label.RichText = true
	Theme.fitText(label, size, 8)
	return label
end

local function makeCard(item)
	local card = Instance.new("Frame")
	card.Name = item.Id
	card.LayoutOrder = item.Order
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.BorderSizePixel = 0
	Theme.round(card, 14)
	local edge = Theme.stroke(card, C.Deep, 3)
	Theme.gradient(card, item.Color:Lerp(Color3.new(1, 1, 1), 0.3), item.Color:Lerp(C.Deep, 0.65))

	local number = Theme.label(card, "Nº " .. item.Order, 10, C.Frost)
	number.Font = Theme.Font.Display
	number.BackgroundColor3 = C.Deep
	number.BackgroundTransparency = 0.35
	number.Position = UDim2.fromOffset(6, 6)
	number.Size = UDim2.fromOffset(34, 16)
	Theme.round(number, 8)

	local ribbon = Theme.label(card, "PRÓXIMA", 10, C.Navy)
	ribbon.Font = Theme.Font.Display
	ribbon.BackgroundColor3 = C.Gold
	ribbon.AnchorPoint = Vector2.new(1, 0)
	ribbon.Position = UDim2.new(1, -6, 0, 6)
	ribbon.Size = UDim2.fromOffset(62, 16)
	ribbon.Visible = false
	Theme.round(ribbon, 8)

	local badge = Theme.badge(card, item.Icon, item.Color:Lerp(Color3.new(1, 1, 1), 0.2), 62)
	badge.AnchorPoint = Vector2.new(0.5, 0)
	badge.Position = UDim2.new(0.5, 0, 0, 26)

	local name = Theme.label(card, item.Name, 15, Color3.new(1, 1, 1))
	name.Font = Theme.Font.Display
	name.TextStrokeTransparency = 0
	name.Position = UDim2.fromOffset(4, 92)
	name.Size = UDim2.new(1, -8, 0, 22)
	Theme.fitText(name, 15, 9)

	local primary = textLine(card, 116, 13, C.Text)
	local secondary = textLine(card, 134, 11, C.Frost)

	-- Progresso até poder comprar (só quando falta saldo).
	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 10, 1, -54)
	track.Size = UDim2.new(1, -20, 0, 6)
	track.Visible = false
	track.Parent = card
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = C.Gold
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = track
	Theme.meter(track, fill)

	local button = Theme.action(card, "", C.Blue)
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -8)
	button.Size = UDim2.new(1, -16, 0, 36)
	button.Font = Theme.Font.Display
	Theme.fitText(button, 16, 9)

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
		item = item, frame = card, button = button, edge = edge, ribbon = ribbon,
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
			card.button.Text = text
			Theme.setTint(card.button, color)
			card.ribbon.Visible = card == goal
			card.edge.Color = highlight and C.Gold or card == goal and C.Frost or C.Deep
			card.edge.Thickness = (highlight or card == goal) and 4 or 3
			local showProgress = not text:find("✔") and not isOwned(item) and not affordable
			card.track.Visible = showProgress
			if showProgress then
				card.fill.Size = UDim2.fromScale(math.clamp(state.Credits / math.max(item.Price, 1), 0, 1), 1)
			end
		end
	end
	for id, tab in pairs(tabs) do
		local edge = tab.button:FindFirstChildOfClass("UIStroke")
		edge.Color = id == selected and Color3.new(1, 1, 1) or tab.accent
		edge.Thickness = id == selected and 4 or 2
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
		scroller.CanvasPosition = Vector2.new(0, math.max(0, offset - 12))
	end)
end

for _, item in ipairs(items) do
	table.insert(cards, makeCard(item))
end
for index, category in ipairs(categories) do
	local button = Theme.navigationAction(sidebar, category.Name, category.Icon, category.Accent)
	button.LayoutOrder = index
	button.Size = UDim2.new(1, 0, 0, 72)
	local count = Theme.label(button, "", 11, C.Navy)
	count.Name = "Count"
	count.Font = Theme.Font.Display
	count.BackgroundColor3 = C.Frost
	count.AnchorPoint = Vector2.new(1, 0)
	count.Position = UDim2.new(1, 4, 0, -4)
	count.Size = UDim2.fromOffset(40, 18)
	count.ZIndex = 5
	Theme.round(count, 9)
	Theme.stroke(count, C.Deep, 2)
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
