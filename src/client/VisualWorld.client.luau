-- Atmosfera do mundo no cliente: poeira cósmica flutuante e pulso nos neons.
-- Só apresentação; respeita "Movimento reduzido".
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Poeira ao redor da câmera
local anchor = Instance.new("Part")
anchor.Name = "CosmicDustAnchor"
anchor.Anchored = true
anchor.CanCollide = false
anchor.CanQuery = false
anchor.CanTouch = false
anchor.Transparency = 1
anchor.Size = Vector3.new(90, 24, 90)
anchor.Parent = workspace

local dust = Instance.new("ParticleEmitter")
dust.Texture = "rbxasset://textures/particles/sparkles_main.dna"
dust.Color = ColorSequence.new(Color3.fromRGB(190, 140, 255), Color3.fromRGB(120, 230, 255))
dust.LightEmission = 0.9
dust.Rate = 22
dust.Lifetime = NumberRange.new(4, 7)
dust.Speed = NumberRange.new(0.4, 1.4)
dust.Rotation = NumberRange.new(0, 360)
dust.SpreadAngle = Vector2.new(180, 180)
dust.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.35),
	NumberSequenceKeypoint.new(1, 0),
})
dust.Transparency = NumberSequence.new(0.3)
dust.Shape = Enum.ParticleEmitterShape.Box
dust.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
dust.Parent = anchor

RunService.Heartbeat:Connect(function()
	local camera = workspace.CurrentCamera
	if camera then
		anchor.Position = camera.CFrame.Position + Vector3.new(0, 4, 0)
	end
	dust.Enabled = not playerGui:GetAttribute("GalaxyReduceMotion")
		and not playerGui:GetAttribute("GalaxyHideDust") and not playerGui:GetAttribute("GalaxyLowGraphics")
end)

local world = workspace:WaitForChild("TerraNova")

-- ---------- Orçamento de neon ----------
-- O neon fica como acento (lâmpadas, orbes, pontas). Superfícies grandes em
-- neon (faixas, bordas, hologramas, anéis do chão) viram foscas na mesma cor,
-- só neste cliente. Depósitos de minério e peças mineráveis não são alterados.
local NEON_MAX_SIZE = 6
local function tame(part)
	if not part:IsA("BasePart") or part.Material ~= Enum.Material.Neon then return end
	-- Sem esperar OreDeposits: a checagem é feita na hora, para não atrasar o cenário.
	local deposits = world:FindFirstChild("OreDeposits")
	if part:GetAttribute("Mineable") or (deposits and part:IsDescendantOf(deposits)) then return end
	local size = part.Size
	if math.max(size.X, size.Y, size.Z) > NEON_MAX_SIZE then
		part.Material = Enum.Material.SmoothPlastic
		part.Color = part.Color:Lerp(Color3.fromHex("#1A1440"), 0.25)
	end
end
for _, descendant in ipairs(world:GetDescendants()) do tame(descendant) end
world.DescendantAdded:Connect(tame)

-- Pulso suave nos neons da praça (anéis e núcleos orbitais)
local pulse = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local function animate(part)
	if part:IsA("BasePart") and part.Material == Enum.Material.Neon
		and (part.Name:match("^RingInlay") or part.Name:match("^OrbitCore")) then
		local tween = TweenService:Create(part, pulse, { Transparency = 0.45 })
		tween:Play()
		playerGui:GetAttributeChangedSignal("GalaxyReduceMotion"):Connect(function()
			if playerGui:GetAttribute("GalaxyReduceMotion") then
				tween:Cancel()
				part.Transparency = 0
			else
				tween:Play()
			end
		end)
	end
end
for _, descendant in ipairs(world:GetDescendants()) do
	animate(descendant)
end
world.DescendantAdded:Connect(animate)

