-- Progressão na tela: barra de XP e nível, Fragmentos, rastreador de missão,
-- falas de ORBI, celebrações de nível/missão, aviso de modo de teste e a
-- janela do Hangar (Orion Scout e mapa galáctico). Só apresentação.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent:WaitForChild("VisualTheme"))
local Sound = require(script.Parent:WaitForChild("Sound"))
local ArtStyle = require(script.Parent:WaitForChild("ArtStyle"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local remote = ReplicatedStorage:WaitForChild("InventoryState")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local C = Theme.Color

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyProgress"
gui.ResetOnSpawn = false
gui.DisplayOrder = 11
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local stage = Instance.new("ScreenGui")
stage.Name = "GalaxyProgressStage"
stage.ResetOnSpawn = false
stage.DisplayOrder = 31
stage.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
stage.Parent = playerGui

-- Esconde a camada de HUD quando um menu está aberto (como a mineração).
local function syncVisibility()
	gui.Enabled = not playerGui:GetAttribute("GalaxyMenuOpen")
end
playerGui:GetAttributeChangedSignal("GalaxyMenuOpen"):Connect(syncVisibility)
syncVisibility()

-- ---------- Barra de XP ----------
local xpBar = Instance.new("Frame")
xpBar.Name = "Experience"
xpBar.AnchorPoint = Vector2.new(0.5, 0)
Theme.panel(xpBar, C.Violet, 15)
xpBar.Parent = gui
local xpLimit = Instance.new("UISizeConstraint")
xpLimit.MaxSize = Vector2.new(440, 30)
xpLimit.Parent = xpBar
local levelBadge = Theme.badge(xpBar, "star", C.Gold, 42)
levelBadge.AnchorPoint = Vector2.new(0, 0.5)
levelBadge.Position = UDim2.new(0, -16, 0.5, 0)
levelBadge.ZIndex = 4
local levelNumber = Theme.title(levelBadge, "1", 18, C.White)
levelNumber.Size = UDim2.fromScale(1, 1)
levelNumber.ZIndex = 5
local xpTrack = Instance.new("Frame")
xpTrack.Position = UDim2.fromOffset(32, 6)
xpTrack.Size = UDim2.new(1, -112, 1, -12)
xpTrack.Parent = xpBar
local xpFill = Instance.new("Frame")
xpFill.BackgroundColor3 = C.Violet
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.Parent = xpTrack
Theme.meter(xpTrack, xpFill)
local xpText = Theme.title(xpTrack, "", 11, C.White)
xpText.Size = UDim2.fromScale(1, 1)
xpText.ZIndex = 3
local fragments = Theme.title(xpBar, "◆ 0", 14, C.Cyan)
fragments.AnchorPoint = Vector2.new(1, 0.5)
fragments.Position = UDim2.new(1, -10, 0.5, 0)
fragments.Size = UDim2.fromOffset(70, 20)
fragments.TextXAlignment = Enum.TextXAlignment.Right
Theme.fitText(fragments, 14, 9)

-- ---------- Rastreador de missão ----------
local tracker = Instance.new("TextButton")
tracker.Name = "MissionTracker"
tracker.Text = ""
tracker.AutoButtonColor = false
Theme.panel(tracker, C.Cyan, 18)
tracker.Visible = false
tracker.Parent = gui
local trackerBadgeHolder = Instance.new("Frame")
trackerBadgeHolder.BackgroundTransparency = 1
trackerBadgeHolder.Size = UDim2.fromOffset(48, 48)
trackerBadgeHolder.Parent = tracker
local trackerHeader = Theme.title(tracker, "", 11, C.Cyan)
trackerHeader.TextXAlignment = Enum.TextXAlignment.Left
local trackerTitle = Theme.title(tracker, "", 16, C.White)
trackerTitle.TextXAlignment = Enum.TextXAlignment.Left
Theme.fitText(trackerTitle, 16, 9)
local trackerGoal = Theme.label(tracker, "", 11, C.Muted)
trackerGoal.Font = Theme.Font.Body
trackerGoal.TextXAlignment = Enum.TextXAlignment.Left
Theme.fitText(trackerGoal, 11, 7)
local trackerTrack = Instance.new("Frame")
trackerTrack.Parent = tracker
local trackerFill = Instance.new("Frame")
trackerFill.BackgroundColor3 = C.Cyan
trackerFill.Size = UDim2.fromScale(0, 1)
trackerFill.Parent = trackerTrack
Theme.meter(trackerTrack, trackerFill)
local trackerCount = Theme.title(trackerTrack, "", 11, C.White)
trackerCount.Size = UDim2.fromScale(1, 1)
trackerCount.ZIndex = 3
local trackerBadgeKey
tracker.Activated:Connect(function()
	Sound.play("click")
	playerGui:SetAttribute("GalaxyMenuRequest", "Missões#" .. os.clock())
end)

-- ---------- Aviso de modo de teste (sem DataStore) ----------
local testChip = Theme.title(gui, "MODO DE TESTE · progresso não será salvo", 11, C.Ink)
testChip.TextStrokeTransparency = 1
testChip.BackgroundColor3 = C.Amber
testChip.AnchorPoint = Vector2.new(1, 1)
testChip.Position = UDim2.new(1, -10, 1, -10)
testChip.Size = UDim2.fromOffset(250, 22)
testChip.Visible = false
Theme.round(testChip, 11)
Theme.stroke(testChip, C.Ink, 2)

-- ---------- Falas de ORBI ----------
local dialog = Instance.new("TextButton")
dialog.Name = "OrbiDialog"
dialog.Text = ""
dialog.AutoButtonColor = false
dialog.AnchorPoint = Vector2.new(0, 1)
dialog.Visible = false
Theme.panel(dialog, C.Cyan, 20)
dialog.Parent = gui
local dialogScale = Instance.new("UIScale")
dialogScale.Parent = dialog
local orbiBadge = Theme.badge(dialog, "robot", C.Cyan, 64)
orbiBadge.AnchorPoint = Vector2.new(0, 0.5)
orbiBadge.Position = UDim2.new(0, -14, 0.5, 0)
orbiBadge.ZIndex = 4
local dialogName = Theme.title(dialog, "ORBI", 14, C.Cyan)
dialogName.TextXAlignment = Enum.TextXAlignment.Left
dialogName.Position = UDim2.fromOffset(60, 6)
dialogName.Size = UDim2.new(1, -70, 0, 18)
local dialogText = Theme.label(dialog, "", 14, C.Frost)
dialogText.Font = Theme.Font.Label
dialogText.TextXAlignment = Enum.TextXAlignment.Left
dialogText.TextYAlignment = Enum.TextYAlignment.Top
dialogText.Position = UDim2.fromOffset(60, 26)
dialogText.Size = UDim2.new(1, -72, 1, -32)
Theme.fitText(dialogText, 14, 9)
local dialogToken = 0

local function hideDialog()
	if not dialog.Visible then return end
	if Theme.reducedMotion(dialog) then
		dialog.Visible = false
		return
	end
	local tween = TweenService:Create(dialogScale, Theme.Motion.Exit, { Scale = 0 })
	tween.Completed:Once(function() dialog.Visible = false end)
	tween:Play()
end
dialog.Activated:Connect(hideDialog)

-- Texto aparece letra a letra (máquina de escrever), como uma transmissão.
local function say(text)
	dialogToken += 1
	local token = dialogToken
	dialog.Visible = true
	dialogScale.Scale = 1
	Theme.pop(dialog, 0.1)
	Sound.play("open", 1.3)
	if Theme.reducedMotion(dialog) then
		dialogText.Text = text
	else
		dialogText.Text = ""
		task.spawn(function()
			-- Avança por caractere UTF-8 completo (acentos não quebram).
			local shown = {}
			for _, code in utf8.codes(text) do
				if token ~= dialogToken then return end
				table.insert(shown, utf8.char(code))
				dialogText.Text = table.concat(shown)
				task.wait(0.018)
			end
		end)
	end
	task.delay(8, function()
		if token == dialogToken then hideDialog() end
	end)
end

-- ---------- Celebrações (fila para não sobrepor) ----------
local queue = {}
local showing = false

local function showNext()
	if showing or #queue == 0 then return end
	showing = true
	local item = table.remove(queue, 1)
	Sound.play("reward", item.Pitch or 1.2)
	Theme.confetti(stage, item.Confetti or 40)
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.38)
	holder.Size = UDim2.fromOffset(440, 220)
	holder.BackgroundTransparency = 1
	holder.Parent = stage
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	Theme.rays(holder, { Color = item.Color, Alt = C.Gold, Length = 300, Width = 26, Count = 10,
		Position = UDim2.fromScale(0.5, 0.32), Transparency = 0.5 })
	local badge = Theme.badge(holder, item.Icon, item.Color, 110)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.5, 0.32)
	badge.ZIndex = 3
	if item.BadgeText then
		local number = Theme.title(badge, item.BadgeText, 44, C.White)
		number.Size = UDim2.fromScale(1, 1)
		number.ZIndex = 6
	end
	local headline = Theme.title(holder, item.Title, 40, C.Gold)
	headline.AnchorPoint = Vector2.new(0.5, 0)
	headline.Position = UDim2.new(0.5, 0, 0.32, 62)
	headline.Size = UDim2.new(1.2, 0, 0, 46)
	headline.ZIndex = 4
	local detail = Theme.title(holder, item.Detail, 19, C.White)
	detail.AnchorPoint = Vector2.new(0.5, 0)
	detail.Position = UDim2.new(0.5, 0, 0.32, 108)
	detail.Size = UDim2.new(1.2, 0, 0, 24)
	detail.ZIndex = 4
	if not Theme.reducedMotion(holder) then
		scale.Scale = 0.2
		TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	task.delay(2.6, function()
		local function finish()
			holder:Destroy()
			showing = false
			showNext()
		end
		if Theme.reducedMotion(holder) then
			finish()
			return
		end
		local out = TweenService:Create(scale, Theme.Motion.Exit, { Scale = 0 })
		out.Completed:Once(finish)
		out:Play()
	end)
