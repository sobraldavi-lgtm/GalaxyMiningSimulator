local Theme = require(script.Parent.VisualTheme)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MiningRequest")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))

local gui = Instance.new("ScreenGui")
gui.Name = "MiningHUD"
gui.ResetOnSpawn = false
local playerGui = player:WaitForChild("PlayerGui")
gui.Parent = playerGui

local C = Theme.Color
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local panel = Instance.new("Frame")
panel.Name = "MiningPanel"
panel.Active = true
panel.Visible = false
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -14)
panel.Size = UDim2.new(0.8, 0, 0, 86)
Theme.panel(panel)
panel.Parent = gui
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(400, 140)
constraint.Parent = panel
local panelStroke = panel:FindFirstChildOfClass("UIStroke")

-- Distintivo com a cor do minério selecionado (recriado ao trocar de minério).
local oreBadge
local badgeColor
local function setBadge(color)
	if badgeColor == color and oreBadge then return end
	badgeColor = color
	if oreBadge then oreBadge:Destroy() end
	oreBadge = Theme.badge(panel, "gem", color, 54)
	oreBadge.Position = UDim2.fromOffset(10, 14)
end
setBadge(C.Gray)

local title = Theme.label(panel, "Selecione um minério", 17, C.Cyan)
title.Font = Theme.Font.Display
title.TextStrokeTransparency = 0.2
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.fromOffset(74, 6)
title.Size = UDim2.new(1, -84, 0, 22)
Theme.fitText(title, 17, 11)

local track = Instance.new("Frame")
track.Position = UDim2.fromOffset(74, 30)
track.Size = UDim2.new(1, -86, 0, 18)
track.Parent = panel
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = C.Cyan
fill.Parent = track
Theme.meter(track, fill)
local hpText = Theme.label(track, "", 13)
hpText.Font = Theme.Font.Display
hpText.TextStrokeTransparency = 0
hpText.Size = UDim2.fromScale(1, 1)
hpText.ZIndex = 3

local tool = Theme.label(panel, "", 12, C.Amber)
tool.TextXAlignment = Enum.TextXAlignment.Left
tool.Position = UDim2.fromOffset(74, 50)
tool.Size = UDim2.new(1, -84, 0, 15)
Theme.fitText(tool, 12, 8)
local function updateTool()
	local name = playerGui:GetAttribute("GalaxyToolName")
	tool.Text = name and ("Ferramenta: " .. name) or "Carregando ferramenta…"
end
playerGui:GetAttributeChangedSignal("GalaxyToolName"):Connect(updateTool)
updateTool()

local status = Theme.label(panel, "Mire em um depósito", 12, C.Frost)
status.Font = Theme.Font.Body
status.TextXAlignment = Enum.TextXAlignment.Left
status.Position = UDim2.fromOffset(74, 66)
status.Size = UDim2.new(1, -84, 0, 15)
Theme.fitText(status, 12, 8)

local touchButton = Theme.action(panel, "◆  MINERAR", C.Blue)
touchButton.Font = Theme.Font.Display
touchButton.TextSize = 20
touchButton.AnchorPoint = Vector2.new(0.5, 1)
touchButton.Position = UDim2.new(0.5, 0, 1, -8)
touchButton.Size = UDim2.new(1, -20, 0, 44)
local function layout()
	local touch = UserInputService.TouchEnabled
	touchButton.Visible = touch
	panel.Size = touch and UDim2.new(0.56, 0, 0, 140) or UDim2.new(0.8, 0, 0, 86)
end
layout()

-- As instruções de mineração ficam na HUD. Oculta apenas as placas
-- redundantes neste cliente, inclusive quando entram por streaming.
local function hideMiningSign(object)
	if not object:IsA("BillboardGui") then return end
	local anchor = object.Parent
	local folder = anchor and anchor.Parent
	local parent = folder and folder.Parent
	if not parent then return end
	local zoneSign = anchor.Name == "MiningSign" and folder.Name == "MiningAreas"
		and parent.Name == "TerraNova" and parent.Parent == workspace
	local depositSign = anchor.Name == "Name" and parent.Name == "OreDeposits"
		and parent.Parent and parent.Parent.Name == "TerraNova" and parent.Parent.Parent == workspace
	if zoneSign or depositSign then object.Enabled = false end
end
workspace.DescendantAdded:Connect(hideMiningSign)
local world = workspace:FindFirstChild("TerraNova")
if world then
	for _, object in ipairs(world:GetDescendants()) do
		hideMiningSign(object)
	end
end

local function updateMenuVisibility()
	gui.Enabled = not playerGui:GetAttribute("GalaxyMenuOpen")
end
playerGui:GetAttributeChangedSignal("GalaxyMenuOpen"):Connect(updateMenuVisibility)
updateMenuVisibility()

-- Retículo para seleção no centro da tela com controle.
local crosshair = Instance.new("TextLabel")
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(24, 24)
crosshair.BackgroundTransparency = 1
crosshair.Text = "+"
crosshair.TextSize = 24
crosshair.TextColor3 = Color3.new(1, 1, 1)
crosshair.Visible = UserInputService.GamepadEnabled
crosshair.Parent = gui
UserInputService.LastInputTypeChanged:Connect(function(inputType)
	crosshair.Visible = inputType.Name:match("^Gamepad") ~= nil
end)

