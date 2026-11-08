-- Companheiro visual do pet equipado. O bônus de poder é aplicado pelo servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local player = Players.LocalPlayer

local dark = Color3.fromRGB(20, 31, 58)
local model

local function newPart(companion, name, shape, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = companion
	return part
end
local Ball, Block = Enum.PartType.Ball, Enum.PartType.Block
local Smooth, Neon = Enum.Material.SmoothPlastic, Enum.Material.Neon

local function eyes(companion, y, z, spread)
	for _, side in ipairs({ -1, 1 }) do
		newPart(companion, "Olho", Ball, Vector3.new(0.24, 0.33, 0.18), Vector3.new(side * spread, y, z), dark, Smooth)
	end
end

local builders = {}
function builders.blob(c, color)
	local body = newPart(c, "Corpo", Ball, Vector3.new(1.6, 1.4, 1.4), Vector3.zero, color, Smooth)
	eyes(c, 0.12, -0.62, 0.32)
	for _, side in ipairs({ -1, 1 }) do
		newPart(c, "Antena", Ball, Vector3.new(0.31, 0.65, 0.31), Vector3.new(side * 0.43, 0.71, 0), color, Neon)
	end
	return body
end
function builders.rock(c, color)
	local body = newPart(c, "Corpo", Block, Vector3.new(1.5, 1.3, 1.4), Vector3.zero, color, Enum.Material.Slate)
	eyes(c, 0.15, -0.72, 0.3)
	for i, x in ipairs({ -0.4, 0.1, 0.5 }) do
		local crystal = newPart(c, "Cristal", Block, Vector3.new(0.25, 0.5 + i * 0.1, 0.25),
			Vector3.new(x, 0.85, 0.1), Color3.fromRGB(255, 190, 90), Neon)
		crystal.CFrame = crystal.CFrame * CFrame.Angles(0, 0, math.rad(8 * (i - 2)))
	end
	return body
end
function builders.cloud(c, color)
	local body = newPart(c, "Corpo", Ball, Vector3.new(1.5, 1.2, 1.3), Vector3.zero, color, Neon)
	body.Transparency = 0.25
	newPart(c, "Nuvem", Ball, Vector3.new(1, 0.9, 0.9), Vector3.new(-0.65, -0.1, 0), color, Neon).Transparency = 0.35
	newPart(c, "Nuvem", Ball, Vector3.new(1, 0.9, 0.9), Vector3.new(0.65, -0.1, 0), color, Neon).Transparency = 0.35
	eyes(c, 0.1, -0.58, 0.3)
	return body
end
function builders.bolt(c, color)
	local body = newPart(c, "Corpo", Ball, Vector3.new(1.3, 1.3, 1.3), Vector3.zero, color, Smooth)
	eyes(c, 0.1, -0.55, 0.28)
	for _, side in ipairs({ -1, 1 }) do
		local ear = newPart(c, "Orelha", Block, Vector3.new(0.2, 0.9, 0.2), Vector3.new(side * 0.4, 0.95, 0), color, Neon)
		ear.CFrame = ear.CFrame * CFrame.Angles(0, 0, math.rad(-side * 15))
	end
	local spark = Instance.new("ParticleEmitter")
	spark.Texture = "rbxasset://textures/particles/sparkles_main.dna"
	spark.Color = ColorSequence.new(color)
	spark.LightEmission = 1
	spark.Rate = 8
	spark.Lifetime = NumberRange.new(0.4, 0.8)
	spark.Speed = NumberRange.new(1, 2)
	spark.SpreadAngle = Vector2.new(180, 180)
	spark.Size = NumberSequence.new(0.3, 0)
	spark.Parent = body
	return body
end
function builders.ice(c, color)
	local body = newPart(c, "Corpo", Block, Vector3.new(1.3, 1.3, 1.3), Vector3.zero, color, Enum.Material.Ice)
	body.Transparency = 0.15
	eyes(c, 0.1, -0.68, 0.28)
	newPart(c, "Pico", Block, Vector3.new(0.3, 0.7, 0.3), Vector3.new(0, 1, 0), Color3.fromRGB(220, 250, 255), Neon)
	return body
end
function builders.sun(c, color)
	local body = newPart(c, "Corpo", Ball, Vector3.new(1.5, 1.5, 1.5), Vector3.zero, color, Neon)
	eyes(c, 0.1, -0.68, 0.3)
	local ring = newPart(c, "Anel", Enum.PartType.Cylinder, Vector3.new(0.12, 2.3, 2.3), Vector3.zero,
		Color3.fromRGB(255, 226, 120), Neon)
	ring.CFrame = ring.CFrame * CFrame.Angles(0, 0, math.rad(90))
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 1.5
	light.Parent = body
	return body
end

local function find(id)
	for _, pet in ipairs(Config.Pets) do
		if pet.Id == id then return pet end
	end
end

local function update()
	if model then
		model:Destroy()
		model = nil
	end
	local pet = find(player:GetAttribute("EquippedPet"))
	if not pet then return end
	local companion = Instance.new("Model")
	companion.Name = pet.Name
	local color = Color3.fromHex(pet.Color)
	companion.PrimaryPart = builders[pet.Look](companion, color)
	-- Etiqueta com o nome, na cor do pet (só visual).
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.fromOffset(120, 26)
	tag.StudsOffset = Vector3.new(0, 1.7, 0)
	tag.MaxDistance = 45
	tag.LightInfluence = 0
	tag.Parent = companion.PrimaryPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 18
	label.Text = pet.Name
	label.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.35)
	label.TextStrokeColor3 = Color3.fromHex("#0A0630")
	label.TextStrokeTransparency = 0
	label.Parent = tag
	model = companion
end
player:GetAttributeChangedSignal("EquippedPet"):Connect(update)
update()

RunService.RenderStepped:Connect(function(dt)
	if not model then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		model.Parent = nil
		return
	end
	local destination = root.CFrame * CFrame.new(2.7, 0.9 + math.sin(os.clock() * 3) * 0.22, 1.9)
	if not model.Parent or (model:GetPivot().Position - destination.Position).Magnitude > 24 then
		model:PivotTo(destination)
		model.Parent = workspace
	else
		model:PivotTo(model:GetPivot():Lerp(destination, 1 - math.exp(-9 * dt)))
	end
end)
