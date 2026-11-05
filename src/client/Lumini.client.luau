local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local model
local function updateCompanion()
	if model then
		model:Destroy()
		model = nil
	end
	if not player:GetAttribute("LuminiEquipped") then
		return
	end

	local companion = Instance.new("Model")
	companion.Name = "Lumini"
	local function orb(name, size, position, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = Enum.PartType.Ball
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
	local blue = Color3.fromRGB(85, 181, 255)
	local dark = Color3.fromRGB(20, 31, 58)
	companion.PrimaryPart = orb("Corpo", Vector3.new(1.6, 1.4, 1.4), Vector3.zero, blue, Enum.Material.SmoothPlastic)
	for _, side in ipairs({ -1, 1 }) do
		orb("Olho", Vector3.new(0.24, 0.33, 0.18), Vector3.new(side * 0.32, 0.12, -0.62), dark, Enum.Material.SmoothPlastic)
		orb("Antena", Vector3.new(0.31, 0.65, 0.31), Vector3.new(side * 0.43, 0.71, 0), blue, Enum.Material.Neon)
	end
	model = companion
end

player:GetAttributeChangedSignal("LuminiEquipped"):Connect(updateCompanion)
updateCompanion()

RunService.RenderStepped:Connect(function(dt)
	if not model then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		model.Parent = nil
		return
	end
	local offset = CFrame.new(2.7, 0.9 + math.sin(os.clock() * 3) * 0.22, 1.9)
	local destination = root.CFrame * offset
	if not model.Parent or (model:GetPivot().Position - destination.Position).Magnitude > 24 then
		model:PivotTo(destination)
		model.Parent = workspace
	else
		model:PivotTo(model:GetPivot():Lerp(destination, 1 - math.exp(-9 * dt)))
	end
end)
