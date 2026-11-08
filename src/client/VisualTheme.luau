-- Design System 5.1 do Galaxy Mining Simulator — "Galáxia Profunda".
-- Botões 3D com profundidade, vidro escuro com brilho, contornos grossos,
-- céu estrelado nas janelas e efeitos animados compartilhados.
-- Só apresentação: nenhuma regra de jogo vive aqui.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Sound = require(script.Parent:WaitForChild("Sound"))

local Theme = {}

Theme.Color = table.freeze({
	-- Base escura
	Ink = Color3.fromHex("#05030F"),
	Deep = Color3.fromHex("#05030F"),
	Void = Color3.fromHex("#070418"),
	Night = Color3.fromHex("#0C0726"),
	Navy = Color3.fromHex("#120B36"),
	Plum = Color3.fromHex("#1A1048"),
	Surface = Color3.fromHex("#241670"),
	Royal = Color3.fromHex("#2E1C9E"),
	Track = Color3.fromHex("#0E0A2E"),
	-- Acentos
	Blue = Color3.fromHex("#2F7BFF"),
	Cyan = Color3.fromHex("#22E1FF"),
	Violet = Color3.fromHex("#A65BFF"),
	Pink = Color3.fromHex("#FF5FB8"),
	Mint = Color3.fromHex("#2EE59D"),
	Green = Color3.fromHex("#36D985"),
	Gold = Color3.fromHex("#FFC531"),
	Amber = Color3.fromHex("#FFB23F"),
	Orange = Color3.fromHex("#FF8A1F"),
	Red = Color3.fromHex("#FF3D57"),
	Gray = Color3.fromHex("#6E6A96"),
	-- Texto
	Frost = Color3.fromHex("#F3F7FF"),
	Text = Color3.fromHex("#F3F7FF"),
	Muted = Color3.fromHex("#B9B0EE"),
	White = Color3.new(1, 1, 1),
})
local C = Theme.Color

Theme.Font = table.freeze({
	Display = Enum.Font.FredokaOne,
	Label = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
})

Theme.Motion = table.freeze({
	Interaction = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Enter = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	Exit = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	Pop = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Count = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Float = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
})

-- ---------- Utilidades ----------

function Theme.reducedMotion(object: Instance): boolean
	local playerGui = object:FindFirstAncestorWhichIsA("PlayerGui")
	return playerGui ~= nil and playerGui:GetAttribute("GalaxyReduceMotion") == true
end

function Theme.tween(object: Instance, info: TweenInfo, properties)
	if Theme.reducedMotion(object) then
		for key, value in pairs(properties) do
			(object :: any)[key] = value
		end
		return nil
	end
	local tween = TweenService:Create(object, info, properties)
	tween:Play()
	return tween
end

-- Números no padrão brasileiro: 1.250 e 5,5.
function Theme.format(value): string
	local number = tonumber(value) or 0
	local negative = number < 0
	number = math.round(math.abs(number) * 10) / 10
	local whole = math.floor(number)
	local tenth = math.round((number - whole) * 10)
	local grouped = string.format("%d", whole)
	local count = 1
	while count > 0 do
		grouped, count = string.gsub(grouped, "^(%d+)(%d%d%d)", "%1.%2")
	end
	if tenth > 0 then
		grouped ..= "," .. tenth
	end
	return (negative and "-" or "") .. grouped
end

-- Versão curta: 1,25 mi a partir de um milhão.
function Theme.compact(value): string
	local number = tonumber(value) or 0
	if math.abs(number) < 1000000 then
		return Theme.format(number)
	end
	local text = string.format("%.2f", number / 1000000)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	text = string.gsub(text, "%.", ",")
	return text .. " mi"
end

