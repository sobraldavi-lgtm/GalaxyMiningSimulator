-- Arte dos depósitos de minério (só neste cliente).
-- Cada tipo ganha um conjunto próprio: pepitas metálicas, cristais, lascas,
-- espinhos de obsidiana ou diamante facetado, com anel de brilho no chão.
-- As peças decorativas não colidem e não recebem cliques (CanQuery = false):
-- o alvo da mineração continua sendo a Base/Sample validada pelo servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local ArtStyle = require(script.Parent:WaitForChild("ArtStyle"))
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local hitSignal = Instance.new("BindableEvent")
hitSignal.Name = "GalaxyOreHit"
hitSignal.Parent = playerGui

local folder = Instance.new("Folder")
folder.Name = "GalaxyOreArt"
folder.Parent = workspace

local ROCK = Color3.fromHex("#241B3A")
local WHITE = Color3.new(1, 1, 1)
local decor = {}
local rings = {}
local spinners = {}

local function reduced()
	return playerGui:GetAttribute("GalaxyReduceMotion") == true or playerGui:GetAttribute("GalaxyLowGraphics") == true
end

-- Modo de desempenho: a decoração dos depósitos sai da cena (a base continua mineral).
local function applyQuality()
	folder.Parent = playerGui:GetAttribute("GalaxyLowGraphics") and nil or workspace
end
playerGui:GetAttributeChangedSignal("GalaxyLowGraphics"):Connect(applyQuality)

local function piece(cframe, size, color, material, shape, transparency)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

local function seedOf(text)
	local seed = 0
	for index = 1, #text do
		seed = (seed * 31 + string.byte(text, index)) % 2147483647
	end
	return seed
end

-- Ponto na superfície de cima da base, em volta da amostra central.
local function spot(top, rng, minRadius, maxRadius)
	local angle = rng:NextNumber(0, math.pi * 2)
	local radius = rng:NextNumber(minRadius, maxRadius)
	return top * CFrame.new(math.cos(angle) * radius, 0, math.sin(angle) * radius), angle
end

-- Inclina uma peça para fora a partir do centro (cristais "abrindo").
local function tiltOut(base, angle, degrees)
	return base * CFrame.Angles(0, -angle, 0) * CFrame.Angles(0, 0, -math.rad(degrees))
end

local kits = {}

