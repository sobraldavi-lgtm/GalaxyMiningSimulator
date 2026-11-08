-- Ferramenta de mineração visível na mão de cada jogador (só apresentação).
-- Cada cliente desenha a ferramenta de todos a partir do atributo
-- EquippedTool, publicado pelo servidor. Cinco famílias: picareta, broca,
-- martelo, lâmina e emissor; o brilho cresce com o nível da ferramenta.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ArtStyle = require(script.Parent:WaitForChild("ArtStyle"))
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local folder = Instance.new("Folder")
folder.Name = "GalaxyGear"
folder.Parent = workspace

local HANDLE = Color3.fromHex("#2A2140")
local WRAP = Color3.fromHex("#120A1E")
local WHITE = Color3.new(1, 1, 1)
local Y = CFrame.Angles(0, 0, math.rad(90)) -- deixa o eixo do cilindro na vertical

-- Monta a lista de peças em coordenadas da empunhadura (+Y = ao longo do cabo).
local function design(info)
	local parts = {}
	local accent = info.Color
	local metal = accent:Lerp(WHITE, 0.45)
	local glowing = info.Tier >= 5
	local glow = glowing and Enum.Material.Neon or Enum.Material.SmoothPlastic
	local function add(cframe, size, color, material, shape, transparency)
		table.insert(parts, { cframe = cframe, size = size, color = color, material = material or Enum.Material.SmoothPlastic,
			shape = shape or Enum.PartType.Block, transparency = transparency or 0 })
	end
	local cylinder = Enum.PartType.Cylinder
	local ball = Enum.PartType.Ball

	-- Cabo comum a todas as famílias.
	add(CFrame.new(0, 0.6, 0) * Y, Vector3.new(3, 0.3, 0.3), HANDLE, Enum.Material.SmoothPlastic, cylinder)
	add(CFrame.new(0, -0.35, 0) * Y, Vector3.new(0.25, 0.38, 0.38), WRAP, Enum.Material.Fabric, cylinder)
	add(CFrame.new(0, 0.15, 0) * Y, Vector3.new(0.25, 0.38, 0.38), WRAP, Enum.Material.Fabric, cylinder)
	add(CFrame.new(0, -0.95, 0), Vector3.new(0.45, 0.45, 0.45), accent, glow, ball)

	local family = info.Family
	if family == "pickaxe" then
		add(CFrame.new(0, 2.15, 0), Vector3.new(0.55, 0.55, 0.6), accent, Enum.Material.Metal)
		for _, side in ipairs({ -1, 1 }) do
			add(CFrame.new(side * 0.85, 2.05, 0) * CFrame.Angles(0, 0, math.rad(side * -18)),
				Vector3.new(1.4, 0.32, 0.42), metal, Enum.Material.Metal)
			add(CFrame.new(side * 1.6, 1.75, 0) * CFrame.Angles(0, 0, math.rad(side * -40)),
				Vector3.new(0.5, 0.22, 0.3), accent, glow)
		end
	elseif family == "drill" then
		add(CFrame.new(0, 1.85, 0), Vector3.new(0.75, 0.55, 0.75), accent, Enum.Material.Metal)
		local radii = { 0.7, 0.56, 0.42, 0.28 }
		for index, radius in ipairs(radii) do
			add(CFrame.new(0, 2.15 + index * 0.38, 0) * Y, Vector3.new(0.4, radius, radius),
				index % 2 == 0 and accent or metal, index % 2 == 0 and glow or Enum.Material.Metal, cylinder)
		end
		add(CFrame.new(0, 3.85, 0), Vector3.new(0.2, 0.2, 0.2), accent:Lerp(WHITE, 0.3), Enum.Material.Neon, ball)
	elseif family == "hammer" then
		add(CFrame.new(0, 2.3, 0), Vector3.new(1.6, 0.85, 0.85), accent, Enum.Material.Metal)
		add(CFrame.new(0, 2.3, 0), Vector3.new(0.4, 0.95, 0.95), metal, Enum.Material.Metal)
		for _, side in ipairs({ -1, 1 }) do
			add(CFrame.new(side * 0.84, 2.3, 0), Vector3.new(0.1, 0.6, 0.6), accent:Lerp(WHITE, 0.3), glow)
		end
	elseif family == "blade" then
		add(CFrame.new(0, 2.15, 0), Vector3.new(1.05, 0.2, 0.32), metal, Enum.Material.Metal)
		add(CFrame.new(0, 3.45, 0), Vector3.new(0.5, 2.4, 0.12), accent, glowing and Enum.Material.Neon or Enum.Material.Glass,
			nil, glowing and 0.1 or 0.15)
		add(CFrame.new(0, 4.75, 0) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.36, 0.36, 0.12), accent, glow)
		add(CFrame.new(0, 3.45, -0.07), Vector3.new(0.08, 2.2, 0.04), WHITE, Enum.Material.Neon)
	else -- laser / emissor
		add(CFrame.new(0, 2.2, 0), Vector3.new(0.65, 1.2, 0.65), metal, Enum.Material.Metal)
		add(CFrame.new(0, 3.2, 0) * Y, Vector3.new(1.2, 0.36, 0.36), HANDLE, Enum.Material.Metal, cylinder)
		for _, height in ipairs({ 2.75, 3.15, 3.55 }) do
			add(CFrame.new(0, height, 0) * Y, Vector3.new(0.1, 0.52, 0.52), accent, Enum.Material.Neon, cylinder)
		end
		add(CFrame.new(0, 3.95, 0), Vector3.new(0.42, 0.42, 0.42), accent:Lerp(WHITE, 0.25), Enum.Material.Neon, ball)
	end
	return parts
