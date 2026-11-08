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

function InventoryModel:BuyPet(id)
	local pet = findPet(self.config, id)
	if not pet then
		return false, "Pet inválido."
	end
	if self.ownedPets[id] then
		return false, "Você já possui " .. pet.Name .. "."
	end
	if self.credits < pet.Price then
		return false, "Faltam " .. (pet.Price - self.credits) .. " Créditos para resgatar " .. pet.Name .. "."
	end
	self.credits -= pet.Price
	self.ownedPets[id] = true
	self.equippedPet = id
	return true, pet.Name .. " resgatado e equipado!"
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

function InventoryModel:Sell()
	local earned = 0
	for oreType, count in pairs(self.items) do
		earned += self.config.Ores[oreType].Value * count
	end
	earned = math.floor(earned * self:GetSaleMultiplier())
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
		self.fragments += mission.Fragments
		self.missionIndex += 1
		self.missionProgress = 0
		table.insert(completed, mission)
	end
	return completed
end

-- Coleta com progressão: XP e missão de mineração.
function InventoryModel:Mine(oreType)
	if not self:Add(oreType) then
		return false, nil, {}
	end
	local levelUp = self:AddXp(self.config.Progression.XpPerOre)
	return true, levelUp, self:Progress("Mine", oreType)
end

-- Venda com progressão. Devolve Créditos ganhos, nível novo e missões.
-- A XP da venda é limitada à quantidade de minérios vendidos: vender um
-- minério por vez não rende mais XP do que minerar (evita farm de XP).
function InventoryModel:SellAll()
	local units = 0
	for _, amount in pairs(self.items) do
		units += amount
	end
	local earned = self:Sell()
	if earned <= 0 then
		return 0, nil, {}
	end
	local levelUp = self:AddXp(math.min(self.config.Progression.XpPerSale, units))
	return earned, levelUp, self:Progress("Sell")
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
	}
end

return InventoryModel
