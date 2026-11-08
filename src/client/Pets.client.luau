-- Companheiros visuais dos pets equipados — de todos os jogadores.
-- Cada cliente desenha o pet de cada jogador a partir do atributo
-- EquippedPet (publicado pelo servidor). O bônus é aplicado só no servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local folder = Instance.new("Folder")
folder.Name = "GalaxyPets"
folder.Parent = workspace

local INK = Color3.fromHex("#140B24")
local WHITE = Color3.new(1, 1, 1)
local CHEEK = Color3.fromHex("#FF7FC4")
local Ball, Block, Cylinder = Enum.PartType.Ball, Enum.PartType.Block, Enum.PartType.Cylinder
local Smooth, Neon, Glass = Enum.Material.SmoothPlastic, Enum.Material.Neon, Enum.Material.Glass

local function findPet(id)
	for _, pet in ipairs(Config.Pets) do
		if pet.Id == id then return pet end
	end
	return nil
end

-- Construtor com peças posicionadas em relação ao centro do corpo (frente = -Z).
local function kit(model)
	local self = { model = model, eyes = {} }
	function self.part(name, shape, size, offset, color, material, transparency)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = shape
		part.Size = size
		part.CFrame = offset
		part.Color = color
		part.Material = material or Smooth
		part.Transparency = transparency or 0
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		return part
	end
	-- Olhos grandes de desenho: branco, pupila e brilho.
	function self.face(y, z, spread, scale)
		scale = scale or 1
		for _, side in ipairs({ -1, 1 }) do
			local white = self.part("EyeWhite", Ball, Vector3.new(0.42, 0.52, 0.2) * scale,
				CFrame.new(side * spread, y, z), WHITE)
			local pupil = self.part("Pupil", Ball, Vector3.new(0.27, 0.36, 0.14) * scale,
				CFrame.new(side * spread, y - 0.03, z - 0.06 * scale), INK)
			self.part("Shine", Ball, Vector3.new(0.1, 0.1, 0.06) * scale,
				CFrame.new(side * spread + 0.06, y + 0.08, z - 0.12 * scale), WHITE, Neon)
			table.insert(self.eyes, { white = white, pupil = pupil })
			self.part("Cheek", Ball, Vector3.new(0.24, 0.14, 0.08) * scale,
				CFrame.new(side * (spread + 0.18), y - 0.26 * scale, z + 0.04), CHEEK, Smooth, 0.15)
		end
		self.part("Mouth", Block, Vector3.new(0.18, 0.05, 0.05) * scale, CFrame.new(0, y - 0.3 * scale, z - 0.02), INK)
	end
	function self.feet(y, spread, color)
		for _, side in ipairs({ -1, 1 }) do
			self.part("Foot", Ball, Vector3.new(0.42, 0.26, 0.5), CFrame.new(side * spread, y, -0.1), color)
		end
	end
	function self.emit(parent, color, rate, size)
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dna"
		sparkle.Color = ColorSequence.new(color, WHITE)
		sparkle.LightEmission = 1
		sparkle.Rate = rate
		sparkle.Lifetime = NumberRange.new(0.5, 1)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Size = NumberSequence.new(size or 0.25, 0)
		sparkle.Parent = parent
		return sparkle
	end
	return self
end

local builders = {}

function builders.blob(k, color)
	local body = k.part("Corpo", Ball, Vector3.new(1.7, 1.55, 1.55), CFrame.new(), color)
	k.part("Barriga", Ball, Vector3.new(1.1, 1.0, 0.6), CFrame.new(0, -0.18, -0.55), color:Lerp(WHITE, 0.45))
	k.face(0.18, -0.7, 0.33)
	for _, side in ipairs({ -1, 1 }) do
		k.part("Antena", Block, Vector3.new(0.1, 0.6, 0.1),
			CFrame.new(side * 0.35, 0.95, 0) * CFrame.Angles(0, 0, math.rad(-side * 18)), color:Lerp(INK, 0.3))
		local tip = k.part("PontaAntena", Ball, Vector3.new(0.32, 0.32, 0.32), CFrame.new(side * 0.47, 1.28, 0),
			color:Lerp(WHITE, 0.4), Neon)
		k.emit(tip, color, 2, 0.15)
	end
	k.feet(-0.75, 0.42, color:Lerp(INK, 0.25))
	return body
