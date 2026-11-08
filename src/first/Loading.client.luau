-- Tela de carregamento do Galaxy Mining Simulator (ReplicatedFirst).
-- Roda antes dos outros scripts; por isso é autocontida (não usa VisualTheme).
-- Só apresentação: some sozinha quando o jogo terminar de carregar.
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local INK = Color3.fromHex("#05030F")
local ROYAL = Color3.fromHex("#4B2BD6")
local VIOLET = Color3.fromHex("#8B4DFF")
local GOLD = Color3.fromHex("#FFC531")
local CYAN = Color3.fromHex("#22E1FF")
local PINK = Color3.fromHex("#FF5FB8")
local WHITE = Color3.new(1, 1, 1)

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
ReplicatedFirst:RemoveDefaultLoadingScreen()

local function corner(object, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius)
	value.Parent = object
end
local function stroke(object, thickness)
	local value = Instance.new("UIStroke")
	value.Color = INK
	value.Thickness = thickness
	value.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	value.Parent = object
end

-- CanvasGroup permite esmaecer tudo de uma vez no final.
local root = Instance.new("CanvasGroup")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = WHITE
root.BorderSizePixel = 0
root.Parent = gui
local sky = Instance.new("UIGradient")
sky.Rotation = 90
sky.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#1A0F55")),
	ColorSequenceKeypoint.new(0.55, Color3.fromHex("#0B0726")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#05030F")),
})
sky.Parent = root

-- Nebulosas suaves (elipses translúcidas sobrepostas).
for _, spot in ipairs({ { 0.2, 0.3, 0.7, PINK }, { 0.82, 0.55, 0.8, CYAN }, { 0.5, 0.9, 0.9, ROYAL } }) do
	for layer = 1, 4 do
		local blob = Instance.new("Frame")
		blob.AnchorPoint = Vector2.new(0.5, 0.5)
		blob.Position = UDim2.fromScale(spot[1], spot[2])
		local size = spot[3] * (1 - (layer - 1) * 0.22)
		blob.Size = UDim2.fromScale(size, size * 0.7)
		blob.BackgroundColor3 = spot[4]
		blob.BackgroundTransparency = 0.94
		blob.BorderSizePixel = 0
		corner(blob, 999)
		blob.Parent = root
	end
end

local stars = {}
for _ = 1, 90 do
	local size = math.random(2, 4)
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(math.random(), math.random())
	dot.Size = UDim2.fromOffset(size, size)
	dot.BackgroundColor3 = ({ WHITE, CYAN, PINK, GOLD })[math.random(1, 4)]
	dot.BorderSizePixel = 0
	corner(dot, 99)
	dot.Parent = root
	table.insert(stars, { frame = dot, speed = 1 + math.random() * 3, phase = math.random() * 6.28 })
end

-- Planeta com anel e lua orbitando.
local planetHolder = Instance.new("Frame")
planetHolder.AnchorPoint = Vector2.new(0.5, 0.5)
planetHolder.Position = UDim2.fromScale(0.5, 0.36)
planetHolder.Size = UDim2.fromOffset(170, 170)
planetHolder.BackgroundTransparency = 1
planetHolder.Parent = root
local ring = Instance.new("Frame")
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Position = UDim2.fromScale(0.5, 0.5)
ring.Size = UDim2.fromOffset(280, 34)
ring.Rotation = -14
ring.BackgroundTransparency = 1
corner(ring, 99)
local ringStroke = Instance.new("UIStroke")
ringStroke.Color = GOLD
ringStroke.Thickness = 7
ringStroke.Parent = ring
ring.Parent = planetHolder
local planet = Instance.new("Frame")
planet.AnchorPoint = Vector2.new(0.5, 0.5)
planet.Position = UDim2.fromScale(0.5, 0.5)
planet.Size = UDim2.fromOffset(150, 150)
planet.BackgroundColor3 = WHITE
planet.BorderSizePixel = 0
corner(planet, 75)
stroke(planet, 5)
local planetFill = Instance.new("UIGradient")
planetFill.Rotation = 45
planetFill.Color = ColorSequence.new(PINK, VIOLET:Lerp(INK, 0.35))
planetFill.Parent = planet
planet.Parent = planetHolder
for _, spot in ipairs({ { 0.3, 0.32, 34 }, { 0.62, 0.6, 22 }, { 0.42, 0.72, 14 } }) do
	local crater = Instance.new("Frame")
	crater.AnchorPoint = Vector2.new(0.5, 0.5)
	crater.Position = UDim2.fromScale(spot[1], spot[2])
	crater.Size = UDim2.fromOffset(spot[3], spot[3])
	crater.BackgroundColor3 = WHITE
	crater.BackgroundTransparency = 0.7
	crater.BorderSizePixel = 0
	corner(crater, 99)
	crater.Parent = planet