end

local rigs = {}

local function clear(player)
	local rig = rigs[player]
	if rig then
		rig.model:Destroy()
		rigs[player] = nil
	end
end

local function attach(player, celebrate)
	clear(player)
	local character = player.Character
	if not character then return end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then return end
	local info = ArtStyle.tool(player:GetAttribute("EquippedTool"))
	local gripOffset = (hand.Name == "RightHand" and CFrame.new(0, -0.3, 0) or CFrame.new(0, -1, 0))
		* CFrame.Angles(math.rad(-90), 0, 0)

	local model = Instance.new("Model")
	model.Name = player.Name .. "_" .. info.Id
	local handle
	local grip = hand.CFrame * gripOffset
	for index, spec in ipairs(design(info)) do
		local part = Instance.new("Part")
		part.Name = index == 1 and "Handle" or "Piece"
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
		part.CFrame = grip * spec.cframe
		part.Parent = model
		if index == 1 then
			handle = part
			handle:SetAttribute("Local", spec.cframe)
		else
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = part
		end
	end
	-- Solda principal com C0 animável (balanço do golpe).
	local weld = Instance.new("Weld")
	weld.Name = "GripWeld"
	weld.Part0 = hand
	weld.Part1 = handle
	weld.C0 = gripOffset
	weld.C1 = handle:GetAttribute("Local"):Inverse()
	weld.Parent = handle

	-- Brilho cresce com o nível: luz a partir do 10º, faíscas a partir do 14º.
	if info.Tier >= 10 then
		local light = Instance.new("PointLight")
		light.Color = info.Color
		light.Range = 8
		light.Brightness = 1.2
		light.Parent = handle
	end
	if info.Tier >= 14 then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dna"
		sparkle.Color = ColorSequence.new(info.Color:Lerp(WHITE, 0.4))
		sparkle.LightEmission = 1
		sparkle.Rate = 10
		sparkle.Lifetime = NumberRange.new(0.3, 0.7)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.Size = NumberSequence.new(0.25, 0)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = model:GetChildren()[#model:GetChildren()]
	end
	model.PrimaryPart = handle
	model.Parent = folder
	rigs[player] = { model = model, weld = weld, base = gripOffset }

	if celebrate then
		local burst = Instance.new("ParticleEmitter")
		burst.Texture = "rbxasset://textures/particles/sparkles_main.dna"
		burst.Color = ColorSequence.new(info.Color, WHITE)
		burst.LightEmission = 1
		burst.Rate = 0
		burst.Lifetime = NumberRange.new(0.4, 0.8)
		burst.Speed = NumberRange.new(6, 12)
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Size = NumberSequence.new(0.5, 0)
		burst.Parent = handle
		burst:Emit(30)
		Debris:AddItem(burst, 1)
	end
end

local function track(player)
	local function onCharacter(character)
		-- Espera a mão existir (R15 ou R6).
		local hand = character:WaitForChild("RightHand", 5) or character:FindFirstChild("Right Arm")
		if hand then attach(player, false) end
	end
	player.CharacterAdded:Connect(onCharacter)
	player.CharacterRemoving:Connect(function() clear(player) end)
	player:GetAttributeChangedSignal("EquippedTool"):Connect(function() attach(player, true) end)
	if player.Character then task.spawn(onCharacter, player.Character) end
end

for _, player in ipairs(Players:GetPlayers()) do track(player) end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(clear)

-- Balanço da ferramenta a cada golpe aceito do jogador local.
local swinging = false
playerGui:GetAttributeChangedSignal("GalaxySwing"):Connect(function()
	local rig = rigs[localPlayer]
	if not rig or swinging or playerGui:GetAttribute("GalaxyReduceMotion") then return end
	swinging = true
	local weld = rig.weld
	local windUp = TweenService:Create(weld, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		C0 = rig.base * CFrame.Angles(math.rad(35), 0, 0),
	})
	local strike = TweenService:Create(weld, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		C0 = rig.base * CFrame.Angles(math.rad(-40), 0, 0),
	})
	local settle = TweenService:Create(weld, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		C0 = rig.base,
	})
	windUp.Completed:Once(function() strike:Play() end)
	strike.Completed:Once(function() settle:Play() end)
	settle.Completed:Once(function() swinging = false end)
	windUp:Play()
	task.delay(0.6, function() swinging = false end)
end)