end

function builders.rock(k, color)
	local body = k.part("Corpo", Block, Vector3.new(1.6, 1.4, 1.45), CFrame.Angles(0, 0, math.rad(4)), color, Enum.Material.Slate)
	k.part("Topo", Block, Vector3.new(1.3, 0.4, 1.2), CFrame.new(0, 0.82, 0.05) * CFrame.Angles(0, math.rad(8), 0),
		color:Lerp(WHITE, 0.15), Enum.Material.Slate)
	k.face(0.12, -0.75, 0.32)
	for _, side in ipairs({ -1, 1 }) do
		k.part("Sobrancelha", Block, Vector3.new(0.34, 0.08, 0.06),
			CFrame.new(side * 0.32, 0.47, -0.76) * CFrame.Angles(0, 0, math.rad(side * 12)), INK)
	end
	for index, x in ipairs({ -0.4, 0.05, 0.45 }) do
		local crystal = k.part("Cristal", Block, Vector3.new(0.26, 0.5 + index * 0.15, 0.26),
			CFrame.new(x, 1.2 + index * 0.05, 0.25) * CFrame.Angles(math.rad(-12), math.rad(45), math.rad(10 * (index - 2))),
			Color3.fromHex(index == 2 and "#FFC531" or "#FF8A1F"), Neon)
		if index == 2 then k.emit(crystal, Color3.fromHex("#FFC531"), 3, 0.2) end
	end
	k.feet(-0.75, 0.45, color:Lerp(INK, 0.3))
	return body
end

function builders.cloud(k, color)
	local body = k.part("Corpo", Ball, Vector3.new(1.55, 1.3, 1.35), CFrame.new(), color, Neon, 0.2)
	for _, spec in ipairs({ { -0.7, -0.1, 1.0 }, { 0.7, -0.1, 1.0 }, { -0.35, 0.45, 0.85 }, { 0.4, 0.5, 0.8 } }) do
		k.part("Nuvem", Ball, Vector3.new(spec[3], spec[3] * 0.85, spec[3] * 0.85), CFrame.new(spec[1], spec[2], 0.1),
			color:Lerp(WHITE, 0.25), Neon, 0.3)
	end
	k.face(0.08, -0.66, 0.3)
	k.emit(body, color:Lerp(WHITE, 0.4), 6, 0.3)
	return body
end

function builders.bolt(k, color)
	local body = k.part("Corpo", Ball, Vector3.new(1.4, 1.4, 1.4), CFrame.new(), color)
	k.part("Barriga", Ball, Vector3.new(0.9, 0.8, 0.5), CFrame.new(0, -0.18, -0.48), color:Lerp(WHITE, 0.5))
	k.face(0.12, -0.6, 0.29)
	for _, side in ipairs({ -1, 1 }) do
		k.part("Orelha", Block, Vector3.new(0.22, 0.65, 0.18),
			CFrame.new(side * 0.42, 0.95, 0) * CFrame.Angles(0, 0, math.rad(-side * 22)), color)
		k.part("Raio", Block, Vector3.new(0.2, 0.5, 0.16),
			CFrame.new(side * 0.6, 1.4, 0) * CFrame.Angles(0, 0, math.rad(side * 28)), color:Lerp(WHITE, 0.3), Neon)
	end
	k.part("Cauda", Block, Vector3.new(0.2, 0.7, 0.2), CFrame.new(0.25, 0.1, 0.8) * CFrame.Angles(math.rad(40), 0, math.rad(-30)),
		color:Lerp(WHITE, 0.3), Neon)
	k.emit(body, color, 10, 0.3)
	k.feet(-0.65, 0.36, color:Lerp(INK, 0.25))
	return body
end