end
-- Metade da frente do anel, por cima do planeta.
local ringFront = Instance.new("Frame")
ringFront.AnchorPoint = Vector2.new(0.5, 0)
ringFront.Position = UDim2.new(0.5, 0, 0.5, 2)
ringFront.Size = UDim2.fromOffset(250, 7)
ringFront.Rotation = -14
ringFront.BackgroundColor3 = GOLD
ringFront.BorderSizePixel = 0
corner(ringFront, 4)
ringFront.Parent = planetHolder
local moon = Instance.new("Frame")
moon.AnchorPoint = Vector2.new(0.5, 0.5)
moon.Size = UDim2.fromOffset(30, 30)
moon.BackgroundColor3 = CYAN
moon.BorderSizePixel = 0
corner(moon, 15)
stroke(moon, 3)
moon.Parent = planetHolder

local function title(text, size, color, y)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, y, 0)
	label.Size = UDim2.new(1, -40, 0, size + 10)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextStrokeColor3 = INK
	label.TextStrokeTransparency = 0
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = size
	limit.Parent = label
	label.Parent = root
	return label
end
title("GALAXY MINING", 64, GOLD, 0.56)
title("SIMULATOR", 34, CYAN, 0.56 + 0.1)

local track = Instance.new("Frame")
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.new(0.5, 0, 0.8, 0)
track.Size = UDim2.new(0.6, 0, 0, 22)
track.BackgroundColor3 = INK
track.BorderSizePixel = 0
track.ClipsDescendants = true
corner(track, 11)
stroke(track, 3)
track.Parent = root
local trackLimit = Instance.new("UISizeConstraint")
trackLimit.MaxSize = Vector2.new(460, 22)
trackLimit.Parent = track
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = WHITE
fill.BorderSizePixel = 0
corner(fill, 11)
local fillColor = Instance.new("UIGradient")
fillColor.Color = ColorSequence.new(CYAN, PINK)
fillColor.Parent = fill
fill.Parent = track
local status = title("Carregando Terra Nova… 0%", 18, WHITE, 0.8)
status.Position = UDim2.new(0.5, 0, 0.8, 28)

local tips = {
	"Dica: cada golpe no cenário também treina seu poder.",
	"Dica: a mochila tem limite de peso; venda na Estação de Venda.",
	"Dica: pets como Lumini aumentam o poder de mineração.",
	"Dica: a Loja Orion mostra a sua próxima meta em destaque.",
	"Dica: aperte B para abrir a mochila e L para a loja.",
}
local tip = title(tips[math.random(1, #tips)], 16, Color3.fromHex("#B9B0EE"), 0.92)
tip.Font = Enum.Font.GothamBold

-- Animação: estrelas cintilam, lua orbita, planeta flutua.
local started = os.clock()
local animation = RunService.RenderStepped:Connect(function()
	local t = os.clock() - started
	for _, star in ipairs(stars) do
		star.frame.BackgroundTransparency = 0.1 + 0.8 * (0.5 + 0.5 * math.sin(t * star.speed + star.phase))
	end
	local angle = t * 1.4
	moon.Position = UDim2.new(0.5, math.cos(angle) * 130, 0.5, math.sin(angle) * 22 - math.cos(angle) * 30)
	moon.ZIndex = math.sin(angle) > 0 and 3 or 0
	planetHolder.Position = UDim2.new(0.5, 0, 0.36, math.sin(t * 1.3) * 8)
end)

-- Progresso: avança suavemente até 90% enquanto carrega e completa no fim.
local progress = 0
local tipClock = os.clock()
while not game:IsLoaded() or os.clock() - started < 2.5 do
	local target = game:IsLoaded() and 1 or 0.9 - 0.5 / (1 + (os.clock() - started))
	progress += (target - progress) * 0.08
	fill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
	local queue = ContentProvider.RequestQueueSize
	status.Text = string.format("Carregando Terra Nova… %d%%%s", math.floor(progress * 100),
		queue > 0 and string.format("  ·  %d recursos", queue) or "")
	if os.clock() - tipClock > 3 then
		tipClock = os.clock()
		tip.Text = tips[math.random(1, #tips)]
	end
	task.wait()
end
fill.Size = UDim2.fromScale(1, 1)
status.Text = "Pronto! Boa mineração."
task.wait(0.4)

local fade = TweenService:Create(root, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
	GroupTransparency = 1,
})
fade.Completed:Once(function()
	animation:Disconnect()
	gui:Destroy()
end)
fade:Play()