function kits.nugget(top, rng, color, style, add)
	for _ = 1, 7 do
		local at = spot(top, rng, 1.2, 2.7)
		local size = rng:NextNumber(0.8, 1.7)
		local shade = color:Lerp(WHITE, rng:NextNumber(0, 0.25))
		local shape = rng:NextNumber() < 0.6 and Enum.PartType.Ball or Enum.PartType.Block
		local part = add(at * CFrame.new(0, size * 0.35, 0) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0),
			Vector3.new(size, size * 0.8, size), shade, style.Material, shape)
		part.Reflectance = 0.25
	end
	if style.Patina then
		for _ = 1, 3 do
			local at = spot(top, rng, 1.6, 2.6)
			add(at * CFrame.new(0, 0.35, 0), Vector3.new(0.55, 0.45, 0.55), style.Patina, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		end
	end
end

function kits.crystal(top, rng, color, style, add)
	for index = 1, 7 do
		local at, angle = spot(top, rng, 1.0, 2.5)
		local height = rng:NextNumber(1.6, 3.6)
		local width = rng:NextNumber(0.6, 1.05)
		local frame = tiltOut(at, angle, rng:NextNumber(12, 30)) * CFrame.new(0, height / 2, 0)
			* CFrame.Angles(0, math.rad(45), 0)
		if index % 2 == 0 then
			local part = add(frame, Vector3.new(width, height, width), color, Enum.Material.Glass, nil, 0.2)
			part.Reflectance = 0.3
		else
			local part = add(frame, Vector3.new(width, height, width), color:Lerp(WHITE, 0.05), Enum.Material.SmoothPlastic)
			part.Reflectance = 0.15
		end
		-- Ponta mais clara no topo do cristal.
		add(frame * CFrame.new(0, height / 2, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
			Vector3.new(width * 0.7, width * 0.7, width * 0.7), color:Lerp(WHITE, 0.45), Enum.Material.Neon)
	end
end

function kits.shard(top, rng, color, style, add)
	for _ = 1, 8 do
		local at, angle = spot(top, rng, 1.0, 2.6)
		local height = rng:NextNumber(1.4, 3.2)
		local part = add(tiltOut(at, angle, rng:NextNumber(8, 28)) * CFrame.new(0, height / 2, 0),
			Vector3.new(0.4, height, 0.7), color:Lerp(WHITE, rng:NextNumber(0, 0.3)), style.Material)
		part.Reflectance = 0.5
	end
end

function kits.spike(top, rng, color, style, add)
	for _ = 1, 7 do
		local at, angle = spot(top, rng, 0.9, 2.6)
		local height = rng:NextNumber(2, 4.2)
		local frame = tiltOut(at, angle, rng:NextNumber(10, 32)) * CFrame.new(0, height / 2, 0)
		add(frame, Vector3.new(0.75, height, 0.75), Color3.fromHex("#120A1E"), style.Material)
		-- Veios de energia violeta subindo pelos espinhos.
		add(frame * CFrame.new(0.38, 0, 0), Vector3.new(0.08, height * 0.85, 0.2), color:Lerp(WHITE, 0.25), Enum.Material.Neon)
	end
end

function kits.diamond(top, rng, color, style, add)
	-- Diamante grande apoiado num vértice, girando devagar.
	local gem = add(top * CFrame.new(2.3, 1.6, 0) * CFrame.Angles(math.rad(45), 0, math.rad(35.26)),
		Vector3.new(1.7, 1.7, 1.7), color:Lerp(WHITE, 0.3), Enum.Material.Glass, nil, 0.1)
	gem.Reflectance = 0.6
	local core = add(gem.CFrame, Vector3.new(0.9, 0.9, 0.9), color, Enum.Material.Neon, nil, 0.05)
	table.insert(spinners, gem)
	table.insert(spinners, core)
	for _ = 1, 5 do
		local at, angle = spot(top, rng, 1.0, 2.4)
		local height = rng:NextNumber(1, 2.2)
		add(tiltOut(at, angle, 20) * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, math.rad(45), 0),
			Vector3.new(0.6, height, 0.6), color:Lerp(WHITE, 0.5), Enum.Material.Glass, nil, 0.15)
	end
end

local function build(base, oreType)
	if decor[base] then return end
	local ore = Config.Ores[oreType]
	local style = ArtStyle.Ore[oreType]
	if not ore or not style then return end
	local color = Color3.fromHex(ore.Color or "#FFFFFF")
	local rng = Random.new(seedOf(base:GetFullName()))
	local entry = { parts = {} }
	-- Peças de rocha (pedregulhos, veios e cascalho) só tremem; o minério renasce.
	local addingRock = false
	local function add(cframe, size, partColor, material, shape, transparency)
		local part = piece(cframe, size, partColor, material, shape, transparency)
		table.insert(entry.parts, { part = part, cframe = cframe, size = size, color = partColor, rock = addingRock })
		return part
	end

	-- A base vira rocha escura com reflexo da cor do minério (só aparência local).
	base.Material = Enum.Material.Rock
	base.Color = ROCK:Lerp(color, 0.12)

	local top = base.CFrame * CFrame.new(0, base.Size.Y / 2, 0)
	local floor = base.CFrame * CFrame.new(0, -base.Size.Y / 2 + 0.08, 0)
	local ring = piece(floor * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.12, 9.6, 9.6), color,
		Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, 0.7)
	table.insert(rings, { part = ring, phase = rng:NextNumber(0, 6.28) })
	entry.ring = ring
	entry.floor = floor
	entry.color = color
	entry.top = top

	-- Pedregulhos nos cantos quebram a silhueta de caixa da base,
	-- com veios do minério correndo pela superfície.
	addingRock = true
	local half = base.Size / 2
	for _, corner in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		local size = rng:NextNumber(2.4, 3.4)
		local at = base.CFrame * CFrame.new(corner[1] * (half.X - 0.6), -half.Y + size * 0.32, corner[2] * (half.Z - 0.5))
			* CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0, 3))
		add(at, Vector3.new(size, size * 0.8, size * 0.9), ROCK:Lerp(color, rng:NextNumber(0.04, 0.12)),
			Enum.Material.Rock, Enum.PartType.Ball)
		for _ = 1, 2 do
			local vein = add(at * CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), 0)
				* CFrame.new(0, size * 0.38, 0), Vector3.new(0.5, 0.12, size * 0.55), color:Lerp(WHITE, 0.1),
				style.Material == Enum.Material.Basalt and Enum.Material.Neon or Enum.Material.SmoothPlastic)
			vein.Reflectance = 0.3
		end
	end

	-- Pedregulhos ao redor.
	for _ = 1, 5 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local size = rng:NextNumber(0.8, 1.6)
		add(floor * CFrame.new(math.cos(angle) * 4.2, size * 0.3, math.sin(angle) * 3.7)
			* CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0),
			Vector3.new(size, size * 0.7, size), ROCK:Lerp(color, 0.08), Enum.Material.Rock, Enum.PartType.Ball)
	end

	addingRock = false
	kits[style.Kit](top, rng, color, style, add)

	if style.Sparkle and entry.parts[1] then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dna"
		sparkle.Color = ColorSequence.new(color:Lerp(WHITE, 0.5))
		sparkle.LightEmission = 1
		sparkle.Rate = 5
		sparkle.Lifetime = NumberRange.new(0.8, 1.6)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.45),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkle.Parent = entry.parts[#entry.parts].part
	end

	decor[base] = entry
	base.Destroying:Connect(function()
		for _, item in ipairs(entry.parts) do item.part:Destroy() end
		ring:Destroy()
		decor[base] = nil
	end)
end

-- Lascas do minério voando a partir do topo do depósito.
local function chips(entry, amount)
	for _ = 1, amount do
		local size = math.random(25, 50) / 100
		local chip = piece(entry.top * CFrame.new(math.random(-10, 10) / 10, 0.6, math.random(-10, 10) / 10)
			* CFrame.Angles(math.random() * 3, math.random() * 3, 0), Vector3.new(size, size, size),
			entry.color:Lerp(WHITE, math.random() * 0.3), Enum.Material.SmoothPlastic)
		local angle = math.random() * math.pi * 2
		local push = math.random(25, 45) / 10
		local apex = chip.Position + Vector3.new(math.cos(angle) * push, math.random(20, 35) / 10, math.sin(angle) * push)
		local landing = apex + Vector3.new(math.cos(angle) * push * 0.6, -math.random(30, 45) / 10, math.sin(angle) * push * 0.6)
		local up = TweenService:Create(chip, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = apex,
		})
		local down = TweenService:Create(chip, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = landing,
			Transparency = 1,
			Size = Vector3.new(0.05, 0.05, 0.05),
		})
		up.Completed:Once(function() down:Play() end)
		down.Completed:Once(function() chip:Destroy() end)
		up:Play()
	end
