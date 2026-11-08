-- Mochila de Poeira Cósmica visível nas costas de cada jogador (só apresentação).
-- Cada cliente desenha a mochila de todos a partir do atributo EquippedBackpack.
-- O visual evolui com o nível da mochila (1–20):
--   1–3   lona com bolso;            4–7   + cápsulas laterais de poeira;
--   8–11  corpo metálico e antena;   12–15 + propulsores;   16–20 lendária com halo.
-- A cápsula mostra a carga real do jogador local (outros: meia carga).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local remote = ReplicatedStorage:WaitForChild("InventoryState")
local localPlayer = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "GalaxyBackpacks"
folder.Parent = workspace

local WHITE = Color3.new(1, 1, 1)
local STRAP = Color3.fromHex("#1C1430")
local VERTICAL = CFrame.Angles(0, 0, math.rad(90)) -- eixo do cilindro na vertical

local tiers = {}
for index, backpack in ipairs(Config.Backpacks) do
	tiers[backpack.Id] = { Index = index, Color = Color3.fromHex(backpack.Color), Name = backpack.Name }
end

-- Peças em coordenadas das costas: +Z para fora, +Y para cima.
local function design(info)
	local parts = {}
	local color = info.Color
	local tier = info.Index
	local metal = tier >= 8
	local bodyMaterial = metal and Enum.Material.Metal or tier >= 4 and Enum.Material.SmoothPlastic or Enum.Material.Fabric
	local function add(name, cframe, size, partColor, material, shape, transparency)
		table.insert(parts, { name = name, cframe = cframe, size = size, color = partColor,
			material = material or Enum.Material.SmoothPlastic, shape = shape or Enum.PartType.Block,
			transparency = transparency or 0 })
	end
	local cylinder, ball = Enum.PartType.Cylinder, Enum.PartType.Ball

	add("Body", CFrame.new(0, 0, 0.35), Vector3.new(1.6, 1.9, 0.75), color:Lerp(STRAP, 0.15), bodyMaterial)
	add("Flap", CFrame.new(0, 0.82, 0.42), Vector3.new(1.68, 0.42, 0.85), color:Lerp(STRAP, 0.4), bodyMaterial)
	add("Pocket", CFrame.new(0, -0.35, 0.8), Vector3.new(1.05, 0.7, 0.22), color:Lerp(WHITE, 0.15), bodyMaterial)
	add("Buckle", CFrame.new(0, 0.55, 0.86), Vector3.new(0.28, 0.2, 0.06), Color3.fromHex("#FFC531"), Enum.Material.Metal)
	for _, side in ipairs({ -1, 1 }) do
		add("Strap", CFrame.new(side * 0.5, 0.95, -0.05), Vector3.new(0.2, 0.18, 0.75), STRAP, Enum.Material.Fabric)
	end
	if tier >= 4 then
		-- Cápsulas de poeira cósmica: vidro com o enchimento colorido dentro.
		for _, side in ipairs({ -1, 1 }) do
			add("Capsule", CFrame.new(side * 0.98, -0.05, 0.4) * VERTICAL, Vector3.new(1.4, 0.48, 0.48),
				WHITE, Enum.Material.Glass, cylinder, 0.55)
			add("CapsuleCap", CFrame.new(side * 0.98, 0.72, 0.4) * VERTICAL, Vector3.new(0.12, 0.56, 0.56),
				color:Lerp(STRAP, 0.3), Enum.Material.Metal, cylinder)
			add("Dust" .. side, CFrame.new(side * 0.98, -0.05, 0.4) * VERTICAL, Vector3.new(1.3, 0.38, 0.38),
				color:Lerp(WHITE, 0.25), Enum.Material.Neon, cylinder, 0.15)
		end
	end
	if tier >= 8 then
		add("Antenna", CFrame.new(0.55, 1.45, 0.3), Vector3.new(0.08, 0.9, 0.08), Color3.fromHex("#C9D4E8"), Enum.Material.Metal)
		add("AntennaTip", CFrame.new(0.55, 1.95, 0.3), Vector3.new(0.2, 0.2, 0.2), color:Lerp(WHITE, 0.3), Enum.Material.Neon, ball)
		add("Panel", CFrame.new(0, 0.15, 0.73), Vector3.new(1.2, 0.08, 0.04), color:Lerp(WHITE, 0.4), Enum.Material.Neon)
	end
	if tier >= 12 then
		for _, side in ipairs({ -1, 1 }) do
			add("Thruster", CFrame.new(side * 0.45, -1.15, 0.4) * VERTICAL, Vector3.new(0.45, 0.42, 0.42),
				Color3.fromHex("#3A3550"), Enum.Material.Metal, cylinder)
			add("Flame" .. side, CFrame.new(side * 0.45, -1.45, 0.4), Vector3.new(0.28, 0.28, 0.28),
				Color3.fromHex("#FFB03A"), Enum.Material.Neon, ball, 0.2)
		end
	end
	if tier >= 16 then
		add("Halo", CFrame.new(0, 0.2, 0.4) * CFrame.Angles(math.rad(90), 0, 0) * VERTICAL,
			Vector3.new(0.06, 2.6, 2.6), color:Lerp(WHITE, 0.4), Enum.Material.Neon, cylinder, 0.35)
		add("Gem", CFrame.new(0, -0.35, 0.93) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.3, 0.3, 0.1),
			Color3.fromHex("#FFE066"), Enum.Material.Neon)
	end
	return parts
