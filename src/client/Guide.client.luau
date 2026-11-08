-- Guia de objetivo: feixe do personagem até o alvo da missão atual e um
-- marcador com nome e distância. Mochila cheia tem prioridade (vá vender).
-- Só apresentação; o servidor continua validando cada ação no local certo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Theme = require(script.Parent:WaitForChild("VisualTheme"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local remote = ReplicatedStorage:WaitForChild("InventoryState")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local C = Theme.Color

local ARRIVE_DISTANCE = 14

-- Onde fica o alvo de cada tipo de missão (caminhos dentro de TerraNova).
local missionTargets = {
	Sell = { "SaleStation", "Counter", "Estação de Venda" },
	Buy = { "Shop", "PurchaseDesk", "Loja Orion" },
	Pet = { "PetShop", "Terminal", "OVNI de resgate" },
	Transmitter = { "Cave", "Transmitter", "Transmissor da caverna" },
}

local function find(group, name)
	local world = workspace:FindFirstChild("TerraNova")
	local folder = world and world:FindFirstChild(group)
	return folder and folder:FindFirstChild(name)
end

-- Depósito mais próximo de um tipo de minério.
local function nearestDeposit(oreType, origin)
	local world = workspace:FindFirstChild("TerraNova")
	local deposits = world and world:FindFirstChild("OreDeposits")
	local folder = deposits and deposits:FindFirstChild(oreType)
	if not folder then return nil end
	local best, bestDistance
	for _, part in ipairs(folder:GetChildren()) do
		if part:IsA("BasePart") and part.Name:match("^Base%d$") then
			local distance = (part.Position - origin).Magnitude
			if not bestDistance or distance < bestDistance then
				best, bestDistance = part, distance
			end
		end
	end
	return best
end

-- ---------- Feixe e marcador ----------
local targetAttachment = Instance.new("Attachment")
targetAttachment.Name = "GalaxyGuideTarget"
local sourceAttachment = Instance.new("Attachment")
sourceAttachment.Name = "GalaxyGuideSource"
sourceAttachment.Position = Vector3.new(0, -1.5, 0)

local beam = Instance.new("Beam")
beam.Name = "GalaxyGuide"
beam.Attachment0 = sourceAttachment
beam.Attachment1 = targetAttachment
beam.FaceCamera = true
beam.Segments = 24
beam.Width0 = 0.6
beam.Width1 = 0.6
beam.CurveSize0 = 6
beam.CurveSize1 = -6
beam.LightEmission = 0.4
beam.LightInfluence = 0
beam.Texture = "rbxasset://textures/particles/sparkles_main.dna"
beam.TextureMode = Enum.TextureMode.Static
beam.TextureLength = 3
beam.TextureSpeed = 1.5
beam.Color = ColorSequence.new(C.Cyan, C.Gold)
beam.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.85),
	NumberSequenceKeypoint.new(0.2, 0.35),
	NumberSequenceKeypoint.new(0.85, 0.35),
	NumberSequenceKeypoint.new(1, 0.9),
})
beam.Enabled = false

local marker = Instance.new("BillboardGui")
marker.Name = "GalaxyGuideMarker"
marker.AlwaysOnTop = true
marker.Size = UDim2.fromOffset(220, 74)
marker.StudsOffset = Vector3.new(0, 5, 0)
marker.LightInfluence = 0
marker.ResetOnSpawn = false
marker.Enabled = false
marker.Parent = playerGui
local card = Instance.new("Frame")
card.Position = UDim2.fromOffset(30, 6)
card.Size = UDim2.new(1, -34, 0, 46)
Theme.panel(card, C.Gold, 23)
card.Parent = marker
local pin = Theme.badge(card, "pin", C.Gold, 52)
pin.AnchorPoint = Vector2.new(0, 0.5)
pin.Position = UDim2.new(0, -26, 0.5, 0)
pin.ZIndex = 3
local label = Theme.title(card, "", 15, C.White)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Position = UDim2.fromOffset(32, 3)
label.Size = UDim2.new(1, -40, 0, 22)
Theme.fitText(label, 15, 9)
local distanceLabel = Theme.title(card, "", 12, C.Gold)
distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
distanceLabel.Position = UDim2.fromOffset(32, 24)
distanceLabel.Size = UDim2.new(1, -40, 0, 16)
-- Seta descendo até o alvo.
local arrow = Instance.new("Frame")
arrow.AnchorPoint = Vector2.new(0.5, 0)
arrow.Position = UDim2.new(0.5, 15, 0, 54)
arrow.Size = UDim2.fromOffset(16, 16)
arrow.Rotation = 45
arrow.BackgroundColor3 = C.Gold
arrow.BorderSizePixel = 0
Theme.round(arrow, 3)
Theme.stroke(arrow, C.Ink, 2)
arrow.Parent = marker

-- ---------- Estado ----------
local state
remote.OnClientEvent:Connect(function(snapshot)
	state = snapshot
end)

-- Decide o alvo a partir do estado mais recente.
local function resolve(origin)
	if not state then return nil end
	if state.Weight >= state.Capacity then
		local counter = find("SaleStation", "Counter")
		return counter, "Mochila cheia: venda aqui"
	end
	local mission = Config.Missions[state.MissionIndex]
	if not mission then
		-- Depois da campanha: guia até o minério de um contrato de mineração.
		for _, contract in ipairs(state.Contracts or {}) do
			if contract.Kind == "Mine" then
				local ore = Config.Ores[contract.Target]
				return nearestDeposit(contract.Target, origin), "Contrato: " .. (ore and ore.Name or "minério")
			end
		end
		return nil
	end
	if mission.Kind == "Mine" then
		return nearestDeposit(mission.Target, origin), mission.Goal
	end
	if mission.Kind == "Transmitter" and state.Level < Config.Progression.CaveLevel then
		-- Antes do nível da caverna, o caminho é minerar para ganhar XP.
		return find("MiningAreas", "MiningPlatform"),
			"Minere para chegar ao nível " .. Config.Progression.CaveLevel
	end
	local spec = missionTargets[mission.Kind]
	if not spec then return nil end
	return find(spec[1], spec[2]), mission.Goal
end

local elapsed = 0
local bob = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	bob += dt
	if elapsed < 0.1 then return end
	elapsed = 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hidden = playerGui:GetAttribute("GalaxyHideGuide") or playerGui:GetAttribute("GalaxyMenuOpen")
	local target, text
	if root and not hidden then
		target, text = resolve(root.Position)
	end
	local distance = target and root and (target.Position - root.Position).Magnitude or 0
	local show = target ~= nil and distance > ARRIVE_DISTANCE
	beam.Enabled = show
	marker.Enabled = show
	if not show then return end
	if sourceAttachment.Parent ~= root then
		sourceAttachment.Parent = root
		beam.Parent = root
	end
	if targetAttachment.Parent ~= target then
		targetAttachment.Parent = target
		marker.Adornee = target
	end
	label.Text = text
	distanceLabel.Text = math.floor(distance) .. " m"
	if not Theme.reducedMotion(marker) then
		marker.StudsOffset = Vector3.new(0, 5 + math.sin(bob * 3) * 0.4, 0)
	end
end)