-- ---------- Cenário vivo ----------
-- Só peças decorativas sem colisão da Expansion se movem, e apenas neste
-- cliente: planetas giram, ilhas e orbes flutuam, nuvens derivam e estrelas
-- dos postes rodam. Minérios, balcões e terminais nunca são movidos.
local movers = {}
local flickers = {}
local holograms = {}

local function bobOffset(t, amplitude, speed, phase)
	return Vector3.new(0, math.sin(t * speed + phase) * amplitude, 0)
end

local function spinY(base, angle)
	return CFrame.new(base.Position) * CFrame.Angles(0, angle, 0) * base.Rotation
end

local function classify(part, folderName)
	local name = part.Name
	local index
	if folderName == "Backdrop" then
		index = name:match("^Island%a+(%d+)$")
		if index then
			local phase = tonumber(index)
			return function(base, t) return base + bobOffset(t, 2.5, 0.5, phase) end
		end
		index = name:match("^TreeTrunk(1%d%d)$") or name:match("^TreeCap(1%d%d)_%d$")
		if index then
			local phase = tonumber(index) - 100
			return function(base, t) return base + bobOffset(t, 2.5, 0.5, phase) end
		end
		index = name:match("^Cloud(%d+)_%d+$")
		if index then
			local phase = tonumber(index)
			-- Céu noturno: as nuvens brancas viram nebulosas escuras e esfumaçadas.
			local nebula = { Color3.fromHex("#3A2470"), Color3.fromHex("#5A2556"), Color3.fromHex("#1D3D66"),
				Color3.fromHex("#2B2160") }
			part.Color = nebula[phase % #nebula + 1]
			part.Material = Enum.Material.SmoothPlastic
			part.Transparency = 0.5
			return function(base, t) return base + Vector3.new(math.sin(t * 0.04 + phase) * 14, 0, 0) end
		end
		if name:match("^PlanetRing%d+$") then
			return function(base, t) return spinY(base, t * 0.05) end
		end
		index = name:match("^PlanetSpot(%d+)$")
		if index then
			-- A mancha gira em volta do centro do planeta: parece que ele roda.
			local planet = part.Parent:FindFirstChild("Planet" .. index)
			if planet then
				local center = planet.Position
				return function(base, t)
					return CFrame.new(center) * CFrame.Angles(0, t * 0.06, 0) * (CFrame.new(-center) * base)
				end
			end
		end
	elseif folderName == "Props" then
		index = name:match("^PlanetBall(%d+)$")
		if index then
			local phase = tonumber(index)
			return function(base, t) return base + bobOffset(t, 0.5, 1.2, phase) end
		end
		index = name:match("^PlanetRing(%d+)$")
		if index then
			local phase = tonumber(index)
			return function(base, t) return spinY(base, t * 0.6) + bobOffset(t, 0.5, 1.2, phase) end
		end
		if name:match("^StarTop") then
			return function(base, t) return spinY(base, t * 1.2) end
		end
		if name:match("^RocketFlame%d+$") then
			table.insert(flickers, part)
		end
	elseif folderName == "PlazaOrbs" then
		index = name:match("^Orb(%d+)$")
		if index then
			local phase = tonumber(index)
			return function(base, t)
				local position = base.Position
				local radius = Vector2.new(position.X, position.Z).Magnitude
				local angle = math.atan2(position.Z, position.X) + t * 0.25
				return CFrame.new(math.cos(angle) * radius, position.Y + math.sin(t * 1.5 + phase) * 0.8,
					math.sin(angle) * radius) * base.Rotation
			end
		end
	elseif folderName == "Rim" then
		index = name:match("^PylonOrb(%d+)$")
		if index then
			local phase = tonumber(index)
			return function(base, t) return base + bobOffset(t, 0.6, 1.4, phase) end
		end
	elseif folderName == "Gates" then
		if name:match("Holo$") then
			table.insert(holograms, { part = part, base = part.Transparency })
		end
	end
	return nil
end

local function register(part)
	if not part:IsA("BasePart") or part.CanCollide or movers[part] then return end
	local folder = part.Parent
	if not folder or not folder.Parent or folder.Parent.Name ~= "Expansion" then return end
	local motion = classify(part, folder.Name)
	if motion then
		movers[part] = { base = part.CFrame, motion = motion }
	end
end

local expansion = world:WaitForChild("Expansion", 30)
if expansion then
	for _, descendant in ipairs(expansion:GetDescendants()) do register(descendant) end
	expansion.DescendantAdded:Connect(register)
end

local resting = false
local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 1 / 30 then return end
	accumulator = 0
	-- Movimento reduzido ou modo de desempenho: tudo volta à posição original.
	local reduced = playerGui:GetAttribute("GalaxyReduceMotion") == true
		or playerGui:GetAttribute("GalaxyLowGraphics") == true
	if reduced then
		-- Movimento reduzido: tudo volta à posição original uma única vez.
		if not resting then
			resting = true
			local parts, frames = {}, {}
			for part, entry in pairs(movers) do
				if part.Parent then
					table.insert(parts, part)
					table.insert(frames, entry.base)
				end
			end
			workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		end
		return
	end
	resting = false
	local t = os.clock()
	local parts, frames = {}, {}
	for part, entry in pairs(movers) do
		if part.Parent then
			table.insert(parts, part)
			table.insert(frames, entry.motion(entry.base, t))
		else
			movers[part] = nil
		end
	end
	workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	for _, flame in ipairs(flickers) do
		flame.Transparency = 0.1 + math.random() * 0.35
	end
	for _, holo in ipairs(holograms) do
		holo.part.Transparency = math.clamp(holo.base + math.sin(t * 2.2) * 0.06, 0, 1)
	end
end)

