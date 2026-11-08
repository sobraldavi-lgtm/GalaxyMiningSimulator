-- Polimento visual dos depósitos: brilho, luz e partículas. Não altera regras de jogo.
local looks = {
	Iron = { color = Color3.fromRGB(190, 215, 255), neon = false },
	Copper = { color = Color3.fromRGB(255, 150, 80), neon = false },
	Crystal = { color = Color3.fromRGB(60, 170, 255), neon = true },
}

local deposits = workspace:WaitForChild("TerraNova"):WaitForChild("OreDeposits")
for oreType, look in pairs(looks) do
	local folder = deposits:WaitForChild(oreType)
	for _, part in ipairs(folder:GetChildren()) do
		if part:IsA("BasePart") and part.Name:match("^Sample") then
			part.Color = look.color
			if look.neon then
				part.Material = Enum.Material.Neon
				part.Transparency = 0.15
			else
				part.Material = Enum.Material.Metal
				part.Reflectance = 0.25
			end

			local light = Instance.new("PointLight")
			light.Color = look.color
			light.Brightness = look.neon and 2 or 0.6
			light.Range = look.neon and 14 or 8
			light.Shadows = false
			light.Parent = part

			local sparkle = Instance.new("ParticleEmitter")
			sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dna"
			sparkle.Color = ColorSequence.new(look.color)
			sparkle.LightEmission = 1
			sparkle.Rate = look.neon and 6 or 2
			sparkle.Lifetime = NumberRange.new(1, 2)
			sparkle.Speed = NumberRange.new(0.3, 1)
			sparkle.SpreadAngle = Vector2.new(180, 180)
			sparkle.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0.4),
				NumberSequenceKeypoint.new(1, 0),
			})
			sparkle.Parent = part
		end
	end
end
