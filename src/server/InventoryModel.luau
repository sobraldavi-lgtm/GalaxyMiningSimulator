-- Regras de inventário independentes das APIs do Studio.
local InventoryModel = {}
InventoryModel.__index = InventoryModel

local function findBackpack(config, id)
	for index, backpack in ipairs(config.Backpacks) do
		if backpack.Id == id then
			return backpack, index
		end
	end
	return nil
end

local function findPet(config, id)
	for _, pet in ipairs(config.Pets) do
		if pet.Id == id then
			return pet
		end
	end
	return nil
end

function InventoryModel.new(config)
	local starting = findBackpack(config, config.StartingBackpack)
	return setmetatable({
		config = config,
		items = {},
		weight = 0,
		credits = 0,
		capacity = starting.Capacity,
		backpackId = starting.Id,
		ownedBackpacks = { [starting.Id] = true },
		power = config.Power,
		trainingPower = 0,
		trainingClicks = 0,
		toolName = "Extrator Básico",
		toolId = "Basic",
		backpackName = starting.Name,
		ownedUpgrades = {},
		ownedPets = {},
		equippedPet = nil,
		-- Progressão (salva entre sessões).
		xp = 0,
		fragments = 0,
		missionIndex = 1,
		missionProgress = 0,
		rebirths = 0,
		lifetimeCredits = 0,
		purchases = 0,
		settings = {},
		pity = {},
		dailyStreak = 0,
		dailyLastDay = 0,
		autoSell = false,
		contracts = {},
	}, InventoryModel)
end

function InventoryModel:CanFit(oreType)
	local ore = self.config.Ores[oreType]
	return ore ~= nil and self.weight + ore.Weight <= self.capacity
end

function InventoryModel:GetMiningPower()
	local pet = self.equippedPet and findPet(self.config, self.equippedPet)
	local multiplier = pet and (1 + pet.Bonus) or 1
	return math.round(self.power * multiplier * 100) / 100 + self:GetTrainingPower()
end

function InventoryModel:GetPowerCap()
	return (findBackpack(self.config, self.backpackId)).PowerCap
end

-- O treino acumulado nunca passa do limite da mochila equipada.
function InventoryModel:GetTrainingPower()
	return math.min(self.trainingPower, self:GetPowerCap())
end

function InventoryModel:BuyBackpack(id)
	local backpack = findBackpack(self.config, id)
	if not backpack then
		return false, "Mochila inválida."
	end
	if self.ownedBackpacks[id] then
		return false, "Você já possui " .. backpack.Name .. "."
	end
	if self.credits < backpack.Price then
		return false, "Créditos insuficientes: faltam " .. (backpack.Price - self.credits) .. "."
	end
	self.credits -= backpack.Price
	self.ownedBackpacks[id] = true
	self.purchases += 1
	self:EquipBackpack(id, true)
	return true, "Mochila de " .. backpack.Name .. " comprada e equipada!"
end

function InventoryModel:EquipBackpack(id, force)
	local backpack = findBackpack(self.config, id)
	if not backpack or not self.ownedBackpacks[id] then
		return false, "Você não possui essa mochila."
	end
	if not force and self.weight > backpack.Capacity then
		return false, "Esvazie a mochila: a carga excede " .. backpack.Capacity .. "."
	end
	self.backpackId = id
	self.capacity = backpack.Capacity
	self.backpackName = backpack.Name
	return true, backpack.Name .. " equipada."
end

function InventoryModel:TrainMining()
	if self.trainingPower >= self:GetPowerCap() then
		return false, false
	end
	self.trainingClicks += 1
	local gained = self.trainingClicks >= self.config.TrainingClicksPerPoint
	if gained then
		self.trainingPower += 1
		self.trainingClicks = 0
	end
	return true, gained
end

local function findEgg(config, id)
	for _, egg in ipairs(config.Eggs) do
		if egg.Id == id then
			return egg
		end
	end
	return nil
end

