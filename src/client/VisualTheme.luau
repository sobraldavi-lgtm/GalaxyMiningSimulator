-- Design System 4.0 do Galaxy Mining Simulator.
-- Só apresentação: nenhuma regra de jogo vive aqui.
local TweenService = game:GetService("TweenService")
local Theme = {}

Theme.Color = table.freeze({
	Navy = Color3.fromHex("#1B1250"),
	Blue = Color3.fromHex("#2F7BFF"),
	Cyan = Color3.fromHex("#00D8FF"),
	Violet = Color3.fromHex("#A855F7"),
	Amber = Color3.fromHex("#FFCA3A"),
	Green = Color3.fromHex("#36D985"),
	Frost = Color3.fromHex("#EAF4FF"),
	Text = Color3.fromHex("#EDF4FF"),
	Track = Color3.fromHex("#273857"),
	Deep = Color3.fromHex("#0A0630"),
	Surface = Color3.fromHex("#4B2BB8"),
	Gold = Color3.fromHex("#FFB800"),
	Mint = Color3.fromHex("#2FD16B"),
	Red = Color3.fromHex("#FF3B4E"),
	Pink = Color3.fromHex("#FF6FB5"),
	Gray = Color3.fromHex("#6B6F8F"),
	Muted = Color3.fromHex("#B7AEE8"),
	White = Color3.new(1, 1, 1),
})

-- Display arredondada (cartunesca) para títulos e números; Gotham para leitura.
Theme.Font = table.freeze({
	Display = Enum.Font.FredokaOne,
	Label = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
})

Theme.Motion = table.freeze({
	Interaction = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Enter = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	Exit = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	Pop = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Count = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Float = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
})

-- ---------- Utilidades ----------

function Theme.reducedMotion(object: Instance): boolean
	local playerGui = object:FindFirstAncestorWhichIsA("PlayerGui")
	return playerGui ~= nil and playerGui:GetAttribute("GalaxyReduceMotion") == true
end

-- Aplica as propriedades com animação, ou diretamente com movimento reduzido.
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
	local digits = string.format("%d", whole)
	local grouped = digits
	local count = 1
	while count > 0 do
		grouped, count = string.gsub(grouped, "^(%d+)(%d%d%d)", "%1.%2")
	end
	if tenth > 0 then
		grouped ..= "," .. tenth
	end
	return (negative and "-" or "") .. grouped
end

-- Versão curta para espaços pequenos: 1,25 mi a partir de um milhão.
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
local outline = Theme.stroke

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

local function scaleOf(object: GuiObject): UIScale
	local scale = object:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = object
	end
	return scale
end

-- Pequeno "salto" de destaque, usado em contadores e cartões.
function Theme.pop(object: GuiObject, strength: number?)
	if Theme.reducedMotion(object) then return end
	local scale = scaleOf(object)
	scale.Scale = 1 + (strength or 0.12)
	TweenService:Create(scale, Theme.Motion.Pop, { Scale = 1 }):Play()
end

-- ---------- Superfícies ----------

function Theme.panel(object: GuiObject, accent: Color3?)
	local tint = accent or Theme.Color.Cyan
	object.BackgroundColor3 = Color3.new(1, 1, 1)
	object.BorderSizePixel = 0
	Theme.round(object, 12)
	outline(object, tint:Lerp(Theme.Color.Deep, 0.62), 3)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 100
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Color.Surface:Lerp(tint, 0.18)),
		ColorSequenceKeypoint.new(0.5, Theme.Color.Navy),
		ColorSequenceKeypoint.new(1, Theme.Color.Deep),
	})
	gradient.Parent = object
	local rail = Instance.new("Frame")
	rail.Name = "AccentRail"
	rail.AnchorPoint = Vector2.new(0.5, 0)
	rail.Position = UDim2.new(0.5, 0, 0, 2)
	rail.Size = UDim2.new(0.36, 0, 0, 3)
	rail.BackgroundColor3 = tint
	rail.BorderSizePixel = 0
	rail.ZIndex = object.ZIndex + 1
	Theme.round(rail, 2)
	rail.Parent = object
	object:GetPropertyChangedSignal("ZIndex"):Connect(function()
		rail.ZIndex = object.ZIndex + 1
	end)