function builders.ice(k, color)
	local body = k.part("Corpo", Block, Vector3.new(1.4, 1.4, 1.4), CFrame.new(), color, Glass, 0.25)
	k.part("Nucleo", Ball, Vector3.new(0.8, 0.8, 0.8), CFrame.new(0, 0, 0.1), color:Lerp(WHITE, 0.3), Neon, 0.1)
	k.face(0.12, -0.72, 0.3)
	for index, spec in ipairs({ { 0, 0.75 }, { -0.4, 0.55 }, { 0.4, 0.55 } }) do
		k.part("Pico", Block, Vector3.new(0.28, spec[2], 0.28),
			CFrame.new(spec[1], 0.75 + spec[2] / 2, 0) * CFrame.Angles(0, math.rad(45), math.rad((index - 2) * -15)),
			Color3.fromHex("#E6FCFF"), Neon)
	end
	k.emit(body, Color3.fromHex("#CFF7FF"), 5, 0.22)
	k.feet(-0.75, 0.38, color:Lerp(WHITE, 0.3))
	return body
end

function builders.sun(k, color)
	local body = k.part("Corpo", Ball, Vector3.new(1.55, 1.55, 1.55), CFrame.new(), color, Neon)
	k.face(0.1, -0.74, 0.32)
	local ring = k.part("Anel", Cylinder, Vector3.new(0.1, 2.5, 2.5), CFrame.Angles(math.rad(70), 0, math.rad(90)),
		Color3.fromHex("#FFE278"), Neon, 0.2)
	ring:SetAttribute("Spin", true)
	for index = 0, 7 do
		local angle = index * math.pi / 4
		local flame = k.part("Chama", Block, Vector3.new(0.3, 0.45, 0.3),
			CFrame.new(math.cos(angle) * 1.0, math.sin(angle) * 1.0, 0.2) * CFrame.Angles(0, 0, angle - math.pi / 2) * CFrame.Angles(0, math.rad(45), 0),
			Color3.fromHex("#FFB03A"), Neon)
		flame:SetAttribute("Spin", true)
	end
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 1.5
	light.Parent = body
	k.emit(body, color, 8, 0.35)
	return body
end

-- Sombra no chão e etiqueta com o nome.
local function decorate(model, root, pet, owner)
	local shadow = Instance.new("Part")
	shadow.Name = "Sombra"
	shadow.Shape = Cylinder
	shadow.Size = Vector3.new(0.05, 1.6, 1.6)
	shadow.Color = Color3.new(0, 0, 0)
	shadow.Material = Smooth
	shadow.Transparency = 0.6
	shadow.Anchored = true
	shadow.CanCollide = false
	shadow.CanQuery = false
	shadow.CanTouch = false
	shadow.CastShadow = false
	shadow.Parent = model
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.fromOffset(160, 40)
	tag.StudsOffset = Vector3.new(0, 1.9, 0)
	tag.MaxDistance = 45
	tag.LightInfluence = 0
	tag.Parent = root
	local color = Color3.fromHex(pet.Color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 20
	label.Text = pet.Name
	label.TextColor3 = color:Lerp(WHITE, 0.35)
	label.TextStrokeColor3 = Color3.fromHex("#05030F")
	label.TextStrokeTransparency = 0
	label.Parent = tag
	local bonus = Instance.new("TextLabel")
	bonus.Position = UDim2.fromOffset(0, 21)
	bonus.Size = UDim2.new(1, 0, 0, 16)
	bonus.BackgroundTransparency = 1
	bonus.Font = Enum.Font.FredokaOne
	bonus.TextSize = 13
	bonus.Text = (owner == localPlayer and "" or owner.DisplayName .. " · ") .. "+" .. math.round(pet.Bonus * 100) .. "%"
	bonus.TextColor3 = Color3.fromHex("#2EE59D")
	bonus.TextStrokeColor3 = Color3.fromHex("#05030F")
	bonus.TextStrokeTransparency = 0
	bonus.Parent = tag
	return shadow
end

-- ---------- Um companheiro por jogador ----------
local companions = {}

local function build(player)
	local old = companions[player]
	if old then
		old.model:Destroy()
		companions[player] = nil
	end
	local pet = findPet(player:GetAttribute("EquippedPet"))
	if not pet or not builders[pet.Look] then return end
	local model = Instance.new("Model")
	model.Name = player.Name .. "_" .. pet.Name
	local k = kit(model)
	local root = builders[pet.Look](k, Color3.fromHex(pet.Color))
	model.PrimaryPart = root
	local shadow = decorate(model, root, pet, player)
	-- Guarda o desenho original de cada peça (relativo ao corpo) para animar.
	local layout = {}
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= shadow then
			layout[part] = part.CFrame
		end
	end
	local entry = {
		model = model, layout = layout, shadow = shadow, eyes = k.eyes, root = root,
		phase = math.random() * 6.28, current = nil, nextBlink = os.clock() + math.random(2, 5),
	}
	companions[player] = entry
	-- Pequeno "pulo" de chegada.
	entry.arrival = os.clock()
end

local function track(player)
	player:GetAttributeChangedSignal("EquippedPet"):Connect(function() build(player) end)
	build(player)
end
for _, player in ipairs(Players:GetPlayers()) do track(player) end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(player)
	local entry = companions[player]
	if entry then entry.model:Destroy() end
	companions[player] = nil
end)