function Theme.round(object: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
	return corner
end

function Theme.stroke(object: GuiObject, color: Color3, thickness: number, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = object
	return stroke
end

function Theme.gradient(object: GuiObject, top: Color3, bottom: Color3, rotation: number?)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation or 90
	gradient.Color = ColorSequence.new(top, bottom)
	gradient.Parent = object
	return gradient
end

function Theme.padding(object: GuiObject, pixels: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, pixels)
	padding.PaddingBottom = UDim.new(0, pixels)
	padding.PaddingLeft = UDim.new(0, pixels)
	padding.PaddingRight = UDim.new(0, pixels)
	padding.Parent = object
	return padding
end

function Theme.fitText(label: TextLabel | TextButton, maxSize: number, minSize: number?)
	label.TextScaled = true
	local limit = label:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.MinTextSize = minSize or 8
	limit.Parent = label
	return limit
end

local function scaleOf(object: GuiObject): UIScale
	local scale = object:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = object
	end
	return scale
end

function Theme.pop(object: GuiObject, strength: number?)
	if Theme.reducedMotion(object) then return end
	local scale = scaleOf(object)
	scale.Scale = 1 + (strength or 0.12)
	TweenService:Create(scale, Theme.Motion.Pop, { Scale = 1 }):Play()
end

function Theme.label(parent, text, size, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Theme.Font.Label
	label.TextColor3 = color or C.Text
	label.Text = text
	label.TextSize = size
	label.TextWrapped = true
	label.TextStrokeColor3 = C.Ink
	label.TextStrokeTransparency = (color == C.Navy or color == C.Ink) and 1 or 0.35
	label.Parent = parent
	return label
end

-- Título grande com contorno cheio, no estilo de jogo de simulador.
function Theme.title(parent, text, size, color)
	local label = Theme.label(parent, text, size, color)
	label.Font = Theme.Font.Display
	label.TextStrokeTransparency = 0
	return label
end

-- ---------- Superfícies ----------

-- Vidro escuro com brilho no topo e faixa de cor da área.
function Theme.panel(object: GuiObject, accent: Color3?, radius: number?)
	local tint = accent or C.Cyan
	object.BackgroundColor3 = Color3.new(1, 1, 1)
	object.BorderSizePixel = 0
	Theme.round(object, radius or 14)
	Theme.stroke(object, C.Ink, 3)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.Plum:Lerp(tint, 0.2)),
		ColorSequenceKeypoint.new(0.5, C.Night),
		ColorSequenceKeypoint.new(1, C.Void),
	})
	gradient.Parent = object
	-- Borda interna de neon na cor da área: brilho de holograma.
	local glow = Instance.new("Frame")
	glow.Name = "NeonEdge"
	glow.Position = UDim2.fromOffset(2, 2)
	glow.Size = UDim2.new(1, -4, 1, -4)
	glow.BackgroundTransparency = 1
	Theme.round(glow, math.max((radius or 14) - 2, 2))
	Theme.stroke(glow, tint, 1.5, 0.35)
	glow.Parent = object
	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.Position = UDim2.fromOffset(8, 3)
	gloss.Size = UDim2.new(0.5, -8, 0, 2)
	gloss.BackgroundColor3 = tint:Lerp(C.White, 0.4)
	gloss.BackgroundTransparency = 0.25
	gloss.BorderSizePixel = 0
	Theme.round(gloss, 2)
	gloss.Parent = object
end

-- Cartão rebaixado (fundo mais escuro e translúcido).
function Theme.well(object: GuiObject, radius: number?)
	object.BackgroundColor3 = C.Ink
	object.BackgroundTransparency = 0.25
	object.BorderSizePixel = 0
	Theme.round(object, radius or 14)
	Theme.stroke(object, C.Ink, 3)
end

