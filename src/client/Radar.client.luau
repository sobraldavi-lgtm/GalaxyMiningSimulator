-- Radar da HUD: mostra a direção e a distância relativa dos pontos principais
-- de Terra Nova, girando com a câmera. Só apresentação.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Theme = require(script.Parent:WaitForChild("VisualTheme"))
local C = Theme.Color
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RADIUS = 56 -- raio útil em pixels
local RANGE = 170 -- studs até a borda do radar

local points = {
	{ "Mina", { "MiningAreas", "MiningPlatform" }, C.Cyan, "pickaxe" },
	{ "Loja", { "Shop", "Floor" }, C.Gold, "shop" },
	{ "Venda", { "SaleStation", "Counter" }, C.Mint, "coin" },
	{ "Pets", { "PetShop", "Terminal" }, C.Pink, "egg" },
	{ "Hangar", { "Hangar", "LandingPad" }, C.Violet, "rocket" },
}

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyRadar"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local dial = Instance.new("Frame")
dial.Name = "Radar"
dial.AnchorPoint = Vector2.new(1, 1)
dial.Position = UDim2.new(1, -14, 1, -42)
dial.Size = UDim2.fromOffset(RADIUS * 2 + 16, RADIUS * 2 + 16)
Theme.panel(dial, C.Cyan, 999)
dial.BackgroundTransparency = 0.15
dial.Parent = gui

-- Anéis de distância e marcador do jogador (aponta para onde a câmera olha).
for _, scale in ipairs({ 0.5, 1 }) do
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromOffset(RADIUS * 2 * scale, RADIUS * 2 * scale)
	ring.BackgroundTransparency = 1
	Theme.round(ring, 999)
	Theme.stroke(ring, C.White, 1, 0.85)
	ring.Parent = dial
end
local me = Instance.new("Frame")
me.AnchorPoint = Vector2.new(0.5, 0.5)
me.Position = UDim2.fromScale(0.5, 0.5)
me.Size = UDim2.fromOffset(10, 10)
me.Rotation = 45
me.BackgroundColor3 = C.White
me.BorderSizePixel = 0
me.ZIndex = 4
Theme.round(me, 2)
Theme.stroke(me, C.Ink, 2)
me.Parent = dial
local north = Theme.title(dial, "▲", 10, C.White)
north.AnchorPoint = Vector2.new(0.5, 0)
north.Position = UDim2.new(0.5, 0, 0, 2)
north.Size = UDim2.fromOffset(14, 12)

local dots = {}
for index, point in ipairs(points) do
	local dot = Theme.badge(dial, point[4], point[3], 22)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.ZIndex = 3
	dots[index] = dot
end

-- Legenda do ponto mais próximo, abaixo do radar.
local caption = Theme.title(gui, "", 12, C.White)
caption.AnchorPoint = Vector2.new(1, 1)
caption.Position = UDim2.new(1, -14, 1, -42 - (RADIUS * 2 + 16) - 2)
caption.Size = UDim2.fromOffset(RADIUS * 2 + 16, 16)

local function visible()
	local size = gui.AbsoluteSize
	-- Só em telas largas e altas (não disputa espaço em celulares) e fora de menus.
	return size.X >= 900 and size.Y >= 640 and not playerGui:GetAttribute("GalaxyMenuOpen")
end

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	if elapsed < 1 / 20 then return end
	elapsed = 0
	local show = visible()
	dial.Visible = show
	caption.Visible = show
	if not show then return end
	local camera = workspace.CurrentCamera
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local world = workspace:FindFirstChild("TerraNova")
	if not camera or not root or not world then return end
	local look = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.01 then return end
	local forward = look.Unit
	local right = Vector3.new(-forward.Z, 0, forward.X)
	local nearest, nearestDistance
	for index, point in ipairs(points) do
		local group = world:FindFirstChild(point[2][1])
		local anchor = group and group:FindFirstChild(point[2][2])
		local dot = dots[index]
		dot.Visible = anchor ~= nil
		if anchor then
			local offset = (anchor.Position - root.Position) * Vector3.new(1, 0, 1)
			local distance = offset.Magnitude
			local x, y = offset:Dot(right), -offset:Dot(forward)
			local reach = math.min(distance / RANGE, 1) * RADIUS
			local scale = distance > 0.01 and reach / distance or 0
			dot.Position = UDim2.new(0.5, x * scale, 0.5, y * scale)
			-- Na borda (fora do alcance) o ícone fica menor e translúcido.
			dot.BackgroundTransparency = distance > RANGE and 0.4 or 0
			if not nearestDistance or distance < nearestDistance then
				nearest, nearestDistance = point, distance
			end
		end
	end
	if nearest then
		caption.Text = nearest[1] .. " · " .. math.floor(nearestDistance) .. " m"
		caption.TextColor3 = nearest[3]:Lerp(C.White, 0.3)
	end
end)