end

local rigs = {}
local localRatio = 0.5

local function clear(player)
	local rig = rigs[player]
	if rig then
		rig.model:Destroy()
		rigs[player] = nil
	end
end

-- Ajusta a altura da poeira dentro das cápsulas (0–1).
local function setFill(rig, ratio)
	for _, entry in ipairs(rig.dust) do
		local height = 0.08 + 1.22 * math.clamp(ratio, 0, 1)
		entry.part.Size = Vector3.new(height, entry.part.Size.Y, entry.part.Size.Z)
		-- Cilindro deitado no eixo X local; mantém a base no fundo da cápsula.
		entry.weld.C0 = entry.base * CFrame.new(0, -0.65 + height / 2, 0) * VERTICAL
	end
end

local function attach(player)
	clear(player)
	local character = player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	local info = tiers[player:GetAttribute("EquippedBackpack") or Config.StartingBackpack]
	if not torso or not torso:IsA("BasePart") or not info then return end
	local model = Instance.new("Model")
	model.Name = player.Name .. "_Backpack"
	local back = torso.CFrame * CFrame.new(0, 0.1, torso.Size.Z / 2)
	local rig = { model = model, dust = {}, flames = {}, tips = {} }
	for _, spec in ipairs(design(info)) do
		local part = Instance.new("Part")
		part.Name = spec.name
		part.Anchored = false
		part.Massless = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Shape = spec.shape
		part.Size = spec.size
		part.Color = spec.color
		part.Material = spec.material
		part.Transparency = spec.transparency
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		-- Weld manual: permite mover a poeira dentro da cápsula depois.
		local weld = Instance.new("Weld")
		weld.Part0 = torso
		weld.Part1 = part
		weld.C0 = CFrame.new(0, 0.1, torso.Size.Z / 2) * spec.cframe
		weld.Parent = part
		part.CFrame = back * spec.cframe
		if spec.name:match("^Dust") then
			local x = spec.cframe.Position.X
			table.insert(rig.dust, { part = part, weld = weld,
				base = CFrame.new(0, 0.1, torso.Size.Z / 2) * CFrame.new(x, -0.05, 0.4) })
		elseif spec.name:match("^Flame") then
			table.insert(rig.flames, part)
		elseif spec.name == "AntennaTip" then
			table.insert(rig.tips, part)
		end
	end
	model.Parent = folder
	rigs[player] = rig
	setFill(rig, player == localPlayer and localRatio or 0.5)
end

local function track(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("UpperTorso", 5)
		attach(player)
	end)
	player.CharacterRemoving:Connect(function() clear(player) end)
	player:GetAttributeChangedSignal("EquippedBackpack"):Connect(function() attach(player) end)
	if player.Character then task.spawn(attach, player) end
end
for _, player in ipairs(Players:GetPlayers()) do track(player) end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(clear)

-- Carga do jogador local enche a cápsula.
remote.OnClientEvent:Connect(function(snapshot)
	if not snapshot.Capacity or snapshot.Capacity <= 0 then return end
	localRatio = snapshot.Weight / snapshot.Capacity
	local rig = rigs[localPlayer]
	if rig then setFill(rig, localRatio) end
end)

-- Chamas tremulam e a antena pisca (leve, 15 Hz).
local elapsed = 0
local playerGui = localPlayer:WaitForChild("PlayerGui")
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 1 / 15 then return end
	elapsed = 0
	if playerGui:GetAttribute("GalaxyReduceMotion") or playerGui:GetAttribute("GalaxyLowGraphics") then return end
	local t = os.clock()
	for _, rig in pairs(rigs) do
		for _, flame in ipairs(rig.flames) do
			flame.Transparency = 0.1 + math.random() * 0.4
		end
		for _, tip in ipairs(rig.tips) do
			tip.Transparency = (math.floor(t * 2) % 2 == 0) and 0 or 0.7
		end
	end
end)
