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
		backpackName = starting.Name,
		ownedUpgrades = {},
	}, InventoryModel)
end

function InventoryModel:CanFit(oreType)
	local ore = self.config.Ores[oreType]
	return ore ~= nil and self.weight + ore.Weight <= self.capacity
end

function InventoryModel:GetMiningPower()
	local multiplier = self.luminiEquipped and (1 + self.config.LuminiBonus) or 1
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

function InventoryModel:SetLuminiEquipped(equipped)
	if not self.luminiDiscovered then
		return false
	end
	self.luminiEquipped = equipped
	return true
end

function InventoryModel:InteractWithLumini(price)
	local discovered = not self.luminiDiscovered
	if discovered then
		if self.credits < price then
			return false, self.luminiEquipped, "Faltam " .. (price - self.credits) .. " Créditos para resgatar Lumini."
		end
		self.credits -= price
	end
	self.luminiDiscovered = true
	self.luminiEquipped = not self.luminiEquipped
	return discovered, self.luminiEquipped
end

function InventoryModel:Add(oreType)
	if not self:CanFit(oreType) then
		return false
	end
	self.items[oreType] = (self.items[oreType] or 0) + 1
	self.weight += self.config.Ores[oreType].Weight
	return true
end

function InventoryModel:Sell()
	local earned = 0
	for oreType, count in pairs(self.items) do
		earned += self.config.Ores[oreType].Value * count
	end
	self.credits += earned
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
	if self.credits < upgrade.Price then
		return false, "Créditos insuficientes: faltam " .. (upgrade.Price - self.credits) .. "."
	end
	if upgrade.Kind == "Tool" then
		self.power = upgrade.Power
		self.toolName = upgrade.Name
	else
		return false, "Tipo de melhoria inválido."
	end
	self.credits -= upgrade.Price
	self.ownedUpgrades[upgradeId] = true
	return true, upgrade.Name .. " comprada e equipada!"
end

function InventoryModel:Snapshot()
	return {
		Items = table.clone(self.items),
		Weight = self.weight,
		Capacity = self.capacity,
		Credits = self.credits,
		LuminiDiscovered = self.luminiDiscovered == true,
		LuminiEquipped = self.luminiEquipped == true,
		Power = self:GetMiningPower(),
		TrainingPower = self:GetTrainingPower(),
		PowerCap = self:GetPowerCap(),
		BackpackId = self.backpackId,
		OwnedBackpacks = table.clone(self.ownedBackpacks),
		TrainingClicks = self.trainingClicks,
		ToolName = self.toolName,
		BackpackName = self.backpackName,
	}
end

return InventoryModel
