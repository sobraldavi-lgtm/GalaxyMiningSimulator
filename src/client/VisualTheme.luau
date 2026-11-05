local TweenService = game:GetService("TweenService")
local Theme = {}

Theme.Color = table.freeze({
	Navy = Color3.fromHex("#0B1530"),
	Blue = Color3.fromHex("#3478F6"),
	Cyan = Color3.fromHex("#00D8FF"),
	Violet = Color3.fromHex("#A855F7"),
	Amber = Color3.fromHex("#FFCA3A"),
	Green = Color3.fromHex("#36D985"),
	Frost = Color3.fromHex("#EAF4FF"),
	Text = Color3.fromHex("#EDF4FF"),
	Track = Color3.fromHex("#273857"),
	Deep = Color3.fromHex("#050B1C"),
	Surface = Color3.fromHex("#182B55"),
})

Theme.Font = table.freeze({ Display = Enum.Font.GothamBlack, Label = Enum.Font.GothamBold })
Theme.Motion = table.freeze({
	Interaction = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Enter = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	Exit = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
})

function Theme.reducedMotion(object: Instance): boolean
	local playerGui = object:FindFirstAncestorWhichIsA("PlayerGui")
	return playerGui ~= nil and playerGui:GetAttribute("GalaxyReduceMotion") == true
end

function Theme.round(object: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
end

local function outline(object: GuiObject, color: Color3, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Parent = object
	return stroke
end

function Theme.panel(object: GuiObject, accent: Color3?)
	local tint = accent or Theme.Color.Cyan
	object.BackgroundColor3 = Color3.new(1, 1, 1)
	object.BorderSizePixel = 0
	Theme.round(object, 12)
	local stroke = outline(object, tint, 1.5)
	stroke.Transparency = 0.32
	local gradient = Instance.new("UIGradient", object)
	gradient.Rotation = 105
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Color.Surface:Lerp(tint, 0.12)),
		ColorSequenceKeypoint.new(0.48, Theme.Color.Navy),
		ColorSequenceKeypoint.new(1, Theme.Color.Deep),
	})
	local rail = Instance.new("Frame")
	rail.Name = "AccentRail"
	rail.AnchorPoint = Vector2.new(0.5, 0)
	rail.Position = UDim2.new(0.5, 0, 0, 1)
	rail.Size = UDim2.new(0.32, 0, 0, 2)
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
	Theme.round(object, 8)
	outline(object, Theme.Color.Cyan, 1.5)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHex("#A9B9EA"))
	gradient.Rotation = 90
	gradient.Parent = object
end

function Theme.sheet(object: Frame)
	object.BackgroundColor3 = Color3.new(1, 1, 1)
	object.BorderSizePixel = 0
	Theme.round(object, 18)
	outline(object, Theme.Color.Blue, 2)
	local gradient = Instance.new("UIGradient", object)
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.fromHex("#FFFFFF"), Color3.fromHex("#BCD8FF"))
end

function Theme.meter(track: Frame, fill: Frame)
	track.BackgroundColor3 = Theme.Color.Track
	track.BorderSizePixel = 0
	fill.BorderSizePixel = 0
	track.ClipsDescendants = true
	Theme.round(track, 6)
	Theme.round(fill, 6)
	outline(track, Theme.Color.Deep, 1.5)
	local gradient = Instance.new("UIGradient", fill)
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHex("#A2ABD2"))
	gradient.Rotation = 90
end

function Theme.label(parent, text, size, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Theme.Font.Label
	label.TextColor3 = color or Theme.Color.Text
	label.Text = text
	label.TextSize = size
	label.TextWrapped = true
	label.Parent = parent
	return label
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
	local scale = Instance.new("UIScale", button)
	local tween
	local hovered, focused, pressed = false, false, false
	local function update()
		local active = hovered or focused
		button.BackgroundColor3 = pressed and base:Lerp(Theme.Color.Deep, 0.35)
			or active and base:Lerp(Theme.Color.Frost, 0.18) or base
		if tween then tween:Cancel() end
		if Theme.reducedMotion(button) then
			scale.Scale = 1
			return
		end
		tween = TweenService:Create(scale, Theme.Motion.Interaction, { Scale = pressed and 0.95 or 1 })
		tween:Play()
	end
	button.MouseEnter:Connect(function() hovered = true; update() end)
	button.MouseLeave:Connect(function() hovered = false; pressed = false; update() end)
	button.SelectionGained:Connect(function() focused = true; update() end)
	button.SelectionLost:Connect(function() focused = false; pressed = false; update() end)
	button.MouseButton1Down:Connect(function() pressed = true; update() end)
	button.MouseButton1Up:Connect(function() pressed = false; update() end)
	button.Parent = parent
	return button
end

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
	end
	return icon
end

function Theme.navigationAction(parent, text, kind, accent)
	local button = Theme.action(parent, "", accent:Lerp(Theme.Color.Navy, 0.56))
	button.Name = text
	local edge = button:FindFirstChildOfClass("UIStroke")
	edge.Color = accent
	edge.Thickness = 2
	edge.Transparency = 0.15
	local lip = Instance.new("Frame", button)
	lip.AnchorPoint = Vector2.new(0.5, 1)
	lip.Position = UDim2.new(0.5, 0, 1, -2)
	lip.Size = UDim2.new(0.76, 0, 0, 3)
	lip.BackgroundColor3 = accent
	lip.BorderSizePixel = 0
	Theme.round(lip, 3)
	local icon = Theme.illustration(button, kind, accent)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 3)
	local caption = Theme.label(button, text, 12)
	caption.Position = UDim2.fromOffset(3, 31)
	caption.Size = UDim2.new(1, -6, 0, 19)
	caption.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint", caption)
	limit.MinTextSize = 8
	limit.MaxTextSize = 13
	return button
end

return Theme