local outlines = {}
for index = 1, 2 do
	local outline = Instance.new("Highlight")
	outline.Name = "MiningSelection" .. index
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.FillTransparency = 0.92
	outline.OutlineTransparency = 0.1
	outline.Enabled = false
	outline.Parent = workspace
	outlines[index] = outline
end
local activeBase
local activePiece
local remainingByBase = {}
local messageUntil = 0
local barTween
local cyan = Theme.Color.Cyan
local orange = Theme.Color.Amber

local function setBar(remaining, maximum)
	if barTween then
		barTween:Cancel()
	end
	local ratio = maximum > 0 and math.clamp(remaining / maximum, 0, 1) or 0
	hpText.Text = maximum > 1 and (Theme.format(remaining) .. " / " .. Theme.format(maximum)) or ""
	local color = ratio <= 0.3 and orange or cyan
	if playerGui:GetAttribute("GalaxyReduceMotion") then
		fill.Size = UDim2.fromScale(ratio, 1)
		fill.BackgroundColor3 = color
		return
	end
	barTween = TweenService:Create(fill, TweenInfo.new(0.12), {
		Size = UDim2.fromScale(ratio, 1),
		BackgroundColor3 = color,
	})
	barTween:Play()
end

-- Clarão rápido no contorno do depósito a cada golpe aceito.
local function flashOutline()
	if playerGui:GetAttribute("GalaxyReduceMotion") then return end
	for _, outline in ipairs(outlines) do
		if outline.Enabled then
			outline.FillTransparency = 0.45
			TweenService:Create(outline, TweenInfo.new(0.25), { FillTransparency = 0.92 }):Play()
		end
	end
end

local function selectPiece(piece)
	local definition = piece and Config.Ores[piece:GetAttribute("OreType")]
	local index = piece and piece:GetAttribute("DepositIndex")
	local base = definition and index ~= nil and piece.Parent:FindFirstChild("Base" .. index) or nil
	local changed = base ~= activeBase
	activeBase = base
	activePiece = piece
	panel.Visible = base ~= nil or os.clock() < messageUntil
	if not base then
		for _, outline in ipairs(outlines) do
			outline.Enabled = false
		end
		if changed then
			title.Text = "Selecione um minério"
			title.TextColor3 = cyan
			setBadge(C.Gray)
			setBar(0, 1)
		end
		if os.clock() > messageUntil then
			status.Text = "Mire em um depósito"
		end
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local inRange = root ~= nil and (root.Position - piece.Position).Magnitude <= Config.Reach
	local color = inRange and cyan or orange
	local sample = piece.Parent:FindFirstChild("Sample" .. index)
	for outlineIndex, part in ipairs({ base, sample }) do
		local outline = outlines[outlineIndex]
		outline.Adornee = part
		outline.OutlineColor = color
		outline.FillColor = color
		outline.Enabled = true
	end
	if changed then
		local remaining = remainingByBase[base] or definition.Resistance
		local oreColor = Color3.fromHex(definition.Color or "#FFFFFF")
		title.Text = definition.Name
		title.TextColor3 = oreColor:Lerp(Color3.new(1, 1, 1), 0.25)
		setBadge(oreColor)
		setBar(remaining, definition.Resistance)
	end
	panelStroke.Color = inRange and cyan:Lerp(C.Deep, 0.35) or orange
	if os.clock() > messageUntil then
		status.Text = inRange and "Clique, toque ou use R2 para minerar"
			or "Fora de alcance • aproxime-se"
	end
end

local function findTarget(screenPosition, useViewport)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local ray
	if useViewport then
		ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	else
		local inset = GuiService:GetGuiInset()
		ray = camera:ViewportPointToRay(screenPosition.X - inset.X, screenPosition.Y - inset.Y)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	if hit and hit.Instance:GetAttribute("Mineable") then
		return hit.Instance
	end
	return nil
end

local lastSent = -math.huge
local function requestAction(action, piece)
	if playerGui:GetAttribute("GalaxyMenuOpen") then return end
	if os.clock() - lastSent >= Config.HitInterval then
		lastSent = os.clock()
		remote:FireServer(action, piece)
	end
end

local function mine(screenPosition, useViewport)
	local piece = findTarget(screenPosition, useViewport)
	selectPiece(piece)
	requestAction(piece and "Hit" or "Practice", piece)
end

touchButton.Activated:Connect(function()
	if activePiece and activePiece:IsDescendantOf(workspace) then
		requestAction("HitOnly", activePiece)
	else
		status.Text = "Toque em um depósito primeiro."
		messageUntil = os.clock() + 1.5
	end
end)