-- ---------- Céu galáctico (só neste cliente) ----------
-- Galáxia espiral girando, nebulosas, faixa estelar e estrelas cadentes.
-- Peças locais, sem colisão e sem consulta: não interferem na mineração.
local skyFolder = Instance.new("Folder")
skyFolder.Name = "GalaxySky"
skyFolder.Parent = workspace

local function skyPart(position, size, color, transparency)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Size = Vector3.new(size, size, size)
	part.Position = position
	part.Color = color
	part.Transparency = transparency
	part.Parent = skyFolder
	return part
end

local random = Random.new(42)
local PINK = Color3.fromHex("#FF4FB3")
local VIOLET = Color3.fromHex("#8B4DFF")
local CYAN = Color3.fromHex("#22D8FF")
local GOLD = Color3.fromHex("#FFD36E")

-- Galáxia espiral voltada para o centro do mapa.
local galaxyCenter = Vector3.new(-620, 540, -860)
local normal = (Vector3.new(0, 120, 0) - galaxyCenter).Unit
local axisA = normal:Cross(Vector3.yAxis).Unit
local axisB = normal:Cross(axisA).Unit
local galaxy = {}
local function addStar(offset, size, color, transparency)
	local part = skyPart(galaxyCenter + offset, size, color, transparency)
	table.insert(galaxy, { part = part, offset = offset })
end
for _ = 1, 26 do
	local angle = random:NextNumber(0, math.pi * 2)
	local radius = random:NextNumber(0, 45)
	addStar(axisA * math.cos(angle) * radius + axisB * math.sin(angle) * radius,
		random:NextNumber(20, 34), GOLD:Lerp(Color3.new(1, 1, 1), random:NextNumber(0, 0.6)), random:NextNumber(0.45, 0.65))
end
for arm = 0, 1 do
	for k = 1, 120 do
		local progress = k / 120
		local angle = arm * math.pi + progress * math.pi * 3.4
		local radius = 45 + progress * 400
		local jitter = (1 - progress * 0.4) * 30
		local offset = axisA * (math.cos(angle) * radius + random:NextNumber(-jitter, jitter))
			+ axisB * (math.sin(angle) * radius + random:NextNumber(-jitter, jitter))
			+ normal * random:NextNumber(-12, 12)
		local color = progress < 0.5 and PINK:Lerp(VIOLET, progress * 2) or VIOLET:Lerp(CYAN, (progress - 0.5) * 2)
		addStar(offset, random:NextNumber(6, 16) * (1.2 - progress * 0.5), color, random:NextNumber(0.5, 0.8))
	end