-- Sorteia entre as entradas de um ovo, respeitando o peso de cada uma.
local function pick(entries, value)
	local total = 0
	for _, entry in ipairs(entries) do total += entry[2] end
	local target = value * total
	local sum = 0
	for _, entry in ipairs(entries) do
		sum += entry[2]
		if target < sum then return entry[1] end
	end
	return entries[#entries][1]
end

-- Abre um ovo já pago. Regras, nesta ordem:
--  1. quem ainda não tem pets e abre um ovo com o pet inicial recebe esse pet;
--  2. garantia: após (PityOpens - 1) aberturas sem raridade alta, sai uma delas;
--  3. caso contrário, sorteio normal pelas chances do ovo.
function InventoryModel:HatchOne(egg, roll)
	local config = self.config
	local petId
	if next(self.ownedPets) == nil then
		for _, entry in ipairs(egg.Odds) do
			if entry[1] == config.FirstEggPet then petId = entry[1] end
		end
	end
	local pity = self.pity[egg.Id] or 0
	local pityTriggered = false
	if not petId and pity >= config.PityOpens - 1 then
		local rare = {}
		for _, entry in ipairs(egg.Odds) do
			local candidate = findPet(config, entry[1])
			if candidate and config.PityRarities[candidate.Rarity] then table.insert(rare, entry) end
		end
		if #rare > 0 then
			petId = pick(rare, (roll or math.random)())
			pityTriggered = true
		end
	end
	if not petId then
		petId = pick(egg.Odds, (roll or math.random)())
	end
	local pet = findPet(config, petId)
	self.pity[egg.Id] = config.PityRarities[pet.Rarity] and 0 or pity + 1
	local duplicate = self.ownedPets[petId] == true
	local refund = 0
	local equipped = false
	if duplicate then
		refund = math.floor(egg.Price * config.DuplicateRefund)
		self.credits += refund
	else
		self.ownedPets[petId] = true
		local current = self.equippedPet and findPet(config, self.equippedPet)
		if not current or pet.Bonus > current.Bonus then
			self.equippedPet = petId
			equipped = true
		end
	end
	return { Egg = egg.Id, PetId = petId, Duplicate = duplicate, Refund = refund,
		Equipped = equipped, Pity = pityTriggered }
end

-- Abre `count` ovos (1 ou MultiOpen). Cobra tudo antes; devolve a lista de resultados.
function InventoryModel:HatchEggs(eggId, count, roll)
	local egg = findEgg(self.config, eggId)
	if not egg then
		return false, "Ovo inválido."
	end
	if count ~= 1 and count ~= self.config.MultiOpen then
		return false, "Quantidade inválida."
	end
	local cost = egg.Price * count
	if self.credits < cost then
		return false, "Faltam " .. (cost - self.credits) .. " Créditos para abrir "
			.. (count > 1 and (count .. "× ") or "o ") .. egg.Name .. "."
	end
	self.credits -= cost
	local results, names = {}, {}
	for _ = 1, count do
		local result = self:HatchOne(egg, roll)
		table.insert(results, result)
		local pet = findPet(self.config, result.PetId)
		table.insert(names, pet.Name .. (result.Duplicate and "" or " (novo)"))
	end
	local message
	if count == 1 then
		local pet = findPet(self.config, results[1].PetId)
		if results[1].Duplicate then
			message = pet.Name .. " repetido: +" .. results[1].Refund .. " Créditos devolvidos."
		else
			message = "Nasceu " .. pet.Name .. " (" .. pet.Rarity .. ")!" .. (results[1].Equipped and " Equipado." or "")
		end
	else
		message = count .. " ovos abertos: " .. table.concat(names, ", ") .. "."
	end
	return true, message, results
end

-- Atalho para um ovo (usado pelos testes): devolve o primeiro resultado.
function InventoryModel:HatchEgg(eggId, roll)
	local ok, message, results = self:HatchEggs(eggId, 1, roll)
	return ok, message, results and results[1]
end

-- id = nil guarda o pet atual.
function InventoryModel:EquipPet(id)
	if id == nil then
		self.equippedPet = nil
		return true, "Pet guardado."
	end
	local pet = findPet(self.config, id)
	if not pet or not self.ownedPets[id] then
		return false, "Você não possui esse pet."
	end
	self.equippedPet = id
	return true, pet.Name .. " equipado • +" .. math.round(pet.Bonus * 100) .. "% de poder."
end

function InventoryModel:Add(oreType)
	if not self:CanFit(oreType) then
		return false
	end
	self.items[oreType] = (self.items[oreType] or 0) + 1
	self.weight += self.config.Ores[oreType].Weight
	return true
end

function InventoryModel:GetSaleMultiplier()
	local rebirth = self.config.Rebirth
	return 1 + self.rebirths * (rebirth and rebirth.SaleBonus or 0)
end

-- rate opcional (ex.: 0,8 na venda automática).
function InventoryModel:Sell(rate)
	local earned = 0
	for oreType, count in pairs(self.items) do
		earned += self.config.Ores[oreType].Value * count
	end
	earned = math.floor(earned * self:GetSaleMultiplier() * (rate or 1))
	self.credits += earned
	self.lifetimeCredits += earned
	table.clear(self.items)
	self.weight = 0
	return earned
end

function InventoryModel:Purchase(upgradeId)
	local upgrade = self.config.Upgrades[upgradeId]
	if not upgrade then
		return false, "Melhoria inválida."
	end
	if self.ownedUpgrades[upgradeId] then
		return false, "Você já possui " .. upgrade.Name .. "."
	end
	if upgrade.Kind == "Tool" and upgrade.Power <= self.power then
		return false, "Você já tem uma ferramenta melhor."
	end
	if self.credits < upgrade.Price then
		return false, "Créditos insuficientes: faltam " .. (upgrade.Price - self.credits) .. "."
	end
	if upgrade.Kind == "Tool" then
		self.power = upgrade.Power
		self.toolName = upgrade.Name
		self.toolId = upgradeId
	else
		return false, "Tipo de melhoria inválido."
	end
	self.credits -= upgrade.Price
	self.ownedUpgrades[upgradeId] = true
	self.purchases += 1
	return true, upgrade.Name .. " comprada e equipada!"
end

-- ---------- Progressão: XP, nível, missões e renascimento ----------

-- Nível atual, XP do início do nível e XP do próximo nível.
function InventoryModel:GetLevel()
	local progression = self.config.Progression
	local levels = progression.LevelXp
	local level = 1
	for index, need in ipairs(levels) do
		if self.xp >= need then level = index end
	end
	local floorXp = levels[level]
	local nextXp = levels[level + 1]
	if level == #levels then
		local step = progression.LevelStepAfter
		local extra = math.floor((self.xp - levels[#levels]) / step)
		level += extra
		floorXp = levels[#levels] + extra * step
		nextXp = floorXp + step
	end
	return level, floorXp, nextXp
end

-- Soma XP e devolve o novo nível quando sobe (ou nil).
function InventoryModel:AddXp(amount)
	if amount <= 0 then return nil end
	local before = self:GetLevel()
	self.xp += amount
	local after = self:GetLevel()
	return after > before and after or nil
end

function InventoryModel:CurrentMission()
	return self.config.Missions[self.missionIndex]
end

-- Missões que dependem do estado já alcançado (podem concluir na hora).
function InventoryModel:MissionSatisfied(mission)
	if mission.Kind == "Pet" then
		return self.equippedPet == mission.Target
	elseif mission.Kind == "Buy" then
		return self.purchases > 0
	end
	return self.missionProgress >= mission.Count
end

-- Registra um evento e conclui missões em sequência; devolve as concluídas.
function InventoryModel:Progress(kind, target, amount)
	local completed = {}
	while true do
		local mission = self:CurrentMission()
		if not mission then break end
		if kind and mission.Kind == kind and (mission.Target == nil or mission.Target == target) then
			self.missionProgress += amount or 1
		end
		kind = nil -- o evento conta só para a missão ativa no momento
		if not self:MissionSatisfied(mission) then break end
		self.credits += mission.Credits
		-- Contador da sessão: separa recompensas de missão dos gastos (analytics).
		self.rewardedCredits = (self.rewardedCredits or 0) + mission.Credits
		self.fragments += mission.Fragments
		self.missionIndex += 1
		self.missionProgress = 0
		table.insert(completed, mission)
	end
	-- Ao terminar a campanha, os contratos repetíveis aparecem.
	self:FillContracts()
	return completed
end

-- Coleta com progressão: XP e missão de mineração.
function InventoryModel:Mine(oreType)
	if not self:Add(oreType) then
		return false, nil, {}
	end
	local levelUp = self:AddXp(self.config.Progression.XpPerOre)
	local completed = self:Progress("Mine", oreType)
	for _, contract in ipairs(self:UpdateContracts("Mine", oreType, 1)) do
		table.insert(completed, contract)
	end
	return true, levelUp, completed
end

-- Venda com progressão. Devolve Créditos ganhos, nível novo e missões.
-- A XP da venda é limitada à quantidade de minérios vendidos: vender um
-- minério por vez não rende mais XP do que minerar (evita farm de XP).
function InventoryModel:SellAll(rate)
	local units = 0
	for _, amount in pairs(self.items) do
		units += amount
	end
	local earned = self:Sell(rate)
	if earned <= 0 then
		return 0, nil, {}
	end
	local levelUp = self:AddXp(math.min(self.config.Progression.XpPerSale, units))
	local completed = self:Progress("Sell")
	for _, contract in ipairs(self:UpdateContracts("Earn", nil, earned)) do
		table.insert(completed, contract)
	end
	return earned, levelUp, completed
end

function InventoryModel:CanUseTransmitter()
	local mission = self:CurrentMission()
	return mission ~= nil and mission.Kind == "Transmitter" and self:GetLevel() >= self.config.Progression.CaveLevel
end

function InventoryModel:RebirthCost()
	return self.config.Rebirth.BaseCost * (self.rebirths + 1)
end

-- Renascer: reinicia a economia da partida e soma bônus permanente de venda.
function InventoryModel:Rebirth()
	local cost = self:RebirthCost()
	if self.credits < cost then
		return false, "Faltam " .. (cost - self.credits) .. " Créditos para renascer."
	end
	local starting = findBackpack(self.config, self.config.StartingBackpack)
	self.items = {}
	self.weight = 0
	self.credits = 0
	self.capacity = starting.Capacity
	self.backpackId = starting.Id
	self.backpackName = starting.Name
	self.ownedBackpacks = { [starting.Id] = true }
	self.power = self.config.Power
	self.trainingPower = 0
	self.trainingClicks = 0
	self.toolName = "Extrator Básico"
	self.toolId = "Basic"
	self.ownedUpgrades = {}
	self.rebirths += 1
	return true, string.format("Renascimento nº %d! Vendas agora rendem +%d%%.", self.rebirths,
		math.round((self:GetSaleMultiplier() - 1) * 100))
end

-- Preferências de interface: só chaves conhecidas e valores booleanos.
function InventoryModel:SetSettings(values)
	if type(values) ~= "table" then return false end
	local allowed = {}
	for _, key in ipairs(self.config.ClientSettings) do allowed[key] = true end
	local clean = {}
	for key, value in pairs(values) do
		if allowed[key] and type(value) == "boolean" then
			clean[key] = value
		end
	end
	self.settings = clean
	return true
end

-- ---------- Prêmio diário ----------
-- `today` é o número do dia UTC (os.time() // 86400), calculado no servidor.
function InventoryModel:DailyAvailable(today)
	return self.dailyLastDay < today
end

function InventoryModel:ClaimDaily(today)
	if self.dailyLastDay >= today then
		return false, "Prêmio de hoje já resgatado. Volte amanhã!"
	end
	-- Sequência continua se o último resgate foi ontem; senão recomeça.
	self.dailyStreak = (self.dailyLastDay == today - 1) and self.dailyStreak + 1 or 1
	self.dailyLastDay = today
	local rewards = self.config.DailyRewards
	local day = (self.dailyStreak - 1) % #rewards + 1
	local reward = rewards[day]
	local credits = math.floor(reward.Credits * self:GetSaleMultiplier())
	self.credits += credits
	self.rewardedCredits = (self.rewardedCredits or 0) + credits
	self.fragments += reward.Fragments
	local extra = reward.Fragments > 0 and (" e +" .. reward.Fragments .. " Fragmento" .. (reward.Fragments > 1 and "s" or "")) or ""
	return true, "Prêmio do dia " .. day .. ": +" .. credits .. " Créditos" .. extra .. "!",
		{ Day = day, Credits = credits, Fragments = reward.Fragments, Streak = self.dailyStreak }
end

-- ---------- Venda automática ----------
function InventoryModel:AutoSellUnlocked()
	return self:GetLevel() >= self.config.AutoSell.Level
end

function InventoryModel:CanAutoSell()
	return self.autoSell and self:AutoSellUnlocked()
end

function InventoryModel:SetAutoSell(on)
	if type(on) ~= "boolean" then
		return false, "Valor inválido."
	end
	if on and not self:AutoSellUnlocked() then
		return false, "A venda automática libera no nível " .. self.config.AutoSell.Level .. "."
	end
	self.autoSell = on
	return true, on and ("Venda automática ligada (" .. math.round(self.config.AutoSell.Rate * 100) .. "% do valor).")
		or "Venda automática desligada."
end

-- Vende tudo pela taxa reduzida (ao encher a mochila em qualquer lugar).
function InventoryModel:AutoSellAll()
	return self:SellAll(self.config.AutoSell.Rate)
end

-- ---------- Contratos da Orion (missões repetíveis) ----------

-- Minérios que quebram em poucos golpes com o poder atual, do mais valioso ao menos.
local function viableOres(self)
	local power = math.max(self:GetMiningPower(), 0.01)
	local list = {}
	for id, ore in pairs(self.config.Ores) do
		if math.ceil(ore.Resistance / power) <= self.config.Contracts.MineMaxHits then
			table.insert(list, { id = id, ore = ore })
		end
	end
	table.sort(list, function(a, b) return a.ore.Value > b.ore.Value end)
	if #list == 0 then
		table.insert(list, { id = "Iron", ore = self.config.Ores.Iron })
	end
	return list
end

function InventoryModel:NewContract(roll)
	local settings = self.config.Contracts
	local random = roll or math.random
	local value = random()
	local multiplier = self:GetSaleMultiplier()
	if value < 0.45 then
		-- Minerar um dos 3 melhores minérios viáveis.
		local list = viableOres(self)
		local choice = list[math.min(#list, 1 + math.floor(random() * math.min(3, #list)))]
		return { Kind = "Mine", Target = choice.id, Count = settings.MineCount, Progress = 0,
			Credits = math.floor(choice.ore.Value * settings.MineCount * settings.MineRewardFactor * multiplier),
			Fragments = 1 }
	elseif value < 0.8 then
		-- Ganhar Créditos em vendas: meta proporcional à mochila e ao melhor minério viável.
		local best = viableOres(self)[1].ore
		local perBackpack = math.floor(self.capacity / best.Weight) * best.Value * multiplier
		local target = math.max(100, math.floor(perBackpack * settings.EarnBackpacks / 50 + 0.5) * 50)
		return { Kind = "Earn", Count = target, Progress = 0,
			Credits = math.floor(target * settings.EarnRewardFactor), Fragments = 1 }
	end
	return { Kind = "Hatch", Count = settings.HatchCount, Progress = 0, Credits = 0, Fragments = settings.HatchFragments }
end

-- Contratos só existem depois da campanha de ORBI.
function InventoryModel:FillContracts(roll)
	if self:CurrentMission() then return end
	while #self.contracts < self.config.Contracts.Slots do
		table.insert(self.contracts, self:NewContract(roll))
	end
end

-- Avança contratos do tipo do evento; concluídos pagam e são trocados por novos.
function InventoryModel:UpdateContracts(kind, target, amount, roll)
	local done = {}
	for index, contract in ipairs(self.contracts) do
		if contract.Kind == kind and (contract.Target == nil or contract.Target == target) then
			contract.Progress = math.min(contract.Count, contract.Progress + (amount or 1))
			if contract.Progress >= contract.Count then
				self.credits += contract.Credits
				self.rewardedCredits = (self.rewardedCredits or 0) + contract.Credits
				self.fragments += contract.Fragments
				table.insert(done, { Title = "Contrato concluído", Credits = contract.Credits,
					Fragments = contract.Fragments, Contract = true, Kind = contract.Kind })
				self.contracts[index] = self:NewContract(roll)
			end
		end
	end
	return done
end

local function cloneContracts(list)
	local copy = {}
	for index, contract in ipairs(list) do copy[index] = table.clone(contract) end
	return copy
end

-- ---------- Salvamento ----------
-- O treino de poder é por sessão (GDD) e não é salvo.

local SAVE_VERSION = 1
InventoryModel.SaveVersion = SAVE_VERSION

function InventoryModel:Serialize()
	return {
		Version = SAVE_VERSION,
		Items = table.clone(self.items),
		Credits = self.credits,
		BackpackId = self.backpackId,
		OwnedBackpacks = table.clone(self.ownedBackpacks),
		ToolId = self.toolId,
		OwnedUpgrades = table.clone(self.ownedUpgrades),
		OwnedPets = table.clone(self.ownedPets),
		EquippedPet = self.equippedPet,
		Xp = self.xp,
		Fragments = self.fragments,
		MissionIndex = self.missionIndex,
		MissionProgress = self.missionProgress,
		Rebirths = self.rebirths,
		LifetimeCredits = self.lifetimeCredits,
		Purchases = self.purchases,
		Settings = table.clone(self.settings),
		Pity = table.clone(self.pity),
		DailyStreak = self.dailyStreak,
		DailyLastDay = self.dailyLastDay,
		AutoSell = self.autoSell,
		Contracts = cloneContracts(self.contracts),
	}
end

local function count(value)
	if type(value) ~= "number" or value ~= value or value == math.huge or value < 0 then
		return 0
	end
	return math.floor(value)
end

-- Reconstrói um inventário a partir de dados salvos, validando cada campo:
-- ids desconhecidos (itens removidos do catálogo) são descartados.
function InventoryModel.fromData(config, data)
	local inventory = InventoryModel.new(config)
	if type(data) ~= "table" then
		return inventory
	end
	if type(data.Items) == "table" then
		for oreType, amount in pairs(data.Items) do
			local ore = config.Ores[oreType]
			local units = count(amount)
			if ore and units > 0 then
				inventory.items[oreType] = units
				inventory.weight += ore.Weight * units
			end
		end
	end
	inventory.credits = count(data.Credits)
	if type(data.OwnedBackpacks) == "table" then
		for id, owned in pairs(data.OwnedBackpacks) do
			if owned == true and findBackpack(config, id) then inventory.ownedBackpacks[id] = true end
		end
	end
	if type(data.BackpackId) == "string" and inventory.ownedBackpacks[data.BackpackId] then
		inventory:EquipBackpack(data.BackpackId, true)
	end
	if type(data.OwnedUpgrades) == "table" then
		for id, owned in pairs(data.OwnedUpgrades) do
			if owned == true and config.Upgrades[id] then inventory.ownedUpgrades[id] = true end
		end
	end
	local tool = type(data.ToolId) == "string" and config.Upgrades[data.ToolId]
	if tool and inventory.ownedUpgrades[data.ToolId] then
		inventory.power = tool.Power
		inventory.toolName = tool.Name
		inventory.toolId = data.ToolId
	end
	if type(data.OwnedPets) == "table" then
		for id, owned in pairs(data.OwnedPets) do
			if owned == true and findPet(config, id) then inventory.ownedPets[id] = true end
		end
	end
	if type(data.EquippedPet) == "string" and inventory.ownedPets[data.EquippedPet] then
		inventory.equippedPet = data.EquippedPet
	end
	inventory.xp = count(data.Xp)
	inventory.fragments = count(data.Fragments)
	inventory.missionIndex = math.clamp(count(data.MissionIndex), 1, #config.Missions + 1)
	inventory.missionProgress = count(data.MissionProgress)
	inventory.rebirths = count(data.Rebirths)
	inventory.lifetimeCredits = count(data.LifetimeCredits)
	inventory.purchases = count(data.Purchases)
	inventory:SetSettings(data.Settings)
	inventory.dailyStreak = count(data.DailyStreak)
	inventory.dailyLastDay = count(data.DailyLastDay)
	inventory.autoSell = data.AutoSell == true
	if type(data.Contracts) == "table" then
		local kinds = { Mine = true, Earn = true, Hatch = true }
		for _, contract in ipairs(data.Contracts) do
			if #inventory.contracts >= config.Contracts.Slots then break end
			if type(contract) == "table" and kinds[contract.Kind] and count(contract.Count) > 0
				and (contract.Kind ~= "Mine" or config.Ores[contract.Target]) then
				table.insert(inventory.contracts, {
					Kind = contract.Kind,
					Target = contract.Kind == "Mine" and contract.Target or nil,
					Count = count(contract.Count),
					Progress = math.min(count(contract.Progress), count(contract.Count)),
					Credits = count(contract.Credits),
					Fragments = count(contract.Fragments),
				})
			end
		end
	end
	inventory:FillContracts()
	if type(data.Pity) == "table" then
		for eggId, value in pairs(data.Pity) do
			if findEgg(config, eggId) then inventory.pity[eggId] = count(value) end
		end
	end
	return inventory
end

function InventoryModel:Snapshot()
	local level, floorXp, nextXp = self:GetLevel()
	return {
		Items = table.clone(self.items),
		Weight = self.weight,
		Capacity = self.capacity,
		Credits = self.credits,
		OwnedPets = table.clone(self.ownedPets),
		EquippedPet = self.equippedPet,
		ToolPower = self.power,
		Power = self:GetMiningPower(),
		TrainingPower = self:GetTrainingPower(),
		PowerCap = self:GetPowerCap(),
		BackpackId = self.backpackId,
		OwnedBackpacks = table.clone(self.ownedBackpacks),
		OwnedUpgrades = table.clone(self.ownedUpgrades),
		TrainingClicks = self.trainingClicks,
		ToolName = self.toolName,
		ToolId = self.toolId,
		BackpackName = self.backpackName,
		Level = level,
		Xp = self.xp,
		LevelFloorXp = floorXp,
		NextLevelXp = nextXp,
		Fragments = self.fragments,
		MissionIndex = self.missionIndex,
		MissionProgress = self.missionProgress,
		Rebirths = self.rebirths,
		RebirthCost = self:RebirthCost(),
		SaleMultiplier = self:GetSaleMultiplier(),
		LifetimeCredits = self.lifetimeCredits,
		Settings = table.clone(self.settings),
		Pity = table.clone(self.pity),
		DailyStreak = self.dailyStreak,
		DailyLastDay = self.dailyLastDay,
		AutoSell = self.autoSell,
		AutoSellUnlocked = self:AutoSellUnlocked(),
		Contracts = cloneContracts(self.contracts),
	}
end

return InventoryModel