-- Seleção local a 10 Hz: mirar em um depósito não envia mensagens pela rede.
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.1 then
		return
	end
	elapsed = 0
	panel.Visible = activeBase ~= nil or os.clock() < messageUntil
	local inputType = UserInputService:GetLastInputType()
	if playerGui:GetAttribute("GalaxyMenuOpen") then return end
	if GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then
		selectPiece(nil)
		return
	end
	if crosshair.Visible then
		local camera = workspace.CurrentCamera
		if camera then
			local inset = GuiService:GetGuiInset()
			crosshair.Position = UDim2.fromOffset(camera.ViewportSize.X / 2 - inset.X, camera.ViewportSize.Y / 2 - inset.Y)
			selectPiece(findTarget(camera.ViewportSize / 2, true))
		end
	elseif inputType == Enum.UserInputType.MouseMovement or inputType == Enum.UserInputType.MouseButton1 then
		selectPiece(findTarget(UserInputService:GetMouseLocation(), false))
	elseif activePiece and activePiece.Parent then
		selectPiece(activePiece)
	end
end)

player.CharacterAdded:Connect(function()
	selectPiece(nil)
	-- Resistência e inventário do servidor são preservados após renascer.
end)

local function overHud(position)
	local inset = GuiService:GetGuiInset()
	local point = position - inset
	for _, object in ipairs(playerGui:GetGuiObjectsAtPosition(point.X, point.Y)) do
		if object ~= crosshair then
			return true
		end
	end
	return false
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox()
		or playerGui:GetAttribute("GalaxyMenuOpen") then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local position = UserInputService:GetMouseLocation()
		if not overHud(position) then mine(position, false) end
	elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
		local camera = workspace.CurrentCamera
		if camera and not GuiService.SelectedObject then
			mine(camera.ViewportSize / 2, true)
		end
	end
end)
-- TouchTap evita minerar ao arrastar a câmera ou usar o controle de movimento.
UserInputService.TouchTap:Connect(function(positions, processed)
	if not processed and #positions == 1 and not GuiService.MenuIsOpen and not overHud(positions[1])
		and not playerGui:GetAttribute("GalaxyMenuOpen") then
		mine(positions[1], false)
	end
end)

remote.OnClientEvent:Connect(function(result)
	if result.Name and result.Target then
		-- Uma resposta atrasada não altera a barra de outro depósito selecionado.
		remainingByBase[result.Target] = result.Remaining == 0 and result.Maximum or result.Remaining
		if activeBase == result.Target then
			local ready = remainingByBase[result.Target]
			setBar(ready, result.Maximum)
			flashOutline()
		end
		local target = result.Target
		if target and target.Parent then
			-- Fragmentos no impacto; mais intensos ao quebrar o minério.
			local burst = Instance.new("ParticleEmitter")
			burst.Texture = "rbxasset://textures/particles/sparkles_main.dna"
			burst.Color = ColorSequence.new(target.Color)
			burst.LightEmission = 0.8
			burst.Lifetime = NumberRange.new(0.3, 0.6)
			burst.Speed = NumberRange.new(8, 16)
			burst.SpreadAngle = Vector2.new(180, 180)
			burst.Size = NumberSequence.new(result.Remaining == 0 and 0.9 or 0.4, 0)
			burst.Rate = 0
			burst.Parent = target
			burst:Emit(result.Remaining == 0 and 30 or 8)
			Debris:AddItem(burst, 1)
		end
		local broke = result.Remaining == 0
		local showDamage = not playerGui:GetAttribute("GalaxyHideDamage")
		if target and target.Parent and (broke or showDamage) then
			-- Números empilhados com leve desvio lateral; a quebra ganha destaque.
			local popup = Instance.new("BillboardGui")
			popup.Name = "MiningFeedback"
			popup.Adornee = target
			popup.Size = UDim2.fromOffset(280, 52)
			local drift = broke and 0 or (math.random() - 0.5) * 3
			popup.StudsOffsetWorldSpace = Vector3.new(drift, 5, 0)
			popup.MaxDistance = 60
			popup.AlwaysOnTop = true
			popup.Parent = gui
			local text = Instance.new("TextLabel")
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.Font = Theme.Font.Display
			text.TextSize = broke and 30 or 24
			text.TextStrokeTransparency = 0
			text.TextStrokeColor3 = C.Deep
			local oreColor = target.Color
			text.TextColor3 = broke and C.Gold or oreColor:Lerp(Color3.new(1, 1, 1), 0.45)
			text.Text = broke and ("+1 " .. result.Name) or ("-" .. Theme.format(result.Damage))
			text.Parent = popup
			local pop = Instance.new("UIScale")
			pop.Parent = text
			if not playerGui:GetAttribute("GalaxyReduceMotion") then
				pop.Scale = 1.5
				TweenService:Create(pop, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				TweenService:Create(popup, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					StudsOffsetWorldSpace = Vector3.new(drift, broke and 9 or 7.5, 0),
				}):Play()
				TweenService:Create(text, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.35), {
					TextTransparency = 1, TextStrokeTransparency = 1,
				}):Play()
			end
			Debris:AddItem(popup, 0.9)
		end
	end
	status.Text = result.Message
	messageUntil = os.clock() + 1.5
	panel.Visible = true
end)