local function blink(entry)
	for _, eye in ipairs(entry.eyes) do
		for _, part in ipairs({ eye.white, eye.pupil }) do
			local size = part.Size
			part.Size = Vector3.new(size.X, size.Y * 0.15, size.Z)
			TweenService:Create(part, TweenInfo.new(0.12), { Size = size }):Play()
		end
	end
end

local ground = RaycastParams.new()
ground.FilterType = Enum.RaycastFilterType.Exclude

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	local reduced = playerGui:GetAttribute("GalaxyReduceMotion") == true
	local exclude = { folder }
	for player, entry in pairs(companions) do
		if player.Character then table.insert(exclude, player.Character) end
	end
	ground.FilterDescendantsInstances = exclude
	for player, entry in pairs(companions) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			entry.model.Parent = nil
			entry.current = nil
			continue
		end
		local bounce = reduced and 0 or math.abs(math.sin(t * 4 + entry.phase)) * 0.35
		local hop = 0
		if entry.arrival and not reduced then
			local age = t - entry.arrival
			if age < 0.6 then hop = math.sin(age / 0.6 * math.pi) * 1.4 else entry.arrival = nil end
		end
		local goal = root.CFrame * CFrame.new(2.8, 0.6 + bounce + hop, 2)
		if not entry.current or (entry.current.Position - goal.Position).Magnitude > 24 then
			entry.current = goal
		else
			entry.current = entry.current:Lerp(goal, 1 - math.exp(-8 * dt))
		end
		-- Inclinação suave para os lados ao andar.
		local tilt = reduced and CFrame.new() or CFrame.Angles(0, 0, math.sin(t * 2 + entry.phase) * 0.08)
		local pivot = entry.current * tilt
		local spin = reduced and 0 or t * 1.5
		for part, offset in pairs(entry.layout) do
			if part:GetAttribute("Spin") then
				part.CFrame = pivot * CFrame.Angles(0, 0, spin) * offset
			else
				part.CFrame = pivot * offset
			end
		end
		-- Sombra presa ao chão logo abaixo do pet.
		local hit = workspace:Raycast(pivot.Position, Vector3.new(0, -12, 0), ground)
		if hit then
			entry.shadow.Transparency = 0.55 + math.clamp((pivot.Position.Y - hit.Position.Y) / 12, 0, 0.4)
			entry.shadow.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
		else
			entry.shadow.Transparency = 1
		end
		if not reduced and t > entry.nextBlink then
			entry.nextBlink = t + math.random(25, 55) / 10
			blink(entry)
		end
		if not entry.model.Parent then entry.model.Parent = folder end
	end
end)