function Theme.meter(track: Frame, fill: Frame)
	track.BackgroundColor3 = C.Ink
	track.BackgroundTransparency = 0.15
	track.BorderSizePixel = 0
	fill.BorderSizePixel = 0
	track.ClipsDescendants = true
	Theme.round(track, 99)
	Theme.round(fill, 99)
	Theme.stroke(track, C.Ink, 2)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.4, Color3.fromHex("#EEF0FF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#9AA3D8")),
	})
	gradient.Rotation = 90
	gradient.Parent = fill
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Position = UDim2.new(0, 3, 0, 1)
	shine.Size = UDim2.new(1, -6, 0.35, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.55
	shine.BorderSizePixel = 0
	Theme.round(shine, 99)
	shine.Parent = fill
end

-- Compatibilidade com a folha clara antiga.
function Theme.sheet(object: Frame)
	Theme.panel(object, C.Violet, 18)
end

-- ---------- Efeitos animados compartilhados (um único loop) ----------

local effects = { rays = {}, shimmers = {}, stars = {} }
local clock0 = os.clock()
local frame = 0

RunService.RenderStepped:Connect(function()
	local t = os.clock() - clock0
	frame += 1
	for index = #effects.rays, 1, -1 do
		local entry = effects.rays[index]
		if not entry.holder.Parent then
			table.remove(effects.rays, index)
		elseif not Theme.reducedMotion(entry.holder) then
			local angle = t * entry.speed
			for rayIndex, ray in ipairs(entry.list) do
				ray.Rotation = entry.base[rayIndex] + angle
			end
		end
	end
	for index = #effects.shimmers, 1, -1 do
		local entry = effects.shimmers[index]
		if not entry.gradient.Parent or not entry.gradient.Parent.Parent then
			table.remove(effects.shimmers, index)
		elseif Theme.reducedMotion(entry.gradient.Parent) then
			entry.gradient.Offset = Vector2.new(-2, 0)
		else
			entry.gradient.Offset = Vector2.new(((t * 0.6 + entry.phase) % 2.8) - 1.4, 0)
		end
	end
	if frame % 3 == 0 then
		for index = #effects.stars, 1, -1 do
			local entry = effects.stars[index]
			if not entry.holder.Parent then
				table.remove(effects.stars, index)
			elseif not Theme.reducedMotion(entry.holder) then
				for _, dot in ipairs(entry.dots) do
					local wave = 0.5 + 0.5 * math.sin(t * dot.speed + dot.phase)
					dot.frame.BackgroundTransparency = 0.15 + 0.75 * wave
				end
			end
		end
	end
end)

-- Raios giratórios atrás de prêmios e destaques.
function Theme.rays(parent: GuiObject, options)
	options = options or {}
	local count = options.Count or 8
	local length = options.Length or 200
	local holder = Instance.new("Frame")
	holder.Name = "Rays"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = options.Position or UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromOffset(length, length)
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local entry = { holder = holder, list = {}, base = {}, speed = options.Speed or 25 }
	for index = 0, count - 1 do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.Size = UDim2.new(0, options.Width or 22, 1, 0)
		ray.BackgroundColor3 = index % 2 == 0 and (options.Color or C.Gold) or (options.Alt or C.White)
		ray.BackgroundTransparency = options.Transparency or 0.6
		ray.BorderSizePixel = 0
		ray.Rotation = index * (180 / count)
		Theme.round(ray, 99)
		ray.Parent = holder
		table.insert(entry.list, ray)
		table.insert(entry.base, ray.Rotation)
	end
	table.insert(effects.rays, entry)
	return holder
end

-- Faixa de brilho que atravessa o elemento continuamente.
function Theme.shimmer(target: GuiObject, radius: number?)
	local overlay = Instance.new("Frame")
	overlay.Name = "Shimmer"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(1, 1, 1)
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 4
	Theme.round(overlay, radius or 12)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 20
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Offset = Vector2.new(-2, 0)
	gradient.Parent = overlay
	overlay.Parent = target
	table.insert(effects.shimmers, { gradient = gradient, phase = math.random() * 2.8 })
	return overlay
end

-- Nuvens de nebulosa: elipses translúcidas sobrepostas formam um brilho suave.
function Theme.nebula(parent: GuiObject, accent: Color3?)
	local holder = Instance.new("Frame")
	holder.Name = "Nebula"
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.ClipsDescendants = true
	holder.Parent = parent
	local colors = { accent or C.Violet, C.Pink, C.Cyan }
	for index, spot in ipairs({ { 0.18, 0.25, 0.75 }, { 0.82, 0.7, 0.85 }, { 0.55, 0.05, 0.55 } }) do
		for layer = 1, 3 do
			local blob = Instance.new("Frame")
			blob.AnchorPoint = Vector2.new(0.5, 0.5)
			blob.Position = UDim2.fromScale(spot[1], spot[2])
			local size = spot[3] * (1 - (layer - 1) * 0.28)
			blob.Size = UDim2.fromScale(size, size * 0.8)
			blob.BackgroundColor3 = colors[index]
			blob.BackgroundTransparency = 0.93
			blob.BorderSizePixel = 0
			Theme.round(blob, 999)
			blob.Parent = holder
		end
	end
	return holder
end

-- Céu estrelado cintilante ao fundo de janelas.
function Theme.starfield(parent: GuiObject, count: number?)
	local holder = Instance.new("Frame")
	holder.Name = "Stars"
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.ClipsDescendants = true
	holder.Parent = parent
	local entry = { holder = holder, dots = {} }
	for _ = 1, count or 36 do
		local size = math.random(2, 4)
		local dot = Instance.new("Frame")
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(math.random(), math.random())
		dot.Size = UDim2.fromOffset(size, size)
		dot.BackgroundColor3 = ({ C.White, C.Cyan, C.Pink, C.Gold })[math.random(1, 4)]
		dot.BackgroundTransparency = 0.4
		dot.BorderSizePixel = 0
		Theme.round(dot, 99)
		dot.Parent = holder
		table.insert(entry.dots, { frame = dot, speed = 1 + math.random() * 2.5, phase = math.random() * 6.28 })
	end
	table.insert(effects.stars, entry)
	return holder
end

-- Confete caindo do topo da tela (celebrações).
function Theme.confetti(screen: GuiObject | ScreenGui, amount: number?)
	if Theme.reducedMotion(screen) then return end
	local palette = { C.Gold, C.Pink, C.Cyan, C.Mint, C.Violet, C.Orange }
	for _ = 1, amount or 40 do
		local piece = Instance.new("Frame")
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		local x = math.random()
		piece.Position = UDim2.new(x, 0, 0, -20 - math.random(0, 120))
		piece.Size = UDim2.fromOffset(math.random(8, 14), math.random(5, 9))
		piece.BackgroundColor3 = palette[math.random(1, #palette)]
		piece.BorderSizePixel = 0
		piece.Rotation = math.random(0, 360)
		piece.ZIndex = 50
		Theme.round(piece, 2)
		piece.Parent = screen
		local duration = 1.6 + math.random() * 1.2
		TweenService:Create(piece, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(x + (math.random() - 0.5) * 0.25, 0, 1, 40),
			Rotation = piece.Rotation + math.random(-540, 540),
		}):Play()
		Debris:AddItem(piece, duration + 0.1)
	end
end

-- ---------- Ícones vetoriais (feitos de Frames, sem imagens externas) ----------

local function iconPart(parent, x, y, width, height, color, radius, angle)
	local piece = Instance.new("Frame")
	piece.Position = UDim2.fromOffset(x, y)
	piece.Size = UDim2.fromOffset(width, height)
	piece.BackgroundColor3 = color
	piece.BorderSizePixel = 0
	piece.Rotation = angle or 0
	Theme.round(piece, radius)
	piece.Parent = parent
	return piece
end

function Theme.illustration(parent, kind, accent)
	local icon = Instance.new("Frame")
	icon.Name = "Illustration"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(32, 29)
	icon.Parent = parent
	local ink = C.Navy
	local light = C.Frost
	accent = accent or C.Cyan
	if kind == "shop" then
		iconPart(icon, 6, 12, 21, 14, light, 4)
		iconPart(icon, 3, 6, 26, 9, accent, 3)
		for x = 7, 23, 8 do iconPart(icon, x, 6, 4, 9, light, 2) end
		iconPart(icon, 13, 17, 7, 9, ink, 2)
	elseif kind == "pack" then
		iconPart(icon, 11, 3, 10, 9, accent, 4)
		iconPart(icon, 6, 8, 21, 18, light, 6)
		iconPart(icon, 9, 16, 15, 7, accent, 3)
		iconPart(icon, 14, 14, 5, 4, ink, 1)
	elseif kind == "mission" then
		iconPart(icon, 8, 4, 17, 22, light, 4, 9)
		iconPart(icon, 12, 4, 8, 5, accent, 2)
		for y = 12, 20, 4 do iconPart(icon, 12, y, 9, 2, ink, 1, 9) end
	elseif kind == "settings" then
		for y = 6, 22, 8 do
			iconPart(icon, 4, y, 24, 3, light, 2)
			iconPart(icon, y == 14 and 20 or 10, y - 2, 6, 7, accent, 3)
		end
	elseif kind == "drill" then
		iconPart(icon, 8, 9, 16, 11, light, 3, -20)
		iconPart(icon, 20, 9, 10, 5, accent, 2, -20)
		iconPart(icon, 10, 17, 6, 9, accent, 2, 12)
	elseif kind == "coin" then
		iconPart(icon, 4, 2, 24, 24, accent:Lerp(ink, 0.3), 12)
		iconPart(icon, 6, 3, 20, 20, accent, 10)
		iconPart(icon, 10, 7, 12, 12, accent:Lerp(light, 0.45), 6)
		iconPart(icon, 14, 9, 4, 8, accent:Lerp(ink, 0.3), 2)
	elseif kind == "bolt" then
		iconPart(icon, 14, 1, 7, 15, accent, 2, 24)
		iconPart(icon, 10, 11, 13, 5, accent, 2)
		iconPart(icon, 12, 13, 7, 15, accent, 2, 24)
		iconPart(icon, 16, 4, 2, 7, light, 1, 24)
	elseif kind == "gem" then
		iconPart(icon, 7, 5, 18, 18, accent:Lerp(ink, 0.25), 3, 45)
		iconPart(icon, 9, 6, 14, 14, accent, 3, 45)
		iconPart(icon, 12, 8, 5, 5, light, 2, 45)
	elseif kind == "pet" then
		iconPart(icon, 8, 1, 4, 9, accent, 2, -22)
		iconPart(icon, 20, 1, 4, 9, accent, 2, 22)
		iconPart(icon, 4, 6, 24, 21, accent, 11)
		iconPart(icon, 10, 12, 5, 7, ink, 3)
		iconPart(icon, 18, 12, 5, 7, ink, 3)
		iconPart(icon, 11, 13, 2, 2, light, 1)
		iconPart(icon, 19, 13, 2, 2, light, 1)
		iconPart(icon, 13, 21, 6, 2, ink, 1)
	elseif kind == "star" then
		iconPart(icon, 8, 5, 17, 17, accent, 3)
		iconPart(icon, 8, 5, 17, 17, accent, 3, 45)
		iconPart(icon, 13, 10, 7, 7, light, 3)
	elseif kind == "lock" then
		local shackle = iconPart(icon, 10, 3, 12, 14, light, 6)
		shackle.BackgroundTransparency = 1
		Theme.stroke(shackle, light, 3)
		iconPart(icon, 7, 12, 18, 14, light, 4)
		iconPart(icon, 14, 16, 4, 6, ink, 2)
	elseif kind == "robot" then
		iconPart(icon, 15, 0, 2, 6, light, 1)
		iconPart(icon, 13, 0, 6, 4, accent, 2)
		iconPart(icon, 5, 6, 22, 18, light, 7)
		iconPart(icon, 8, 10, 16, 8, ink, 4)
		iconPart(icon, 11, 12, 3, 4, accent, 2)
		iconPart(icon, 18, 12, 3, 4, accent, 2)
	elseif kind == "pin" then
		iconPart(icon, 12, 13, 9, 9, accent, 1, 45)
		iconPart(icon, 8, 2, 16, 16, accent, 8)
		iconPart(icon, 13, 7, 6, 6, ink, 3)
	elseif kind == "target" then
		iconPart(icon, 4, 2, 24, 24, accent, 12)
		iconPart(icon, 8, 6, 16, 16, light, 8)
		iconPart(icon, 12, 10, 8, 8, accent, 4)
	elseif kind == "sound" then
		iconPart(icon, 4, 10, 8, 9, light, 2)
		iconPart(icon, 8, 6, 8, 17, light, 3, 0)
		iconPart(icon, 19, 8, 3, 13, accent, 2)
		iconPart(icon, 24, 5, 3, 19, accent, 2)
	elseif kind == "motion" then
		iconPart(icon, 3, 9, 14, 3, light, 2)
		iconPart(icon, 6, 15, 18, 3, accent, 2)
		iconPart(icon, 3, 21, 11, 3, light, 2)
		iconPart(icon, 19, 6, 10, 10, accent, 5)
	elseif kind == "sparkle" then
		iconPart(icon, 14, 2, 4, 24, accent, 2)
		iconPart(icon, 4, 12, 24, 4, accent, 2)
		iconPart(icon, 12, 10, 8, 8, light, 2, 45)
	elseif kind == "rebirth" then
		-- Seta circular: anel aberto com ponta.
		local ring = iconPart(icon, 5, 3, 22, 22, accent, 11)
		ring.BackgroundTransparency = 1
		Theme.stroke(ring, light, 4)
		iconPart(icon, 18, 0, 9, 4, light, 2, 30)
		iconPart(icon, 21, 4, 4, 8, light, 2, -20)
		iconPart(icon, 12, 10, 8, 8, accent, 4)
	elseif kind == "rocket" then
		iconPart(icon, 12, 2, 9, 20, light, 4)
		iconPart(icon, 13, 8, 6, 6, accent, 3)
		iconPart(icon, 7, 15, 5, 9, accent, 2, -15)
		iconPart(icon, 21, 15, 5, 9, accent, 2, 15)
		iconPart(icon, 13, 22, 6, 6, C.Orange, 3)
	elseif kind == "trophy" then
		iconPart(icon, 8, 3, 16, 13, accent, 6)
		iconPart(icon, 4, 5, 6, 8, accent:Lerp(ink, 0.2), 3)
		iconPart(icon, 22, 5, 6, 8, accent:Lerp(ink, 0.2), 3)
		iconPart(icon, 14, 15, 4, 6, accent, 1)
		iconPart(icon, 9, 21, 14, 5, accent:Lerp(ink, 0.25), 2)
		iconPart(icon, 12, 6, 3, 6, light, 1)
	-- Ferramentas por família
	elseif kind == "pickaxe" then
		iconPart(icon, 14, 6, 4, 23, C.Gray:Lerp(light, 0.4), 2, 35)
		iconPart(icon, 4, 4, 24, 6, accent, 3, -12)
		iconPart(icon, 3, 6, 5, 7, accent:Lerp(light, 0.4), 2, -40)
		iconPart(icon, 24, 2, 5, 7, accent:Lerp(light, 0.4), 2, 15)
	elseif kind == "hammer" then
		iconPart(icon, 14, 10, 4, 19, C.Gray:Lerp(light, 0.4), 2, 30)
		iconPart(icon, 6, 2, 20, 12, accent, 3, 30)
		iconPart(icon, 9, 4, 14, 3, accent:Lerp(light, 0.5), 1, 30)
	elseif kind == "blade" then
		iconPart(icon, 12, 18, 4, 11, C.Gray:Lerp(light, 0.4), 2, 40)
		iconPart(icon, 8, 18, 12, 4, accent:Lerp(ink, 0.2), 2, 40)
		iconPart(icon, 15, 1, 6, 21, accent, 3, 40)
		iconPart(icon, 17, 3, 2, 14, light, 1, 40)
	elseif kind == "laser" then
		iconPart(icon, 4, 9, 20, 10, light, 4)
		iconPart(icon, 7, 16, 6, 11, light, 2, -10)
		iconPart(icon, 22, 11, 8, 6, accent, 3)
		iconPart(icon, 8, 11, 12, 3, accent, 1)
		iconPart(icon, 28, 12, 4, 4, accent:Lerp(light, 0.6), 2)
	-- Minérios
	elseif kind == "nugget" then
		iconPart(icon, 4, 11, 15, 14, accent:Lerp(ink, 0.2), 6)
		iconPart(icon, 13, 5, 15, 15, accent, 7)
		iconPart(icon, 9, 16, 10, 9, accent, 4)
		iconPart(icon, 17, 8, 5, 4, light, 2)
	elseif kind == "shard" then
		iconPart(icon, 7, 6, 7, 21, accent:Lerp(ink, 0.3), 2, -18)
		iconPart(icon, 13, 2, 8, 25, accent, 2, 8)
		iconPart(icon, 20, 9, 6, 17, accent:Lerp(ink, 0.15), 2, 28)
		iconPart(icon, 15, 5, 2, 12, light, 1, 8)
	elseif kind == "diamond" then
		iconPart(icon, 5, 6, 22, 7, accent:Lerp(light, 0.35), 2)
		iconPart(icon, 9, 8, 14, 14, accent, 2, 45)
		iconPart(icon, 7, 6, 18, 6, accent:Lerp(light, 0.5), 2)
		iconPart(icon, 12, 7, 4, 3, light, 1)
	-- Variações de pet (rosto + acessório)
	elseif kind == "petRock" or kind == "petCloud" or kind == "petBolt" or kind == "petIce" or kind == "petSun" then
		if kind == "petSun" then
			for angle = 0, 315, 45 do
				local rad = math.rad(angle)
				iconPart(icon, 14 + math.cos(rad) * 12, 13 + math.sin(rad) * 12, 5, 5, C.Gold, 2, angle)
			end
		elseif kind == "petBolt" then
			iconPart(icon, 6, 0, 5, 11, C.Gold, 1, -25)
			iconPart(icon, 21, 0, 5, 11, C.Gold, 1, 25)
		elseif kind == "petIce" then
			iconPart(icon, 14, 0, 4, 9, light, 1)
			iconPart(icon, 8, 2, 4, 7, light, 1, -20)
			iconPart(icon, 20, 2, 4, 7, light, 1, 20)
		elseif kind == "petCloud" then
			iconPart(icon, 1, 12, 12, 11, accent:Lerp(light, 0.3), 6)
			iconPart(icon, 19, 12, 12, 11, accent:Lerp(light, 0.3), 6)
		elseif kind == "petRock" then
			iconPart(icon, 8, 1, 5, 8, C.Orange, 1, -15)
			iconPart(icon, 15, 0, 5, 9, C.Gold, 1, 0)
			iconPart(icon, 21, 2, 4, 7, C.Orange, 1, 15)
		end
		iconPart(icon, 5, 7, 22, 20, accent, (kind == "petRock" or kind == "petIce") and 5 or 10)
		iconPart(icon, 10, 12, 5, 7, ink, 3)
		iconPart(icon, 18, 12, 5, 7, ink, 3)
		iconPart(icon, 11, 13, 2, 2, light, 1)
		iconPart(icon, 19, 13, 2, 2, light, 1)
		iconPart(icon, 13, 21, 6, 2, ink, 1)
	end
	return icon
end

-- Ícone dentro de uma esfera brilhante com contorno grosso.
function Theme.badge(parent, kind, accent, size)
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.Size = UDim2.fromOffset(size, size)
	badge.BackgroundColor3 = Color3.new(1, 1, 1)
	badge.BorderSizePixel = 0
	Theme.round(badge, size // 2)
	Theme.stroke(badge, C.Ink, size >= 56 and 4 or 3)
	Theme.gradient(badge, accent:Lerp(C.White, 0.15):Lerp(C.Plum, 0.4), accent:Lerp(C.Ink, 0.72))
	badge.Parent = parent
	local ring = Instance.new("Frame")
	ring.Name = "NeonEdge"
	ring.Position = UDim2.fromOffset(2, 2)
	ring.Size = UDim2.new(1, -4, 1, -4)
	ring.BackgroundTransparency = 1
	Theme.round(ring, 999)
	Theme.stroke(ring, accent, 1.5, 0.3)
	ring.Parent = badge
	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.AnchorPoint = Vector2.new(0.5, 0)
	gloss.Position = UDim2.new(0.5, 0, 0.08, 0)
	gloss.Size = UDim2.fromScale(0.62, 0.3)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.78
	gloss.BorderSizePixel = 0
	Theme.round(gloss, 99)
	gloss.Parent = badge
	local icon = Theme.illustration(badge, kind, accent)
	icon.ZIndex = 2
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.52)
	local scale = Instance.new("UIScale")
	scale.Scale = (size * 0.72) / 32
	scale.Parent = icon
	return badge, icon
end

function Theme.keyHint(parent, key)
	local hint = Instance.new("TextLabel")
	hint.Name = "KeyHint"
	hint.AnchorPoint = Vector2.new(1, 0)
	hint.Position = UDim2.new(1, 5, 0, -5)
	hint.Size = UDim2.fromOffset(20, 20)
	hint.BackgroundColor3 = C.Frost
	hint.TextColor3 = C.Ink
	hint.Font = Theme.Font.Display
	hint.TextSize = 13
	hint.Text = key
	hint.ZIndex = 10
	Theme.round(hint, 6)
	Theme.stroke(hint, C.Ink, 2)
	hint.Parent = parent
	return hint
end

-- ---------- Botão 3D ----------
-- O TextButton é transparente; dentro dele há a Base (sombra sólida) e a
-- Face, que afunda ao pressionar. Use Theme.setText/setTint para alterar.

function Theme.action(parent, text, tint, options)
	options = options or {}
	local depth = options.Depth or 5
	local radius = options.Radius or 12
	local color = tint or C.Blue
	local button = Instance.new("TextButton")
	button.Name = options.Name or "Button"
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Size = options.Size or UDim2.fromOffset(140, 46)
	button:SetAttribute("BaseColor", color)

	local base = Instance.new("Frame")
	base.Name = "Base"
	base.ZIndex = 1
	base.Size = UDim2.fromScale(1, 1)
	base.BorderSizePixel = 0
	Theme.round(base, radius)
	Theme.stroke(base, C.Ink, 3)
	base.Parent = button

	local face = Instance.new("Frame")
	face.Name = "Face"
	face.ZIndex = 2
	face.Size = UDim2.new(1, 0, 1, -depth)
	face.BorderSizePixel = 0
	Theme.round(face, radius)
	Theme.stroke(face, C.Ink, 3)
	Theme.gradient(face, Color3.new(1, 1, 1), Color3.fromHex("#8E93C8"))
	face.Parent = button

	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.Position = UDim2.new(0, 6, 0, 3)
	gloss.Size = UDim2.new(1, -12, 0.36, 0)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.72
	gloss.BorderSizePixel = 0
	Theme.round(gloss, math.max(radius - 4, 3))
	gloss.Parent = face

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.ZIndex = 2
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 8, 0, 0)
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Font = Theme.Font.Display
	label.Text = text
	label.TextColor3 = C.White
	label.TextStrokeColor3 = C.Ink
	label.TextStrokeTransparency = 0
	label.TextWrapped = true
	label.Parent = face
	Theme.fitText(label, options.TextSize or 18, 8)

	if options.Icon then
		local icon = Theme.illustration(face, options.Icon, options.IconAccent or C.Frost)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 10, 0.5, 0)
		label.Position = UDim2.new(0, 46, 0, 0)
		label.Size = UDim2.new(1, -54, 1, 0)
	end

	local scale = Instance.new("UIScale")
	scale.Parent = button
	local tweens = {}
	local hovered, focused, pressed = false, false, false
	local function paint()
		local current = button:GetAttribute("BaseColor") or color
		local active = hovered or focused
		base.BackgroundColor3 = current:Lerp(C.Ink, 0.62)
		face.BackgroundColor3 = pressed and current:Lerp(C.Ink, 0.15)
			or active and current:Lerp(C.White, 0.18) or current
		for _, tween in ipairs(tweens) do tween:Cancel() end
		table.clear(tweens)
		local facePosition = UDim2.fromOffset(0, pressed and depth - 1 or 0)
		local size = pressed and 1 or active and 1.05 or 1
		if Theme.reducedMotion(button) then
			face.Position = facePosition
			scale.Scale = 1
			return
		end
		table.insert(tweens, TweenService:Create(face, Theme.Motion.Interaction, { Position = facePosition }))
		table.insert(tweens, TweenService:Create(scale, Theme.Motion.Interaction, { Scale = size }))
		for _, tween in ipairs(tweens) do tween:Play() end
	end
	button:GetAttributeChangedSignal("BaseColor"):Connect(paint)
	button.MouseEnter:Connect(function() hovered = true; paint() end)
	button.MouseLeave:Connect(function() hovered = false; pressed = false; paint() end)
	button.SelectionGained:Connect(function() focused = true; paint() end)
	button.SelectionLost:Connect(function() focused = false; pressed = false; paint() end)
	button.MouseButton1Down:Connect(function() pressed = true; paint() end)
	button.MouseButton1Up:Connect(function() pressed = false; paint() end)
	button.Activated:Connect(function()
		if not options.Silent then Sound.play("click") end
	end)
	paint()
	button.Parent = parent
	return button
