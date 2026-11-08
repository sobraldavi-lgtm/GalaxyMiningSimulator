-- Placares no mundo (Top 10). O servidor publica os dados em
-- ReplicatedStorage.LeaderboardData; aqui só desenhamos as telas.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Theme = require(script.Parent:WaitForChild("VisualTheme"))
local C = Theme.Color
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local data = ReplicatedStorage:WaitForChild("LeaderboardData", 60)
local folder = workspace:WaitForChild("TerraNova"):WaitForChild("Leaderboards", 60)
if not data or not folder then return end

local boards = {
	{ Part = "BoardLifetime", Key = "Lifetime", Title = "TOP MINERADORES", Subtitle = "Créditos ganhos em vendas",
		Accent = C.Gold, Icon = "coin", Format = function(value) return "✦ " .. Theme.compact(value) end },
	{ Part = "BoardRebirths", Key = "Rebirths", Title = "TOP RENASCIMENTOS", Subtitle = "Quem mais renasceu",
		Accent = C.Pink, Icon = "rebirth", Format = function(value) return Theme.format(value) .. "×" end },
}
local MEDALS = { Color3.fromHex("#FFC531"), Color3.fromHex("#D7DEEA"), Color3.fromHex("#E08A4B") }

local function build(spec, part)
	local surface = Instance.new("SurfaceGui")
	surface.Name = spec.Key .. "Board"
	surface.Adornee = part
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 50
	surface.LightInfluence = 0
	surface.Brightness = 1.4
	surface.ResetOnSpawn = false
	surface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	surface.Parent = playerGui

	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = C.White
	root.BorderSizePixel = 0
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new(C.Plum:Lerp(spec.Accent, 0.12), C.Void)
	fill.Parent = root
	root.Parent = surface
	Theme.nebula(root, spec.Accent)
	Theme.starfield(root, 40)

	local header = Instance.new("Frame")
	header.Position = UDim2.fromOffset(16, 14)
	header.Size = UDim2.new(1, -32, 0, 80)
	Theme.panel(header, spec.Accent, 20)
	header.Parent = root
	local badge = Theme.badge(header, spec.Icon, spec.Accent, 72)
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, 8, 0.5, 0)
	local title = Theme.title(header, spec.Title, 40, spec.Accent)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(92, 4)
	title.Size = UDim2.new(1, -104, 0, 46)
	Theme.fitText(title, 40, 16)
	local subtitle = Theme.title(header, spec.Subtitle, 20, C.Muted)
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Position = UDim2.fromOffset(92, 48)
	subtitle.Size = UDim2.new(1, -104, 0, 24)

	local rows = {}
	for rank = 1, 10 do
		local row = Instance.new("Frame")
		row.Position = UDim2.new(0, 16, 0, 104 + (rank - 1) * 32)
		row.Size = UDim2.new(1, -32, 0, 28)
		row.BackgroundColor3 = C.Ink
		row.BackgroundTransparency = rank % 2 == 0 and 0.5 or 0.3
		row.BorderSizePixel = 0
		Theme.round(row, 14)
		row.Parent = root
		local medal = Theme.title(row, tostring(rank), 18, rank <= 3 and C.Ink or C.White)
		medal.BackgroundColor3 = MEDALS[rank] or C.Plum
		medal.TextStrokeTransparency = rank <= 3 and 1 or 0
		medal.Position = UDim2.fromOffset(4, 2)
		medal.Size = UDim2.fromOffset(40, 24)
		Theme.round(medal, 12)
		local name = Theme.title(row, "—", 18, C.White)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Position = UDim2.fromOffset(56, 0)
		name.Size = UDim2.new(1, -220, 1, 0)
		Theme.fitText(name, 18, 10)
		local value = Theme.title(row, "", 18, spec.Accent)
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.AnchorPoint = Vector2.new(1, 0)
		value.Position = UDim2.new(1, -12, 0, 0)
		value.Size = UDim2.fromOffset(160, 28)
		rows[rank] = { name = name, value = value, row = row }
	end

	local function refresh()
		local ok, list = pcall(function()
			return HttpService:JSONDecode(data:GetAttribute(spec.Key) or "[]")
		end)
		list = ok and list or {}
		for rank, entry in ipairs(rows) do
			local item = list[rank]
			entry.name.Text = item and item.Name or "—"
			entry.value.Text = item and spec.Format(item.Value) or ""
			entry.row.BackgroundTransparency = item and (rank % 2 == 0 and 0.5 or 0.3) or 0.75
		end
	end
	data:GetAttributeChangedSignal(spec.Key):Connect(refresh)
	refresh()
end

for _, spec in ipairs(boards) do
	task.spawn(function()
		local part = folder:WaitForChild(spec.Part, 60)
		if part then build(spec, part) end
	end)
end
