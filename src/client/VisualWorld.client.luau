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
dust.Color = ColorSequence.new(Color3.fromRGB(190, 160, 255), Color3.fromRGB(120, 220, 255))
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
end)

-- Pulso suave nos neons da praça (anéis e núcleos orbitais)
local world = workspace:WaitForChild("TerraNova")
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
