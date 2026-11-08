-- Prompts de interação no estilo do jogo (substituem o visual padrão do Roblox).
-- Só apresentação: o servidor cria os prompts e valida cada ação disparada.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.VisualTheme)
local Sound = require(script.Parent.Sound)
local C = Theme.Color
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local folder = Instance.new("Folder")
folder.Name = "GalaxyPrompts"
folder.Parent = playerGui

-- Cor de cada terminal, pelo nome do prompt criado no servidor.
local accents = {
	SellMinerals = C.Gold,
	OpenShop = C.Cyan,
	OpenPets = C.Pink,
}
local icons = {
	SellMinerals = "coin",
	OpenShop = "shop",
	OpenPets = "pet",
}

-- Estilo personalizado só neste cliente; o servidor não depende dele.
local function adopt(object)
	if object:IsA("ProximityPrompt") then
		object.Style = Enum.ProximityPromptStyle.Custom
	end
end
for _, object in ipairs(workspace:GetDescendants()) do adopt(object) end
workspace.DescendantAdded:Connect(adopt)

local function keyText(prompt, inputType)
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "TOQUE"
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		local name = prompt.GamepadKeyCode.Name
		return (string.gsub(name, "^Button", ""))
	end
	local key = prompt.KeyboardKeyCode.Name
	return key
end

local active = {}

local function build(prompt, inputType)
	local accent = accents[prompt.Name] or C.Violet
	local billboard = Instance.new("BillboardGui")
	billboard.Name = prompt.Name
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(270, 84)
	billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 1, 0)
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.Active = true
	billboard.Adornee = prompt.Parent
	billboard.Parent = folder

	local root = Instance.new("Frame")
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = billboard
	local scale = Instance.new("UIScale")
	scale.Parent = root

	local card = Instance.new("Frame")
	card.Position = UDim2.fromOffset(40, 12)
	card.Size = UDim2.new(1, -44, 0, 60)
	Theme.panel(card, accent, 30)
	card.Parent = root
	local badge = Theme.badge(card, icons[prompt.Name] or "star", accent, 50)
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.Position = UDim2.new(1, 12, 0, 2)
	badge.ZIndex = 3
	local object = Theme.label(card, string.upper(prompt.ObjectText), 11, accent:Lerp(C.White, 0.3))
	object.Font = Theme.Font.Display
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.Position = UDim2.fromOffset(44, 8)
	object.Size = UDim2.new(1, -86, 0, 14)
	Theme.fitText(object, 12, 7)
	local action = Theme.title(card, prompt.ActionText, 20, C.White)
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.Position = UDim2.fromOffset(44, 22)
	action.Size = UDim2.new(1, -60, 0, 30)
	Theme.fitText(action, 20, 10)

	-- Tecla 3D com preenchimento de "segurar".
	local key = Instance.new("TextButton")
	key.Name = "Key"
	key.Text = ""
	key.AutoButtonColor = false
	key.Size = UDim2.fromOffset(72, 72)
	key.Position = UDim2.fromOffset(0, 6)
	key.BackgroundTransparency = 1
	key.Parent = root
	local base = Instance.new("Frame")
	base.Size = UDim2.fromScale(1, 1)
	base.BackgroundColor3 = accent:Lerp(C.Ink, 0.5)
	base.BorderSizePixel = 0
	Theme.round(base, 18)
	Theme.stroke(base, C.Ink, 3)
	base.Parent = key
	local face = Instance.new("Frame")
	face.Size = UDim2.new(1, 0, 1, -6)
	face.BackgroundColor3 = C.Frost
	face.BorderSizePixel = 0
	face.ClipsDescendants = true
	Theme.round(face, 18)
	Theme.stroke(face, C.Ink, 3)
	face.Parent = key
	local hold = Instance.new("Frame")
	hold.AnchorPoint = Vector2.new(0, 1)
	hold.Position = UDim2.fromScale(0, 1)
	hold.Size = UDim2.fromScale(1, 0)
	hold.BackgroundColor3 = accent
	hold.BorderSizePixel = 0
	hold.Parent = face
	local letter = Theme.title(face, keyText(prompt, inputType), 30, C.Ink)
	letter.TextStrokeTransparency = 1
	letter.Size = UDim2.fromScale(1, 1)
	letter.ZIndex = 2
	Theme.fitText(letter, 30, 10)

	-- Toque: a tecla funciona como botão (inclusive para segurar).
	key.MouseButton1Down:Connect(function() prompt:InputHoldBegin() end)
	key.MouseButton1Up:Connect(function() prompt:InputHoldEnd() end)
	key.MouseLeave:Connect(function() prompt:InputHoldEnd() end)

	if not Theme.reducedMotion(root) then
		scale.Scale = 0.3
		TweenService:Create(scale, Theme.Motion.Pop, { Scale = 1 }):Play()
	end
	return { gui = billboard, hold = hold, face = face, scale = scale }
end

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end
	if active[prompt] then active[prompt].gui:Destroy() end
	active[prompt] = build(prompt, inputType)
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	local entry = active[prompt]
	if not entry then return end
	active[prompt] = nil
	if Theme.reducedMotion(entry.gui) then
		entry.gui:Destroy()
		return
	end
	local tween = TweenService:Create(entry.scale, Theme.Motion.Exit, { Scale = 0 })
	tween.Completed:Once(function() entry.gui:Destroy() end)
	tween:Play()
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	local entry = active[prompt]
	if not entry then return end
	entry.hold.Size = UDim2.fromScale(1, 0)
	TweenService:Create(entry.hold, TweenInfo.new(math.max(prompt.HoldDuration, 0.05), Enum.EasingStyle.Linear), {
		Size = UDim2.fromScale(1, 1),
	}):Play()
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
	local entry = active[prompt]
	if entry then
		TweenService:Create(entry.hold, Theme.Motion.Interaction, { Size = UDim2.fromScale(1, 0) }):Play()
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local entry = active[prompt]
	if entry then
		Sound.play("click", 1.2)
		Theme.pop(entry.face, 0.15)
	end
end)

-- Limpa cartões de prompts que saíram do jogo (por exemplo, por streaming).
UserInputService.LastInputTypeChanged:Connect(function()
	for prompt, entry in pairs(active) do
		if not prompt.Parent then
			entry.gui:Destroy()
			active[prompt] = nil
		end
	end
end)