end

local function celebrate(item)
	table.insert(queue, item)
	showNext()
end

-- ---------- Layout ----------
local wideLayout = true
local function layout()
	local size = gui.AbsoluteSize
	local wide = size.X >= 900 and size.Y >= 520
	wideLayout = wide
	xpBar.Position = wide and UDim2.new(0.5, 8, 0, 72) or UDim2.new(0.5, 8, 0, 140)
	xpBar.Size = UDim2.new(wide and 0.5 or 1, wide and 0 or -40, 0, 30)
	tracker.AnchorPoint = wide and Vector2.new(1, 0) or Vector2.new(0.5, 0)
	tracker.Position = wide and UDim2.new(1, -14, 0, 74) or UDim2.new(0.5, 0, 0, 176)
	tracker.Size = wide and UDim2.fromOffset(250, 104) or UDim2.new(1, -24, 0, 50)
	local trackerLimit = tracker:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint", tracker)
	trackerLimit.MaxSize = Vector2.new(wide and 250 or 420, 104)
	trackerHeader.Visible = wide
	trackerGoal.Visible = wide
	trackerBadgeHolder.Position = wide and UDim2.fromOffset(10, 28) or UDim2.fromOffset(6, 1)
	local left = wide and 66 or 58
	trackerHeader.Position = UDim2.fromOffset(14, 8)
	trackerHeader.Size = UDim2.new(1, -28, 0, 14)
	trackerTitle.Position = UDim2.fromOffset(left, wide and 28 or 4)
	trackerTitle.Size = UDim2.new(1, -(left + 10), 0, 20)
	trackerGoal.Position = UDim2.fromOffset(left, 50)
	trackerGoal.Size = UDim2.new(1, -(left + 10), 0, 14)
	trackerTrack.Position = UDim2.fromOffset(left, wide and 72 or 28)
	trackerTrack.Size = UDim2.new(1, -(left + 12), 0, wide and 18 or 14)
	dialog.Position = wide and UDim2.new(0, 220, 1, -24) or UDim2.new(0, 26, 1, -170)
	dialog.Size = wide and UDim2.fromOffset(380, 92) or UDim2.new(1, -40, 0, 84)
	local dialogLimit = dialog:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint", dialog)
	dialogLimit.MaxSize = Vector2.new(420, 92)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()