end

function Theme.button(object: TextButton)
	object.BackgroundColor3 = Theme.Color.Blue
	object.TextColor3 = Theme.Color.Text
	object.AutoButtonColor = false
	Theme.round(object, 10)
	outline(object, Theme.Color.Deep, 3)
	object.TextStrokeColor3 = Theme.Color.Deep
	object.TextStrokeTransparency = 0.2
	-- Brilho de cima para baixo: dá volume de botão de desenho animado.
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("#E2E8FF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#8FA2E8")),
	})
	gradient.Rotation = 90
	gradient.Parent = object
end

function Theme.sheet(object: Frame)
	object.BackgroundColor3 = Color3.new(1, 1, 1)
	object.BorderSizePixel = 0
	Theme.round(object, 18)
	outline(object, Theme.Color.Deep, 4)
	Theme.gradient(object, Color3.fromHex("#FFFFFF"), Color3.fromHex("#C9B8FF"))
end

-- Cartão interno de janelas (fundo escuro translúcido).
function Theme.well(object: GuiObject, radius: number?)
	object.BackgroundColor3 = Theme.Color.Deep
	object.BackgroundTransparency = 0.45
	object.BorderSizePixel = 0
	Theme.round(object, radius or 14)
	outline(object, Theme.Color.Deep, 3)
end

function Theme.meter(track: Frame, fill: Frame)
	track.BackgroundColor3 = Theme.Color.Track
	track.BorderSizePixel = 0
	fill.BorderSizePixel = 0
	track.ClipsDescendants = true
	Theme.round(track, 6)
	Theme.round(fill, 6)
	outline(track, Theme.Color.Deep, 1.5)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.45, Color3.fromHex("#E6EBFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#A2ABD2")),
	})
	gradient.Rotation = 90
	gradient.Parent = fill
end