end

function Theme.setTint(button: TextButton, color: Color3)
	button:SetAttribute("BaseColor", color)
end

function Theme.setText(button: TextButton, text: string)
	local face = button:FindFirstChild("Face")
	local label = face and face:FindFirstChild("Label")
	if label then label.Text = text end
end

function Theme.getLabel(button: TextButton): TextLabel?
	local face = button:FindFirstChild("Face")
	return face and face:FindFirstChild("Label") :: TextLabel?
end

-- Botão quadrado de navegação: ícone grande e legenda.
function Theme.navigationAction(parent, text, kind, accent, hotkey)
	local button = Theme.action(parent, "", accent:Lerp(C.Plum, 0.35), { Radius = 16, Depth = 6, Name = text })
	local face = button:FindFirstChild("Face")
	local icon = Theme.illustration(face, kind, accent:Lerp(C.White, 0.2))
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.42, 0)
	local iconScale = Instance.new("UIScale")
	iconScale.Name = "IconScale"
	iconScale.Scale = 1.25
	iconScale.Parent = icon
	local label = face:FindFirstChild("Label")
	label.Text = text
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -3)
	label.Size = UDim2.new(1, -6, 0, 16)
	Theme.fitText(label, 14, 7)
	if hotkey then
		Theme.keyHint(button, hotkey)
	end
	return button