end

-- Nebulosas gigantes e translúcidas ao redor do horizonte.
for index = 1, 8 do
	local angle = index / 8 * math.pi * 2 + random:NextNumber(-0.3, 0.3)
	local distance = random:NextNumber(950, 1300)
	local colors = { VIOLET, PINK, CYAN, Color3.fromHex("#3B2BD6") }
	skyPart(Vector3.new(math.cos(angle) * distance, random:NextNumber(220, 560), math.sin(angle) * distance),
		random:NextNumber(380, 620), colors[index % #colors + 1], 0.96)
end

-- Faixa da "Via Láctea" cruzando o céu.
for k = 0, 70 do
	local progress = k / 70
	local angle = progress * math.pi
	local position = Vector3.new(math.cos(angle) * 1100, 380 + math.sin(angle) * 520, 300 - progress * 600)
		+ Vector3.new(random:NextNumber(-60, 60), random:NextNumber(-40, 40), random:NextNumber(-60, 60))
	skyPart(position, random:NextNumber(40, 90), ({ VIOLET, CYAN, PINK })[k % 3 + 1], random:NextNumber(0.92, 0.96))
end

-- Modo de desempenho: o céu galáctico inteiro sai da cena.
local function applyQuality()
	skyFolder.Parent = playerGui:GetAttribute("GalaxyLowGraphics") and nil or workspace
end
playerGui:GetAttributeChangedSignal("GalaxyLowGraphics"):Connect(applyQuality)
applyQuality()

local galaxyClock = 0
RunService.Heartbeat:Connect(function(dt)
	galaxyClock += dt
	if galaxyClock < 1 / 20 or playerGui:GetAttribute("GalaxyReduceMotion")
		or playerGui:GetAttribute("GalaxyLowGraphics") then return end
	galaxyClock = 0
	local rotation = CFrame.fromAxisAngle(normal, os.clock() * 0.015)
	local parts, frames = {}, {}
	for _, star in ipairs(galaxy) do
		table.insert(parts, star.part)
		table.insert(frames, CFrame.new(galaxyCenter + rotation:VectorToWorldSpace(star.offset)))
	end
	workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
end)

-- Estrelas cadentes de tempos em tempos.
local function shootingStar()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local origin = camera.CFrame.Position
	local start = origin + Vector3.new(random:NextNumber(-500, 500), random:NextNumber(260, 420), random:NextNumber(-500, 500))
	local heading = Vector3.new(random:NextNumber(-1, 1), -0.35, random:NextNumber(-1, 1)).Unit
	local star = skyPart(start, 4, Color3.new(1, 1, 1), 0)
	local head = Instance.new("Attachment")
	head.Position = Vector3.new(0, 1.5, 0)
	head.Parent = star
	local tail = Instance.new("Attachment")
	tail.Position = Vector3.new(0, -1.5, 0)
	tail.Parent = star
	local trail = Instance.new("Trail")
	trail.Attachment0 = head
	trail.Attachment1 = tail
	trail.Lifetime = 0.45
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1), CYAN)
	trail.Transparency = NumberSequence.new(0, 1)
	trail.Parent = star
	local tween = TweenService:Create(star, TweenInfo.new(1.3, Enum.EasingStyle.Linear), {
		Position = start + heading * 420,
		Transparency = 1,
	})
	tween.Completed:Once(function() star:Destroy() end)
	tween:Play()
end

task.spawn(function()
	while true do
		task.wait(random:NextNumber(4, 9))
		if not playerGui:GetAttribute("GalaxyReduceMotion") and not playerGui:GetAttribute("GalaxyLowGraphics") then
			shootingStar()
		end
	end
end)