-- ---------- Estado ----------
local lastMission
local cargoFull = false

remote.OnClientEvent:Connect(function(s)
	-- Barra de XP
	local span = math.max(s.NextLevelXp - s.LevelFloorXp, 1)
	local ratio = math.clamp((s.Xp - s.LevelFloorXp) / span, 0, 1)
	Theme.tween(xpFill, Theme.Motion.Enter, { Size = UDim2.fromScale(ratio, 1) })
	levelNumber.Text = tostring(s.Level)
	xpText.Text = string.format("NÍVEL %d  ·  %s / %s XP", s.Level, Theme.format(s.Xp - s.LevelFloorXp), Theme.format(span))
	fragments.Text = "◆ " .. Theme.format(s.Fragments)
	testChip.Visible = s.SaveMode == "memory"

	-- Rastreador de missão (some com a mochila cheia em telas estreitas)
	cargoFull = s.Weight >= s.Capacity
	local mission = Config.Missions[s.MissionIndex]
	tracker.Visible = mission ~= nil and (wideLayout or not cargoFull)
	if mission then
		trackerHeader.Text = string.format("MISSÃO %d/%d · ORBI", s.MissionIndex, #Config.Missions)
		trackerTitle.Text = mission.Title
		trackerGoal.Text = mission.Goal
		local current, goal = s.MissionProgress, mission.Count
		if mission.Kind == "Transmitter" and s.Level < Config.Progression.CaveLevel then
			current, goal = s.Level, Config.Progression.CaveLevel
			trackerCount.Text = "Nível " .. s.Level .. " / " .. goal
		else
			trackerCount.Text = math.min(current, goal) .. " / " .. goal
		end
		Theme.tween(trackerFill, Theme.Motion.Enter, { Size = UDim2.fromScale(math.clamp(current / goal, 0, 1), 1) })
		if trackerBadgeKey ~= mission.Id then
			trackerBadgeKey = mission.Id
			trackerBadgeHolder:ClearAllChildren()
			Theme.badge(trackerBadgeHolder, ArtStyle.missionIcon(mission.Kind), C.Cyan, 48)
			Theme.pop(tracker, 0.08)
		end
	end

	-- Celebrações vindas do servidor
	if s.CompletedMissions then
		for _, done in ipairs(s.CompletedMissions) do
			celebrate({
				Title = "MISSÃO CONCLUÍDA!", Detail = done.Title .. "  ·  +" .. done.Credits .. " ✦  +" .. done.Fragments .. " ◆",
				Icon = "star", Color = C.Mint, Confetti = 50,
			})
		end
	end
	if s.LevelUp then
		local reward = Config.Progression.LevelRewards[s.LevelUp]
		celebrate({
			Title = "NÍVEL " .. s.LevelUp .. "!", Detail = reward or "Você está ficando mais forte!",
			Icon = "star", Color = C.Violet, BadgeText = tostring(s.LevelUp), Confetti = 70, Pitch = 1.4,
		})
		Theme.pop(xpBar, 0.15)
	end

	-- ORBI fala quando uma missão nova começa (e ao entrar no jogo).
	if s.MissionIndex ~= lastMission then
		local first = lastMission == nil
		lastMission = s.MissionIndex
		local text = mission and mission.Orbi
			or (not first and "Campanha concluída! Você é oficialmente um explorador de Terra Nova. Continue minerando!")
		if text then
			task.delay(first and 4 or 2.8, function() say(text) end)
		end
	end
end)

-- ---------- Hangar: Orion Scout e mapa galáctico ----------
local hangarGui = Instance.new("ScreenGui")
hangarGui.Name = "GalaxyHangar"
hangarGui.ResetOnSpawn = false
hangarGui.DisplayOrder = 20
hangarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hangarGui.Parent = playerGui
local hangar = Theme.window(hangarGui, "HANGAR ORION", { MaxSize = Vector2.new(820, 470), Accent = C.Cyan, Icon = "rocket" })
local hangarBody = hangar.Body

local ship = Instance.new("Frame")
ship.Size = UDim2.new(0.36, -6, 1, 0)
Theme.panel(ship, C.Cyan, 18)
ship.Parent = hangarBody
Theme.rays(ship, { Color = C.Cyan, Alt = C.Violet, Length = 210, Width = 18, Position = UDim2.new(0.5, 0, 0, 100) })
local shipBadge = Theme.badge(ship, "rocket", C.Cyan, 120)
shipBadge.AnchorPoint = Vector2.new(0.5, 0.5)
shipBadge.Position = UDim2.new(0.5, 0, 0, 100)
shipBadge.ZIndex = 3
local shipName = Theme.title(ship, "ORION SCOUT", 24, C.White)
shipName.Position = UDim2.fromOffset(8, 172)
shipName.Size = UDim2.new(1, -16, 0, 30)
local shipRole = Theme.title(ship, "Transporte inicial", 14, C.Cyan)
shipRole.Position = UDim2.fromOffset(8, 202)
shipRole.Size = UDim2.new(1, -16, 0, 18)
local shipInfo = Theme.label(ship,
	"Nave padrão da Orion Mining Corporation. Pronta no hangar para as primeiras expedições.", 12, C.Muted)
shipInfo.Font = Theme.Font.Body
shipInfo.Position = UDim2.fromOffset(14, 226)
shipInfo.Size = UDim2.new(1, -28, 0, 48)
Theme.fitText(shipInfo, 12, 8)
local launch = Theme.action(ship, "VIAGENS EM BREVE", C.Gray, { Size = UDim2.new(1, -24, 0, 48), Icon = "rocket", TextSize = 16 })
launch.AnchorPoint = Vector2.new(0.5, 1)
launch.Position = UDim2.new(0.5, 0, 1, -12)

local map = Instance.new("Frame")
map.Position = UDim2.new(0.36, 6, 0, 0)
map.Size = UDim2.new(0.64, -6, 1, 0)
Theme.well(map, 18)
map.Parent = hangarBody
Theme.nebula(map, C.Violet)
Theme.starfield(map, 50)
local mapTitle = Theme.title(map, "MAPA DA GALÁXIA DE ASTERION", 16, C.Gold)
mapTitle.Position = UDim2.fromOffset(12, 8)
mapTitle.Size = UDim2.new(1, -24, 0, 22)
local planets = {
	{ "Terra Nova", "Você está aqui", C.Mint, 0.16, 0.62, true },
	{ "Vulkar", "Alpha 0.2", C.Orange, 0.4, 0.3, false },
	{ "Cryon", "Alpha 0.3", C.Cyan, 0.64, 0.66, false },
	{ "Nebulon", "Futuro", C.Violet, 0.86, 0.32, false },
}
for index = 1, #planets - 1 do
	local a, b = planets[index], planets[index + 1]
	local path = Instance.new("Frame")
	path.AnchorPoint = Vector2.new(0.5, 0.5)
	path.BackgroundColor3 = C.White
	path.BackgroundTransparency = 0.6
	path.BorderSizePixel = 0
	path.Parent = map
	-- Segmento ligando dois planetas (recalculado quando o mapa muda de tamanho).
	local function place()
		local sizePx = map.AbsoluteSize
		local ax, ay = a[4] * sizePx.X, a[5] * sizePx.Y
		local bx, by = b[4] * sizePx.X, b[5] * sizePx.Y
		local length = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
		path.Position = UDim2.fromOffset((ax + bx) / 2, (ay + by) / 2)
		path.Size = UDim2.fromOffset(length, 4)
		path.Rotation = math.deg(math.atan2(by - ay, bx - ax))
	end
	map:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	place()
end
for _, planet in ipairs(planets) do
	local node = Instance.new("Frame")
	node.AnchorPoint = Vector2.new(0.5, 0.5)
	node.Position = UDim2.fromScale(planet[4], planet[5])
	node.Size = UDim2.fromOffset(84, 84)
	node.BackgroundColor3 = C.White
	node.BorderSizePixel = 0
	node.ZIndex = 3
	Theme.round(node, 42)
	Theme.stroke(node, C.Ink, 4)
	Theme.gradient(node, planet[3]:Lerp(C.White, 0.3), planet[3]:Lerp(C.Ink, 0.55), 45)
	node.Parent = map
	if planet[6] then
		Theme.rays(map, { Color = planet[3], Alt = C.Gold, Length = 140, Width = 12,
			Position = UDim2.fromScale(planet[4], planet[5]), Transparency = 0.6 })
	else
		local lock = Theme.badge(node, "lock", C.Gray, 34)
		lock.AnchorPoint = Vector2.new(0.5, 0.5)
		lock.Position = UDim2.fromScale(0.82, 0.82)
		lock.ZIndex = 5
	end
	local label = Theme.title(map, planet[1], 15, C.White)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(planet[4], 0, planet[5], 46)
	label.Size = UDim2.fromOffset(120, 18)
	label.ZIndex = 4
	local sub = Theme.title(map, planet[2], 11, planet[6] and C.Mint or C.Muted)
	sub.AnchorPoint = Vector2.new(0.5, 0)
	sub.Position = UDim2.new(planet[4], 0, planet[5], 64)
	sub.Size = UDim2.fromOffset(120, 14)
	sub.ZIndex = 4
end

local function openHangar()
	if hangar.Overlay.Visible or playerGui:GetAttribute("GalaxyMenuOpen") then return end
	playerGui:SetAttribute("GalaxyMenuOpen", true)
	playerGui:SetAttribute("GalaxyHangarOpen", true) -- bloqueia atalhos da HUD enquanto aberto
	Theme.openWindow(hangar)
end
local function closeHangar()
	Theme.closeWindow(hangar, function()
		playerGui:SetAttribute("GalaxyHangarOpen", false)
		playerGui:SetAttribute("GalaxyMenuOpen", false)
	end)
end
hangar.Close.Activated:Connect(closeHangar)
hangar.Overlay.Activated:Connect(closeHangar)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonB and hangar.Overlay.Visible then closeHangar() end
end)
ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who == player and prompt.Name == "OpenHangar" then openHangar() end
end)