end

-- Interruptor liga/desliga em linha inteira (bom para toque e controle).
function Theme.toggle(parent, text, detail, value, onChange, kind)
	local row = Instance.new("TextButton")
	row.Name = text
	row.Text = ""
	row.AutoButtonColor = false
	row.Size = UDim2.new(1, 0, 0, 70)
	Theme.panel(row, C.Mint)
	row.Parent = parent
	local left = 14
	if kind then
		local badge = Theme.badge(row, kind, C.Mint, 44)
		badge.AnchorPoint = Vector2.new(0, 0.5)
		badge.Position = UDim2.new(0, 12, 0.5, 0)
		left = 66
	end
	local title = Theme.title(row, text, 18, C.White)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(left, 9)
	title.Size = UDim2.new(1, -(left + 96), 0, 24)
	Theme.fitText(title, 18, 10)
	local hint = Theme.label(row, detail, 12, C.Muted)
	hint.Font = Theme.Font.Body
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Position = UDim2.fromOffset(left, 34)
	hint.Size = UDim2.new(1, -(left + 96), 0, 28)
	Theme.fitText(hint, 12, 8)
	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, -14, 0.5, 0)
	track.Size = UDim2.fromOffset(70, 34)
	track.BorderSizePixel = 0
	Theme.round(track, 17)
	Theme.stroke(track, C.Ink, 3)
	track.Parent = row
	local state = Theme.title(track, "", 11, C.White)
	state.Size = UDim2.fromScale(1, 1)
	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Size = UDim2.fromOffset(26, 26)
	knob.BackgroundColor3 = C.White
	knob.ZIndex = 2
	knob.BorderSizePixel = 0
	Theme.round(knob, 13)
	Theme.stroke(knob, C.Ink, 3)
	knob.Parent = track
	local function render(animate)
		local target = { Position = value and UDim2.new(1, -30, 0.5, 0) or UDim2.new(0, 4, 0.5, 0) }
		track.BackgroundColor3 = value and C.Mint or C.Gray
		state.Text = value and "ON  " or "  OFF"
		state.TextXAlignment = value and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
		state.Position = UDim2.fromOffset(value and 10 or -10, 0)
		if animate then
			Theme.tween(knob, Theme.Motion.Interaction, target)
		else
			knob.Position = target.Position
		end
	end
	row.Activated:Connect(function()
		value = not value
		onChange(value)
		render(true)
		Sound.play("click", value and 1.15 or 0.9)
	end)
	render(false)
	return row
