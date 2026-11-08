-- Detalhes do mapa (só neste cliente): flora alienígena no chão aberto e
-- títulos de zona ao entrar em cada área. Nada colide nem recebe cliques.
-- Respeita "Efeitos do cenário" (modo de desempenho) e "Movimento reduzido".
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent:WaitForChild("VisualTheme"))
local C = Theme.Color
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local world = workspace:WaitForChild("TerraNova")

-- ---------- Flora alienígena ----------
local flora = Instance.new("Folder")
flora.Name = "GalaxyFlora"

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
	part.Parent = flora
	return part
end

local VERTICAL = CFrame.Angles(0, 0, math.rad(90))
local CAPS = { Color3.fromHex("#5B3FD1"), Color3.fromHex("#2BA6A0"), Color3.fromHex("#B0408F"), Color3.fromHex("#3D6FD8") }
local GRASS = { Color3.fromHex("#2D6E70"), Color3.fromHex("#4B3B8F"), Color3.fromHex("#2F5C8A") }
local GLOW = { Color3.fromHex("#7CF3E6"), Color3.fromHex("#FF8AD8"), Color3.fromHex("#9EB7FF") }

local kinds = {}
function kinds.mushrooms(at, rng)
	for _ = 1, rng:NextInteger(2, 4) do
		local offset = Vector3.new(rng:NextNumber(-1.4, 1.4), 0, rng:NextNumber(-1.4, 1.4))
		local height = rng:NextNumber(0.8, 2.2)
		local base = at + offset
		piece(CFrame.new(base + Vector3.new(0, height / 2, 0)) * VERTICAL, Vector3.new(height, 0.28, 0.28),
			Color3.fromHex("#D9D2F2"))
		local capSize = rng:NextNumber(1.1, 2)
		local cap = CAPS[rng:NextInteger(1, #CAPS)]
		piece(CFrame.new(base + Vector3.new(0, height, 0)), Vector3.new(capSize, capSize * 0.5, capSize), cap,
			Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		-- Pintas brilhantes: acento pequeno de neon.
		for _ = 1, 2 do
			local angle = rng:NextNumber(0, math.pi * 2)
			piece(CFrame.new(base + Vector3.new(math.cos(angle) * capSize * 0.28, height + capSize * 0.18,
				math.sin(angle) * capSize * 0.28)), Vector3.new(0.18, 0.12, 0.18), GLOW[rng:NextInteger(1, #GLOW)],
				Enum.Material.Neon, Enum.PartType.Ball)
		end
	end
end
function kinds.grass(at, rng)
	local color = GRASS[rng:NextInteger(1, #GRASS)]
	for _ = 1, rng:NextInteger(5, 8) do
		local height = rng:NextNumber(0.8, 1.8)
		local yaw = rng:NextNumber(0, math.pi * 2)
		local lean = rng:NextNumber(10, 30)
		piece(CFrame.new(at + Vector3.new(rng:NextNumber(-0.8, 0.8), 0, rng:NextNumber(-0.8, 0.8)))
			* CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.rad(lean), 0, 0) * CFrame.new(0, height / 2, 0),
			Vector3.new(0.14, height, 0.3), color:Lerp(Color3.new(1, 1, 1), rng:NextNumber(0, 0.15)))
	end
end
function kinds.crystals(at, rng)
	local color = GLOW[rng:NextInteger(1, #GLOW)]
	for _ = 1, rng:NextInteger(2, 3) do
		local height = rng:NextNumber(0.8, 1.8)
		local frame = CFrame.new(at + Vector3.new(rng:NextNumber(-0.6, 0.6), 0, rng:NextNumber(-0.6, 0.6)))
			* CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), rng:NextNumber(0, 6), math.rad(rng:NextNumber(-20, 20)))
			* CFrame.new(0, height / 2, 0)
		local crystal = piece(frame * CFrame.Angles(0, math.rad(45), 0), Vector3.new(0.4, height, 0.4),
			color:Lerp(Color3.fromHex("#1A1440"), 0.3), Enum.Material.Glass, nil, 0.2)
		crystal.Reflectance = 0.3
		piece(frame * CFrame.new(0, height / 2, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
			Vector3.new(0.26, 0.26, 0.26), color, Enum.Material.Neon)
	end
end
function kinds.lantern(at, rng)
	local height = rng:NextNumber(2.4, 3.6)
	piece(CFrame.new(at + Vector3.new(0, height / 2, 0)) * VERTICAL, Vector3.new(height, 0.16, 0.16), Color3.fromHex("#2D6E70"))
	for side = -1, 1, 2 do
		piece(CFrame.new(at + Vector3.new(side * 0.35, height * 0.45, 0)) * CFrame.Angles(0, 0, math.rad(side * -50)),
			Vector3.new(0.12, 0.5, 0.35), Color3.fromHex("#3F8F7A"))
	end
	local color = GLOW[rng:NextInteger(1, #GLOW)]
	local bulb = piece(CFrame.new(at + Vector3.new(0, height + 0.3, 0)), Vector3.new(0.7, 0.85, 0.7), color,
		Enum.Material.Neon, Enum.PartType.Ball, 0.15)
	if rng:NextNumber() < 0.35 then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 9
		light.Brightness = 0.7
		light.Parent = bulb
	end
end
local kindList = { "mushrooms", "mushrooms", "grass", "grass", "grass", "crystals", "lantern" }

-- Áreas ocupadas: caixa orientada (3D) de cada peça, num índice por células de 16 studs.
-- O teste em 3D funciona para qualquer rotação (discos e cilindros deitados inclusive).
local CELL = 16
local occupied = {}
local function cellKey(x, z) return math.floor(x / CELL) .. ":" .. math.floor(z / CELL) end
local function index(part)
	local size = part.Size
	-- O chão e os grandes anéis/faixas/penhascos do terreno (diagonal > 140) não
	-- bloqueiam: são discos decorativos cuja caixa cobriria o mapa inteiro.
	-- Caminhos (~105), crateras e construções continuam bloqueando.
	if part.Name == "Surface" or size.Magnitude > 140 then return end
	local radius = size.Magnitude / 2 + 3
	local position = part.Position
	for cx = math.floor((position.X - radius) / CELL), math.floor((position.X + radius) / CELL) do
		for cz = math.floor((position.Z - radius) / CELL), math.floor((position.Z + radius) / CELL) do
			local key = cx .. ":" .. cz
			occupied[key] = occupied[key] or {}
			table.insert(occupied[key], part)
		end
	end
end
local function blocked(point)
	local list = occupied[cellKey(point.X, point.Z)]
	if not list then return false end
	for _, part in ipairs(list) do
		if part.Parent then
			local localPoint = part.CFrame:PointToObjectSpace(point)
			local half = part.Size / 2 + Vector3.new(2.5, 2.5, 2.5)
			if math.abs(localPoint.X) < half.X and math.abs(localPoint.Y) < half.Y and math.abs(localPoint.Z) < half.Z then
				return true
			end
		end
	end
	return false
end

local function growFlora()
	for _, descendant in ipairs(world:GetDescendants()) do
		if descendant:IsA("BasePart") then index(descendant) end
	end
	local rng = Random.new(7)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	local placed, attempts = 0, 0
	while placed < 140 and attempts < 1400 do
		attempts += 1
		if attempts % 120 == 0 then task.wait() end -- espalha o trabalho entre quadros
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(36, 228)
		local x, z = math.cos(angle) * radius, math.sin(angle) * radius
		local hit = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -240, 0), params)
		-- Testa um ponto logo acima do chão (pega caminhos, crateras e bases de objetos).
		if hit and hit.Instance.Name == "Surface" and not blocked(hit.Position + Vector3.new(0, 1, 0)) then
			kinds[kindList[rng:NextInteger(1, #kindList)]](hit.Position, rng)
			placed += 1
		end
	end
end

local function applyQuality()
	flora.Parent = playerGui:GetAttribute("GalaxyLowGraphics") and nil or workspace
end
playerGui:GetAttributeChangedSignal("GalaxyLowGraphics"):Connect(applyQuality)
task.spawn(function()
	task.wait(2) -- deixa o cenário terminar de carregar
	growFlora()
	applyQuality()
end)

-- Lanternas e cogumelos "respiram" devagar (só o brilho).
local glowing = {}
task.delay(4, function()
	for _, part in ipairs(flora:GetDescendants()) do
		if part:IsA("BasePart") and part.Material == Enum.Material.Neon then
			table.insert(glowing, { part = part, base = part.Transparency, phase = math.random() * 6.28 })
		end
	end
end)
local pulseClock = 0
RunService.Heartbeat:Connect(function(dt)
	pulseClock += dt
	if pulseClock < 1 / 10 or not flora.Parent or playerGui:GetAttribute("GalaxyReduceMotion") then return end
	pulseClock = 0
	local t = os.clock()
	for _, entry in ipairs(glowing) do
		entry.part.Transparency = math.clamp(entry.base + (math.sin(t * 1.3 + entry.phase) + 1) * 0.15, 0, 1)
	end
end)

-- ---------- Títulos de zona ----------
local zones = {
	{ "Praça Central", "Ponto de chegada de Terra Nova", { "Arrival", "LandingPad" }, 20, C.Cyan },
	-- A caverna vem antes da mina: fica dentro do raio da mina.
	{ "Caverna Azul", "Um sinal estranho ecoa aqui", { "Cave", "BackWall" }, 14, C.Blue },
	{ "Mina de Terra Nova", "Ferro, cobre e cristais", { "MiningAreas", "MiningPlatform" }, 38, C.Cyan },
	{ "Loja Orion", "Ferramentas, mochilas e ovos", { "Shop", "Floor" }, 30, C.Gold },
	{ "Estação de Venda", "Troque minérios por Créditos", { "SaleStation", "Counter" }, 22, C.Gold },
	{ "Estação de Pets", "OVNI de resgate e ovos alienígenas", { "PetShop", "Terminal" }, 30, C.Pink },
	{ "Hangar Orion", "A Orion Scout aguarda", { "Hangar", "LandingPad" }, 34, C.Violet },
}

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyZone"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0.2, 0)
banner.Size = UDim2.fromOffset(520, 80)
banner.BackgroundTransparency = 1
banner.Visible = false
banner.Parent = gui
local zoneTitle = Theme.title(banner, "", 40, C.White)
zoneTitle.Size = UDim2.new(1, 0, 0, 48)
Theme.fitText(zoneTitle, 40, 18)
local zoneSubtitle = Theme.title(banner, "", 18, C.Muted)
zoneSubtitle.Position = UDim2.fromOffset(0, 48)
zoneSubtitle.Size = UDim2.new(1, 0, 0, 24)
local line = Instance.new("Frame")
line.AnchorPoint = Vector2.new(0.5, 0)
line.Position = UDim2.new(0.5, 0, 0, 46)
line.Size = UDim2.fromOffset(220, 3)
line.BorderSizePixel = 0
Theme.round(line, 2)
line.Parent = banner

local currentZone
local bannerToken = 0
local function showZone(zone)
	bannerToken += 1
	local token = bannerToken
	zoneTitle.Text = string.upper(zone[1])
	zoneTitle.TextColor3 = zone[5]:Lerp(C.White, 0.35)
	zoneSubtitle.Text = zone[2]
	line.BackgroundColor3 = zone[5]
	for _, label in ipairs({ zoneTitle, zoneSubtitle }) do
		label.TextTransparency = 0
		label.TextStrokeTransparency = 0
	end
	line.BackgroundTransparency = 0
	banner.Visible = true
	if not Theme.reducedMotion(banner) then
		line.Size = UDim2.fromOffset(0, 3)
		TweenService:Create(line, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(220, 3) }):Play()
		Theme.pop(zoneTitle, 0.15)
	end
	task.delay(2.6, function()
		if token ~= bannerToken then return end
		local fade = TweenInfo.new(0.8)
		for _, label in ipairs({ zoneTitle, zoneSubtitle }) do
			Theme.tween(label, fade, { TextTransparency = 1, TextStrokeTransparency = 1 })
		end
		Theme.tween(line, fade, { BackgroundTransparency = 1 })
		task.delay(0.85, function()
			if token == bannerToken then banner.Visible = false end
		end)
	end)
end

local zoneClock = 0
RunService.Heartbeat:Connect(function(dt)
	zoneClock += dt
	if zoneClock < 0.25 then return end
	zoneClock = 0
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or playerGui:GetAttribute("GalaxyMenuOpen") then return end
	local found
	for _, zone in ipairs(zones) do
		local group = world:FindFirstChild(zone[3][1])
		local anchor = group and group:FindFirstChild(zone[3][2])
		if anchor and anchor:IsA("BasePart") then
			local offset = root.Position - anchor.Position
			if Vector2.new(offset.X, offset.Z).Magnitude <= zone[4] then
				found = zone
				break
			end
		end
	end
	-- Só anuncia ao entrar numa zona nova (sair para o campo aberto não mostra nada).
	if found and found ~= currentZone then
		showZone(found)
	end
	currentZone = found
end)