end

-- Reação aos golpes: tremor e lascas; na quebra, clarão, onda de choque e "renascer".
hitSignal.Event:Connect(function(base, broke)
	local entry = decor[base]
	if not entry or reduced() then return end
	chips(entry, broke and 9 or 3)
	if not broke then
		for _, item in ipairs(entry.parts) do
			local jolt = Vector3.new(math.random() - 0.5, math.random() * 0.4, math.random() - 0.5) * 0.35
			item.part.CFrame = item.cframe + jolt
			TweenService:Create(item.part, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = item.cframe,
			}):Play()
		end
		return
	end
	for _, item in ipairs(entry.parts) do
		if item.rock then continue end
		item.part.Size = item.size * 0.25
		item.part.Color = WHITE
		TweenService:Create(item.part, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = item.size,
			Color = item.color,
		}):Play()
	end
	local wave = piece(entry.floor * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.15, 3, 3),
		entry.color:Lerp(WHITE, 0.3), Enum.Material.Neon, Enum.PartType.Cylinder, 0.2)
	local tween = TweenService:Create(wave, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.15, 16, 16),
		Transparency = 1,
	})
	tween.Completed:Once(function() wave:Destroy() end)
	tween:Play()
end)

-- Pulso dos anéis e giro dos diamantes.
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 1 / 20 or reduced() then return end
	local step = elapsed
	elapsed = 0
	local t = os.clock()
	for index = #rings, 1, -1 do
		local ring = rings[index]
		if ring.part.Parent then
			ring.part.Transparency = 0.72 + math.sin(t * 2 + ring.phase) * 0.08
		else
			table.remove(rings, index)
		end
	end
	for index = #spinners, 1, -1 do
		local part = spinners[index]
		if part.Parent then
			part.CFrame = CFrame.new(part.Position) * CFrame.Angles(0, step * 0.8, 0) * part.CFrame.Rotation
		else
			table.remove(spinners, index)
		end
	end
end)

-- Monta a arte quando cada base existe (também com streaming).
applyQuality()
local deposits = workspace:WaitForChild("TerraNova"):WaitForChild("OreDeposits")
local function consider(object)
	if object:IsA("BasePart") and object.Name:match("^Base%d$") and object.Parent and object.Parent.Parent == deposits then
		build(object, object.Parent.Name)
	end
end
for _, object in ipairs(deposits:GetDescendants()) do consider(object) end
deposits.DescendantAdded:Connect(consider)