end

-- ---------- Janela modal padrão (loja e menus) ----------
function Theme.window(parent: Instance, titleText: string, options)
	options = options or {}
	local accent = options.Accent or C.Gold
	local maxSize = options.MaxSize or Vector2.new(780, 480)

	local overlay = Instance.new("TextButton")
	overlay.Name = "Overlay"
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.Selectable = false
	overlay.BackgroundColor3 = C.Ink
	overlay.BackgroundTransparency = 0.22
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Visible = false
	overlay.ZIndex = options.ZIndex or 5
	overlay.Parent = parent

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.52)
	holder.Size = UDim2.fromScale(0.94, 0.84)
	holder.BackgroundTransparency = 1
	holder.Active = true
	holder.Parent = overlay
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = maxSize
	limit.Parent = holder
	local scale = Instance.new("UIScale")
	scale.Parent = holder

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Position = UDim2.fromOffset(0, 10)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.BackgroundColor3 = C.Ink
	shadow.BackgroundTransparency = 0.25
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 1
	Theme.round(shadow, 26)
	shadow.Parent = holder

	local window = Instance.new("Frame")
	window.Name = "Window"
	window.Size = UDim2.fromScale(1, 1)
	window.BackgroundColor3 = Color3.new(1, 1, 1)
	window.BorderSizePixel = 0
	window.Active = true
	window.ZIndex = 2
	Theme.round(window, 24)
	Theme.stroke(window, C.Ink, 5)
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.Plum:Lerp(accent, 0.1)),
		ColorSequenceKeypoint.new(0.4, C.Night),
		ColorSequenceKeypoint.new(1, C.Void),
	})
	fill.Parent = window
	window.Parent = holder
	Theme.nebula(window, accent)
	Theme.starfield(window, 70)

	-- Borda interna clara: dá acabamento de "moldura" à janela.
	local inset = Instance.new("Frame")
	inset.Name = "Inset"
	inset.Position = UDim2.fromOffset(5, 5)
	inset.Size = UDim2.new(1, -10, 1, -10)
	inset.BackgroundTransparency = 1
	Theme.round(inset, 20)
	Theme.stroke(inset, accent, 2, 0.55)
	inset.Parent = window

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.ZIndex = 3
	header.Position = UDim2.fromOffset(10, 10)
	header.Size = UDim2.new(1, -20, 0, 54)
	header.BackgroundColor3 = Color3.new(1, 1, 1)
	header.BorderSizePixel = 0
	Theme.round(header, 16)
	Theme.stroke(header, C.Ink, 3)
	Theme.gradient(header, accent:Lerp(C.Ink, 0.25), accent:Lerp(C.Ink, 0.7))
	local headerEdge = Instance.new("Frame")
	headerEdge.Name = "NeonEdge"
	headerEdge.Position = UDim2.fromOffset(2, 2)
	headerEdge.Size = UDim2.new(1, -4, 1, -4)
	headerEdge.BackgroundTransparency = 1
	Theme.round(headerEdge, 14)
	Theme.stroke(headerEdge, accent, 2, 0.2)
	headerEdge.Parent = header
	header.Parent = window
	local headerGloss = Instance.new("Frame")
	headerGloss.Position = UDim2.fromOffset(8, 4)
	headerGloss.Size = UDim2.new(1, -16, 0, 14)
	headerGloss.BackgroundColor3 = Color3.new(1, 1, 1)
	headerGloss.BackgroundTransparency = 0.85
	headerGloss.BorderSizePixel = 0
	Theme.round(headerGloss, 7)
	headerGloss.Parent = header

	local badge = Theme.badge(header, options.Icon or "star", accent, 62)
	badge.ZIndex = 2
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, -14, 0.5, 0)
	local title = Theme.title(header, titleText, 32, C.White)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(58, 2)
	title.Size = UDim2.new(1, -120, 1, -4)
	Theme.fitText(title, 32, 14)

	local close = Theme.action(header, "X", C.Red, { Size = UDim2.fromOffset(46, 46), Radius = 14, TextSize = 26, Name = "Close" })
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, -4, 0.5, 0)

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.ZIndex = 3
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(14, 74)
	body.Size = UDim2.new(1, -28, 1, -86)
	body.Parent = window

	return {
		Overlay = overlay,
		Holder = holder,
		Window = window,
		Header = header,
		Badge = badge,
		Title = title,
		Close = close,
		Body = body,
		Scale = scale,
		Closing = false,
	}
