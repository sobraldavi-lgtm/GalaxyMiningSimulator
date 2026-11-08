-- Efeitos sonoros locais da interface e da mineração (só apresentação).
-- Usa sons embutidos no Roblox (rbxasset://), sem IDs externos.
-- Desligados quando PlayerGui tem o atributo GalaxyMute.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Sound = {}

local library = {
	click = { Id = "rbxasset://sounds/button.wav", Volume = 0.35 },
	hit = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.45 },
	reward = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5 },
	open = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.25 },
}

local templates = {}
for name, entry in pairs(library) do
	local sound = Instance.new("Sound")
	sound.Name = "Galaxy_" .. name
	sound.SoundId = entry.Id
	sound.Volume = entry.Volume
	templates[name] = sound
end

local lastPlayed = {}

local function muted(): boolean
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
	return playerGui ~= nil and playerGui:GetAttribute("GalaxyMute") == true
end

-- pitch opcional (1 = normal); sons iguais em menos de 40 ms são ignorados.
function Sound.play(name: string, pitch: number?)
	local template = templates[name]
	if not template or muted() then return end
	local now = os.clock()
	if now - (lastPlayed[name] or 0) < 0.04 then return end
	lastPlayed[name] = now
	local sound = template:Clone()
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 3)
end

return Sound