function Theme.label(parent, text, size, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Theme.Font.Label
	label.TextColor3 = color or Theme.Color.Text
	label.Text = text
	label.TextSize = size
	label.TextWrapped = true
	label.TextStrokeColor3 = Theme.Color.Deep
	-- Texto escuro (Navy) fica sem contorno; os claros ganham contorno estilo desenho.
	label.TextStrokeTransparency = (color == Theme.Color.Navy) and 1 or 0.45
	label.Parent = parent
	return label
end

-- Texto grande que encolhe para caber, com limites de tamanho.
function Theme.fitText(label: TextLabel | TextButton, maxSize: number, minSize: number?)
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.MinTextSize = minSize or 8
	limit.Parent = label
	return limit
end

function Theme.action(parent, text, tint)
	local button = Instance.new("TextButton")
	button.Text = text
	button.TextSize = 14
	button.TextWrapped = true
	button.Font = Theme.Font.Label
	Theme.button(button)
	local base = tint or Theme.Color.Blue
	button.BackgroundColor3 = base
	button:SetAttribute("BaseColor", base)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local tween
	local hovered, focused, pressed = false, false, false
	local function update()
		local active = hovered or focused
		local color = button:GetAttribute("BaseColor") or base
		button.BackgroundColor3 = pressed and color:Lerp(Theme.Color.Deep, 0.35)
			or active and color:Lerp(Theme.Color.Frost, 0.2) or color
		if tween then tween:Cancel() end
		if Theme.reducedMotion(button) then
			scale.Scale = 1
			return
		end
		tween = TweenService:Create(scale, Theme.Motion.Interaction, {
			Scale = pressed and 0.94 or active and 1.04 or 1,
		})
		tween:Play()
	end
	button:GetAttributeChangedSignal("BaseColor"):Connect(update)
	button.MouseEnter:Connect(function() hovered = true; update() end)
	button.MouseLeave:Connect(function() hovered = false; pressed = false; update() end)
	button.SelectionGained:Connect(function() focused = true; update() end)
	button.SelectionLost:Connect(function() focused = false; pressed = false; update() end)
	button.MouseButton1Down:Connect(function() pressed = true; update() end)
	button.MouseButton1Up:Connect(function() pressed = false; update() end)
	button.Parent = parent
	return button
end

-- Troca a cor de um botão criado por Theme.action preservando os estados de foco.
function Theme.setTint(button: TextButton, color: Color3)
	button:SetAttribute("BaseColor", color)
end

-- ---------- Ícones vetoriais (feitos de Frames, sem imagens externas) ----------

local function iconPart(parent, x, y, width, height, color, radius, angle)
	local piece = Instance.new("Frame")
	piece.Position = UDim2.fromOffset(x, y)
	piece.Size = UDim2.fromOffset(width, height)
	piece.BackgroundColor3 = color
	piece.BorderSizePixel = 0
	piece.Rotation = angle or 0
	piece.ZIndex = parent.ZIndex + 1
	Theme.round(piece, radius)
	piece.Parent = parent
	return piece
end

function Theme.illustration(parent, kind, accent)
	local icon = Instance.new("Frame")
	icon.Name = "Illustration"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(32, 29)
	icon.ZIndex = parent.ZIndex + 1
	icon.Parent = parent
	local ink = Theme.Color.Navy
	local light = Theme.Color.Frost
	accent = accent or Theme.Color.Cyan
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
		iconPart(icon, 4, 2, 24, 24, accent:Lerp(ink, 0.25), 12)
		iconPart(icon, 6, 3, 20, 20, accent, 10)
		iconPart(icon, 10, 7, 12, 12, accent:Lerp(light, 0.45), 6)
		iconPart(icon, 14, 9, 4, 8, accent:Lerp(ink, 0.3), 2)
	elseif kind == "bolt" then
		iconPart(icon, 14, 1, 7, 15, accent, 2, 24)
		iconPart(icon, 10, 11, 13, 5, accent, 2)
		iconPart(icon, 12, 13, 7, 15, accent, 2, 24)
		iconPart(icon, 16, 4, 2, 7, light, 1, 24)
	elseif kind == "gem" then
		iconPart(icon, 7, 5, 18, 18, accent:Lerp(ink, 0.2), 3, 45)
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
	elseif kind == "star" then
		iconPart(icon, 8, 5, 17, 17, accent, 3)
		iconPart(icon, 8, 5, 17, 17, accent, 3, 45)
		iconPart(icon, 13, 10, 7, 7, light, 3)
	elseif kind == "lock" then
		local shackle = iconPart(icon, 10, 3, 12, 14, light, 6)
		shackle.BackgroundTransparency = 1
		outline(shackle, light, 3)
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
	elseif kind == "motion" then
		iconPart(icon, 3, 9, 14, 3, light, 2)
		iconPart(icon, 6, 15, 18, 3, accent, 2)
		iconPart(icon, 3, 21, 11, 3, light, 2)
		iconPart(icon, 19, 6, 10, 10, accent, 5)
	elseif kind == "sparkle" then
		iconPart(icon, 14, 2, 4, 24, accent, 2)
		iconPart(icon, 4, 12, 24, 4, accent, 2)
		iconPart(icon, 12, 10, 8, 8, light, 2, 45)
	end
	return icon
end

-- Ícone dentro de um distintivo redondo, no tamanho pedido.
function Theme.badge(parent, kind, accent, size)
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.Size = UDim2.fromOffset(size, size)
	badge.BackgroundColor3 = accent:Lerp(Theme.Color.Deep, 0.55)
	badge.BorderSizePixel = 0
	badge.ZIndex = parent.ZIndex + 1
	Theme.round(badge, size // 2)
	outline(badge, accent, 2, 0.1)
	badge.Parent = parent
	local icon = Theme.illustration(badge, kind, accent)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	local scale = Instance.new("UIScale")
	scale.Scale = (size * 0.78) / 32
	scale.Parent = icon
	return badge, icon
end

-- Etiqueta pequena de atalho de teclado ("B", "M"...).
function Theme.keyHint(parent, key)
	local hint = Instance.new("TextLabel")
	hint.Name = "KeyHint"
	hint.AnchorPoint = Vector2.new(1, 0)
	hint.Position = UDim2.new(1, 4, 0, -4)
	hint.Size = UDim2.fromOffset(18, 18)
	hint.BackgroundColor3 = Theme.Color.Frost
	hint.TextColor3 = Theme.Color.Navy
	hint.Font = Theme.Font.Display
	hint.TextSize = 12
	hint.Text = key
	hint.ZIndex = parent.ZIndex + 3
	Theme.round(hint, 5)
	outline(hint, Theme.Color.Deep, 2)
	hint.Parent = parent
	return hint
end

function Theme.navigationAction(parent, text, kind, accent, hotkey)
	local button = Theme.action(parent, "", accent:Lerp(Theme.Color.Navy, 0.56))
	button.Name = text
	local edge = button:FindFirstChildOfClass("UIStroke")
	edge.Color = accent
	edge.Thickness = 2
	edge.Transparency = 0.15
	local lip = Instance.new("Frame")
	lip.AnchorPoint = Vector2.new(0.5, 1)
	lip.Position = UDim2.new(0.5, 0, 1, -2)
	lip.Size = UDim2.new(0.76, 0, 0, 3)
	lip.BackgroundColor3 = accent
	lip.BorderSizePixel = 0
	Theme.round(lip, 3)
	lip.Parent = button
	local icon = Theme.illustration(button, kind, accent)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 3)
	local caption = Theme.label(button, text, 12)
	caption.Font = Theme.Font.Display
	caption.Position = UDim2.fromOffset(3, 31)
	caption.Size = UDim2.new(1, -6, 0, 19)
	Theme.fitText(caption, 13, 8)
	if hotkey then
		Theme.keyHint(button, hotkey)
	end
	return button
end

-- Interruptor liga/desliga em linha inteira (bom para toque e controle).
function Theme.toggle(parent, text, detail, value, onChange)
	local row = Instance.new("TextButton")
	row.Name = text
	row.Text = ""
	row.AutoButtonColor = false
	row.Size = UDim2.new(1, 0, 0, 64)
	Theme.panel(row, Theme.Color.Green)
	row.Parent = parent
	local title = Theme.label(row, text, 16)
	title.Font = Theme.Font.Display
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(14, 8)
	title.Size = UDim2.new(1, -96, 0, 22)
	local hint = Theme.label(row, detail, 12, Theme.Color.Muted)
	hint.Font = Theme.Font.Body
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Position = UDim2.fromOffset(14, 31)
	hint.Size = UDim2.new(1, -96, 0, 26)
	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, -14, 0.5, 0)
	track.Size = UDim2.fromOffset(58, 30)
	track.BorderSizePixel = 0
	Theme.round(track, 15)
	outline(track, Theme.Color.Deep, 2)
	track.Parent = row
	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Size = UDim2.fromOffset(24, 24)
	knob.BackgroundColor3 = Theme.Color.White
	knob.BorderSizePixel = 0
	Theme.round(knob, 12)
	outline(knob, Theme.Color.Deep, 2)
	knob.Parent = track
	local function render(animate)
		local target = {
			Position = value and UDim2.new(1, -27, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		}
		track.BackgroundColor3 = value and Theme.Color.Mint or Theme.Color.Gray
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
	end)
	render(false)
	return row