end

function Theme.openWindow(parts)
	parts.Closing = false
	parts.Overlay.Visible = true
	Sound.play("open")
	if Theme.reducedMotion(parts.Overlay) then
		parts.Scale.Scale = 1
		parts.Overlay.BackgroundTransparency = 0.22
		return
	end
	parts.Scale.Scale = 0.8
	parts.Overlay.BackgroundTransparency = 1
	TweenService:Create(parts.Scale, Theme.Motion.Pop, { Scale = 1 }):Play()
	TweenService:Create(parts.Overlay, Theme.Motion.Enter, { BackgroundTransparency = 0.22 }):Play()
end

function Theme.closeWindow(parts, onClosed)
	if parts.Closing or not parts.Overlay.Visible then return end
	parts.Closing = true
	local function finish()
		parts.Overlay.Visible = false
		parts.Closing = false
		if onClosed then onClosed() end
	end
	if Theme.reducedMotion(parts.Overlay) then
		finish()
		return
	end
	local tween = TweenService:Create(parts.Scale, Theme.Motion.Exit, { Scale = 0.88 })
	TweenService:Create(parts.Overlay, Theme.Motion.Exit, { BackgroundTransparency = 1 }):Play()
	tween.Completed:Once(finish)
	tween:Play()
end

return Theme
