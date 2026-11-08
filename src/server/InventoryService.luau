-- Serviço de inventário, economia e progressão (autoridade do servidor).
-- Carrega/salva via DataService, publica o estado ao cliente, mantém os
-- leaderstats e os placares, e valida toda ação pedida pelo cliente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local AnalyticsService = game:GetService("AnalyticsService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local InventoryModel = require(script.Parent:WaitForChild("InventoryModel"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local Service = {}
local inventories = {} -- só jogadores com dados já carregados
local lastSnapshot = {}
local lastPetChange = {}
local lastSale = {}
local lastBackpack = {}
local lastRebirth = {}
local lastTransmitter = {}
local lastSettings = {}
local hatchRandom = Random.new() -- sorteio dos ovos só no servidor
local initialized = false
local remote
local shopFloor
local petTerminal

local AUTOSAVE_INTERVAL = 120
local LEADERBOARD_INTERVAL = 90

local function getInventory(player)
	return inventories[player]
end

function Service.IsReady(player)
	return inventories[player] ~= nil
end

-- ---------- Leaderstats (lista de jogadores do Roblox) ----------
local function updateLeaderstats(player, inventory)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		for _, spec in ipairs({ { "Créditos", "IntValue" }, { "Nível", "IntValue" }, { "Renasc.", "IntValue" } }) do
			local value = Instance.new(spec[2])
			value.Name = spec[1]
			value.Parent = stats
		end
		stats.Parent = player
	end
	stats["Créditos"].Value = inventory.credits
	stats["Nível"].Value = (inventory:GetLevel())
	stats["Renasc."].Value = inventory.rebirths
end

-- ---------- Analytics do Roblox (painel Creator Hub) ----------
-- Funil do tutorial e fluxo de Créditos. Nunca interfere no jogo (pcall).
local function analytics(callback)
	task.spawn(pcall, callback)
end

local function logFunnel(player, step, name)
	analytics(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
	end)
end

local function logCredits(player, flow, amount, balance, transaction, sku)
	if amount <= 0 then return end
	analytics(function()
		AnalyticsService:LogEconomyEvent(player, flow, "Creditos", amount, balance, transaction, sku)
	end)
end

-- Missões concluídas: passo do funil e Créditos ganhos de recompensa.
local function logMissions(player, inventory, missions)
	if not missions then return end
	for _, mission in ipairs(missions) do
		local index = table.find(Config.Missions, mission) or 0
		logFunnel(player, index + 1, "Missão " .. index .. ": " .. mission.Title)
		logCredits(player, Enum.AnalyticsEconomyFlowType.Source, mission.Credits, inventory.credits,
			Enum.AnalyticsEconomyTransactionType.Gameplay.Name, "Mission_" .. mission.Id)
	end
end

-- Tone é só apresentação: indica ao cliente a cor e o ícone da notificação
-- (success, error, warning, sale, power, pickup). Não carrega regras.
-- extra: { LevelUp = n, Missions = { ... } } para celebrações no cliente.
local function publish(player, message, petReveal, tone, extra)
	local inventory = getInventory(player)
	if not inventory then return end
	local snapshot = inventory:Snapshot()
	-- Atributos replicados só para apresentação: todos os clientes desenham ferramenta e pet.
	if player:GetAttribute("EquippedTool") ~= snapshot.ToolId then
		player:SetAttribute("EquippedTool", snapshot.ToolId)
	end
	if player:GetAttribute("EquippedPet") ~= snapshot.EquippedPet then
		player:SetAttribute("EquippedPet", snapshot.EquippedPet)
	end
	snapshot.Message = message
	snapshot.PetReveal = petReveal
	snapshot.Tone = tone
	if extra then
		logMissions(player, inventory, extra.Missions)
		snapshot.LevelUp = extra.LevelUp
		snapshot.Hatches = extra.Hatches
		if extra.Missions and #extra.Missions > 0 then
			local list = {}
			for _, mission in ipairs(extra.Missions) do
				table.insert(list, { Title = mission.Title, Credits = mission.Credits, Fragments = mission.Fragments })
			end
			snapshot.CompletedMissions = list
		end
	end
	snapshot.SaveMode = DataService.IsAvailable() and "cloud" or "memory"
	updateLeaderstats(player, inventory)
	remote:FireClient(player, snapshot)
end

function Service.CanFit(player, oreType)
	local inventory = getInventory(player)
	return inventory ~= nil and inventory:CanFit(oreType)
end

function Service.GetPower(player)
	local inventory = getInventory(player)
	return inventory and inventory:GetMiningPower() or 0
end

function Service.Train(player)
	local inventory = getInventory(player)
	if not inventory then return end
	local progressed, gained = inventory:TrainMining()
	if progressed then
		publish(player, gained and "Treino • +1 de poder" or nil, nil, "power")
	end
end

function Service.Add(player, oreType)
	local inventory = getInventory(player)
	if not inventory then return false end
	local success, levelUp, missions = inventory:Mine(oreType)
	if success then
		publish(player, "+1 " .. Config.Ores[oreType].Name, nil, "pickup", { LevelUp = levelUp, Missions = missions })
	end
	return success
end

local function alive(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return nil end
	return root
end

local function createPrompt(parent, name, action, object, distance, hold)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = hold or 0
	prompt.MaxActivationDistance = distance
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

-- ---------- Salvamento ----------
local saving = {}

local function save(player, release)
	if saving[player] then
		-- Autosave pode pular; a gravação final (que libera a trava) espera a anterior.
		if not release then return end
		local deadline = os.clock() + 30
		while saving[player] and os.clock() < deadline do task.wait(0.1) end
	end
	local inventory = getInventory(player)
	if not inventory then return end
	saving[player] = true
	DataService.Save(player, inventory:Serialize(), release)
	DataService.SubmitScore("Lifetime", player.UserId, inventory.lifetimeCredits)
	DataService.SubmitScore("Rebirths", player.UserId, inventory.rebirths)
	saving[player] = nil
end

local function load(player)
	local ok, data = DataService.Load(player)
	if not player.Parent then
		-- Saiu durante o carregamento: libera a trava sem tocar nos dados.
		if ok then DataService.Release(player) end
		return
	end
	if not ok then
		-- Sem dados confiáveis, não deixamos jogar: evita sobrescrever o progresso salvo.
		player:Kick("Não foi possível carregar seu progresso agora. Tente entrar novamente em instantes.")
		return
	end
	local inventory = InventoryModel.fromData(Config, data)
	inventories[player] = inventory
	if not data then
		logFunnel(player, 1, "Primeira entrada")
	end
	player:SetAttribute("EquippedPet", inventory.equippedPet)
	player:SetAttribute("EquippedTool", inventory.toolId)
	-- Missões de estado (ex.: Lumini já equipada) concluem ao entrar.
	local missions = inventory:Progress(nil)
	publish(player, data and "Progresso carregado. Bem-vindo de volta!" or nil, nil, "info", { Missions = missions })
end

-- ---------- Placares ----------
local nameCache = {}
local function displayName(userId)
	if nameCache[userId] then return nameCache[userId] end
	local online = Players:GetPlayerByUserId(userId)
	if online then
		nameCache[userId] = online.DisplayName
		return online.DisplayName
	end
	local ok, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	nameCache[userId] = ok and name or ("Explorador " .. userId)
	return nameCache[userId]
end

local leaderboardData
local function refreshLeaderboards()
	for _, board in ipairs({ { "Lifetime", "lifetimeCredits" }, { "Rebirths", "rebirths" } }) do
		local entries = DataService.TopScores(board[1], 10)
		if entries == false then
			-- Falha momentânea: mantém o último placar publicado.
			continue
		end
		if not entries then
			-- Sem DataStore: placar só com quem está neste servidor.
			entries = {}
			for player, inventory in pairs(inventories) do
				table.insert(entries, { UserId = player.UserId, Value = inventory[board[2]] })
			end
			table.sort(entries, function(a, b) return a.Value > b.Value end)
			while #entries > 10 do table.remove(entries) end
		end
		local list = {}
		for rank, entry in ipairs(entries) do
			list[rank] = { Name = displayName(entry.UserId), Value = entry.Value }
		end
		leaderboardData:SetAttribute(board[1], HttpService:JSONEncode(list))
	end
	leaderboardData:SetAttribute("UpdatedAt", os.time())
end

-- ---------- Ações do cliente ----------
local handleAction
local function trackedAction(player, action, argument, extra)
	local inventory = getInventory(player)
	if not inventory then return end
	local before = inventory.credits
	handleAction(player, action, argument, extra)
	-- Créditos gastos (compras, resgates e renascimento) entram como "sink".
	local spent = before - inventory.credits
	if spent > 0 and inventories[player] == inventory then
		local transaction = action == "Rebirth" and Enum.AnalyticsEconomyTransactionType.Gameplay.Name
			or Enum.AnalyticsEconomyTransactionType.Shop.Name
		logCredits(player, Enum.AnalyticsEconomyFlowType.Sink, spent, inventory.credits, transaction,
			typeof(argument) == "string" and argument or action)
	end
end

function handleAction(player, action, argument, extra)
	local inventory = getInventory(player)
	if not inventory then return end
	local now = os.clock()
	if action == "SaveSettings" then
		if now - (lastSettings[player] or -math.huge) < 1 then return end
		lastSettings[player] = now
		inventory:SetSettings(argument)
		return
	end
	if action == "HatchEgg" then
		local root = alive(player)
		-- Intervalo cobre a animação de abertura no cliente.
		if typeof(argument) ~= "string" or not root or now - (lastPetChange[player] or -math.huge) < 1.2 then
			return
		end
		lastPetChange[player] = now
		-- Ovos só no OVNI da Estação de Pets.
		if not petTerminal or (root.Position - petTerminal.Position).Magnitude > 40 then
			publish(player, "Vá até o OVNI da Estação de Pets para abrir ovos.", nil, "warning")
			return
		end
		-- Quantidade: 1 ou Config.MultiOpen (validada no modelo).
		local amount = extra == Config.MultiOpen and Config.MultiOpen or 1
		local ok, message, results = inventory:HatchEggs(argument, amount, function()
			return hatchRandom:NextNumber()
		end)
		local missions = ok and inventory:Progress("Pet", results[1].PetId) or nil
		publish(player, message, nil, ok and "success" or "error", { Missions = missions, Hatches = results })
		return
	end
	if action == "EquipPet" or action == "UnequipPet" then
		local root = alive(player)
		if (action == "EquipPet" and typeof(argument) ~= "string") or not root
			or now - (lastPetChange[player] or -math.huge) < 0.6 then
			return
		end
		lastPetChange[player] = now
		local ok, message
		if action == "EquipPet" then
			ok, message = inventory:EquipPet(argument)
		else
			ok, message = inventory:EquipPet(nil)
		end
		local missions = ok and inventory:Progress("Pet", argument) or nil
		publish(player, message, nil, ok and "success" or "error", { Missions = missions })
		return
	end
	if action == "BuyBackpack" or action == "EquipBackpack" or action == "BuyUpgrade" then
		local root = alive(player)
		if typeof(argument) ~= "string" or not root or now - (lastBackpack[player] or -math.huge) < 0.5 then
			return
		end
		lastBackpack[player] = now
		if action == "EquipBackpack" then
			local ok, message = inventory:EquipBackpack(argument)
			publish(player, message, nil, ok and "success" or "error")
			return
		end
		-- Compra presencial: exige estar perto da Loja Orion.
		if not shopFloor or (root.Position - shopFloor.Position).Magnitude > 45 then
			publish(player, "Vá até a Loja Orion para comprar.", nil, "warning")
			return
		end
		local ok, message
		if action == "BuyBackpack" then
			ok, message = inventory:BuyBackpack(argument)
		else
			ok, message = inventory:Purchase(argument)
		end
		local missions = ok and inventory:Progress("Buy") or nil
		publish(player, message, nil, ok and "success" or "error", { Missions = missions })
		return
	end
	if action == "Rebirth" then
		if now - (lastRebirth[player] or -math.huge) < 2 then return end
		lastRebirth[player] = now
		local ok, message = inventory:Rebirth()
		publish(player, message, nil, ok and "success" or "error")
		if ok then
			task.spawn(save, player, false) -- marco importante: salva logo
		end
		return
	end
	if action ~= nil then
		return
	end
	if now - (lastSnapshot[player] or -math.huge) < 1 then
		return
	end
	lastSnapshot[player] = now
	publish(player)
end

function Service.Init()
	if initialized then
		return
	end
	initialized = true
	DataService.Init()

	remote = Instance.new("RemoteEvent")
	remote.Name = "InventoryState"
	remote.OnServerEvent:Connect(trackedAction)
	remote.Parent = ReplicatedStorage

	leaderboardData = Instance.new("Folder")
	leaderboardData.Name = "LeaderboardData"
	leaderboardData.Parent = ReplicatedStorage

	local world = workspace:WaitForChild("TerraNova")
	local counter = world:WaitForChild("SaleStation"):WaitForChild("Counter")
	petTerminal = world:WaitForChild("PetShop"):WaitForChild("Terminal")
	createPrompt(petTerminal, "OpenPets", "Abrir ovos / equipar pets", "OVNI de resgate", 10)

	local sell = createPrompt(counter, "SellMinerals", "Vender minerais", "Estação de Venda", 12, 0.2)
	sell.Triggered:Connect(function(player)
		local inventory = getInventory(player)
		local now = os.clock()
		if not inventory or now - (lastSale[player] or -math.huge) < 0.5 then return end
		lastSale[player] = now
		local root = alive(player)
		-- O prompt é só a entrada; validar a proximidade novamente no servidor.
		if not root or (root.Position - counter.Position).Magnitude > sell.MaxActivationDistance then return end
		local earned, levelUp, missions = inventory:SellAll()
		logCredits(player, Enum.AnalyticsEconomyFlowType.Source, earned, inventory.credits,
			Enum.AnalyticsEconomyTransactionType.Gameplay.Name, "Sale")
		publish(player, earned > 0 and ("Venda concluída: +" .. earned .. " Créditos.") or "Sua mochila está vazia.",
			nil, earned > 0 and "sale" or "warning", { LevelUp = levelUp, Missions = missions })
	end)

	-- A loja é um menu: o prompt só pede ao cliente para abrir a interface.
	local shop = world:WaitForChild("Shop")
	shopFloor = shop:WaitForChild("Floor")
	createPrompt(shop:WaitForChild("PurchaseDesk"), "OpenShop", "Abrir loja", "Loja Orion", 14)

	-- Peças opcionais do cenário (transmissor e hangar) podem chegar depois:
	-- configuradas em segundo plano para não atrasar o restante do Init.
	task.spawn(function()
		-- Missão 5: transmissor da caverna azul (exige nível de acesso à caverna).
		local transmitter = world:WaitForChild("Cave"):WaitForChild("Transmitter", 10)
		if transmitter then
			local activate = createPrompt(transmitter, "ActivateTransmitter", "Reativar transmissor", "Caverna azul", 10, 1)
			activate.Triggered:Connect(function(player)
				local inventory = getInventory(player)
				local now = os.clock()
				if not inventory or now - (lastTransmitter[player] or -math.huge) < 1 then return end
				lastTransmitter[player] = now
				local root = alive(player)
				if not root or (root.Position - transmitter.Position).Magnitude > 14 then return end
				if inventory:CanUseTransmitter() then
					local missions = inventory:Progress("Transmitter")
					publish(player, "Transmissor reativado! Um sinal ecoa pela galáxia…", nil, "success", { Missions = missions })
				elseif inventory:CurrentMission() and inventory:CurrentMission().Kind == "Transmitter" then
					publish(player, "O transmissor exige nível " .. Config.Progression.CaveLevel .. " de explorador.", nil, "warning")
				else
					publish(player, "O transmissor está em silêncio… por enquanto.", nil, "info")
				end
			end)
		end

		-- Hangar: só abre a apresentação da Orion Scout no cliente.
		local terminal = world:WaitForChild("Hangar"):WaitForChild("Terminal", 10)
		if terminal then
			createPrompt(terminal, "OpenHangar", "Ver nave e destinos", "Hangar Orion", 12)
		end
	end)

	Players.PlayerAdded:Connect(function(player) task.spawn(load, player) end)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(load, player) end

	Players.PlayerRemoving:Connect(function(player)
		save(player, true)
		inventories[player] = nil
		lastSnapshot[player] = nil
		lastPetChange[player] = nil
		lastSale[player] = nil
		lastBackpack[player] = nil
		lastRebirth[player] = nil
		lastTransmitter[player] = nil
		lastSettings[player] = nil
	end)

	-- Ao fechar o servidor, salva todos em paralelo e espera terminar.
	game:BindToClose(function()
		local pending = 0
		for player in pairs(inventories) do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		-- Também espera salvamentos já em andamento (ex.: disparados pela saída do jogador).
		while (pending > 0 or next(saving) ~= nil) and os.clock() < deadline do
			task.wait(0.2)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in pairs(inventories) do
				task.spawn(save, player, false)
			end
		end
	end)
	task.spawn(function()
		while true do
			pcall(refreshLeaderboards)
			task.wait(LEADERBOARD_INTERVAL)
		end
	end)
end

return Service