end

-- ---------- Janela modal padrão (loja e menus) ----------
-- Retorna as partes para o script preencher o conteúdo em `Body`.
function Theme.window(parent: Instance, titleText: string, options)
	options = options or {}
	local top = options.Top or Color3.fromHex("#6A4BFF")
	local bottom = options.Bottom or Color3.fromHex("#25157A")
	local maxSize = options.MaxSize or Vector2.new(780, 480)

	local overlay = Instance.new("TextButton")
	overlay.Name = "Overlay"
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.Selectable = false
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.45
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Visible = false
	overlay.ZIndex = options.ZIndex or 5
	overlay.Parent = parent

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.53)
	holder.Size = UDim2.fromScale(0.94, 0.82)
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
	shadow.Position = UDim2.fromOffset(0, 8)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.BackgroundColor3 = Color3.new(0, 0, 0)
	shadow.BackgroundTransparency = 0.5
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 1
	Theme.round(shadow, 22)
	shadow.Parent = holder

	local window = Instance.new("Frame")
	window.Name = "Window"
	window.Size = UDim2.fromScale(1, 1)
	window.BackgroundColor3 = Color3.new(1, 1, 1)
	window.BorderSizePixel = 0
	window.Active = true
	window.ZIndex = 2
	Theme.round(window, 20)
	outline(window, Theme.Color.Deep, 5)
	Theme.gradient(window, top, bottom)
	window.Parent = holder

	-- Brilho sutil no topo da janela.
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Position = UDim2.fromOffset(10, 6)
	shine.Size = UDim2.new(1, -20, 0, 26)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.88
	shine.BorderSizePixel = 0
	Theme.round(shine, 13)
	shine.Parent = window

	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.new(0.5, 0, 0, 4)
	banner.Size = UDim2.fromOffset(options.BannerWidth or 250, 52)
	banner.BackgroundColor3 = Color3.new(1, 1, 1)
	banner.BorderSizePixel = 0
	banner.ZIndex = 3
	Theme.round(banner, 14)
	outline(banner, Theme.Color.Deep, 4)
	Theme.gradient(banner, options.BannerTop or Color3.fromHex("#FFE066"),
		options.BannerBottom or Color3.fromHex("#FF9F1C"))
	banner.Parent = holder
	local title = Theme.label(banner, titleText, 28, Color3.new(1, 1, 1))
	title.Font = Theme.Font.Display
	title.Size = UDim2.new(1, -16, 1, 0)
	title.Position = UDim2.fromOffset(8, 0)
	title.TextStrokeTransparency = 0
	Theme.fitText(title, 28, 14)

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10)
	close.Size = UDim2.fromOffset(42, 42)
	close.Text = "X"
	close.TextSize = 24
	close.Font = Theme.Font.Display
	Theme.button(close)
	close.BackgroundColor3 = Theme.Color.Red
	close.AutoButtonColor = true
	close.ZIndex = 3
	close.Parent = holder

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(12, 62)
	body.Size = UDim2.new(1, -24, 1, -74)
	body.Parent = window

	return {
		Overlay = overlay,
		Holder = holder,
		Window = window,
		Banner = banner,
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
	if Theme.reducedMotion(parts.Overlay) then
		parts.Scale.Scale = 1
		parts.Overlay.BackgroundTransparency = 0.45
		return
	end
	parts.Scale.Scale = 0.86
	parts.Overlay.BackgroundTransparency = 1
	TweenService:Create(parts.Scale, Theme.Motion.Pop, { Scale = 1 }):Play()
	TweenService:Create(parts.Overlay, Theme.Motion.Enter, { BackgroundTransparency = 0.45 }):Play()
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
	local tween = TweenService:Create(parts.Scale, Theme.Motion.Exit, { Scale = 0.9 })
	TweenService:Create(parts.Overlay, Theme.Motion.Exit, { BackgroundTransparency = 1 }):Play()
	tween.Completed:Once(finish)
	tween:Play()
end

return Theme
