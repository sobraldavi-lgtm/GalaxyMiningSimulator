local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local InventoryModel = require(script.Parent:WaitForChild("InventoryModel"))
local Service = {}
local inventories = {}
local lastSnapshot = {}
local lastPetChange = {}
local lastSale = {}
local initialized = false
local remote

local function getInventory(player)
	if not inventories[player] then
		inventories[player] = InventoryModel.new(Config)
	end
	return inventories[player]
end

local function publish(player, message, petReveal)
	local snapshot = getInventory(player):Snapshot()
	snapshot.Message = message
	snapshot.PetReveal = petReveal
	remote:FireClient(player, snapshot)
end

function Service.CanFit(player, oreType)
	return getInventory(player):CanFit(oreType)
end

function Service.GetPower(player)
	return getInventory(player):GetMiningPower()
end

function Service.Train(player)
	local progressed, gained = getInventory(player):TrainMining()
	if progressed then
		publish(player, gained and "Treino • +1 de poder" or nil)
	end
end

function Service.Add(player, oreType)
	local success = getInventory(player):Add(oreType)
	if success then
		publish(player, "+1 " .. Config.Ores[oreType].Name)
	end
	return success
end

function Service.Init()
	if initialized then
		return
	end
	initialized = true
	remote = Instance.new("RemoteEvent")
	remote.Name = "InventoryState"
	remote.OnServerEvent:Connect(function(player, action, equipped)
		local now = os.clock()
		if action == "SetLuminiEquipped" then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if typeof(equipped) ~= "boolean" or not humanoid or humanoid.Health <= 0
				or now - (lastPetChange[player] or -math.huge) < 0.6 then
				return
			end
			lastPetChange[player] = now
			if getInventory(player):SetLuminiEquipped(equipped) then
				player:SetAttribute("LuminiEquipped", equipped)
				publish(player, equipped and "Lumini equipada." or "Lumini guardada.")
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
	end)
	remote.Parent = ReplicatedStorage

	local counter = workspace:WaitForChild("TerraNova"):WaitForChild("Shop"):WaitForChild("Counter")
	local discovery = counter.Parent.Parent:WaitForChild("PetShop"):WaitForChild("Terminal")
	local price = 75
	local encounter = Instance.new("ProximityPrompt")
	encounter.ActionText = "Resgatar / equipar"
	encounter.ObjectText = "Lumini • primeiro resgate: " .. price .. " Créditos"
	encounter.MaxActivationDistance = 9
	encounter.HoldDuration = 0.35
	encounter.RequiresLineOfSight = false
	encounter.Triggered:Connect(function(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not encounter.Enabled or not root or not humanoid or humanoid.Health <= 0
			or (root.Position - discovery.Position).Magnitude > encounter.MaxActivationDistance then
			return
		end
		local now = os.clock()
		if now - (lastPetChange[player] or -math.huge) < 0.6 then
			return
		end
		lastPetChange[player] = now
		local discovered, equipped, errorMessage = getInventory(player):InteractWithLumini(price)
		if errorMessage then
			publish(player, errorMessage)
			return
		end
		player:SetAttribute("LuminiEquipped", equipped)
		local message = equipped and "Lumini equipada • +10% de poder." or "Lumini guardada na coleção."
		publish(player, discovered and "Lumini resgatada e equipada!" or message, discovered and "Lumini" or nil)
	end)
	encounter.Parent = discovery
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellMinerals"
	prompt.ActionText = "Vender minerais"
	prompt.ObjectText = "Balcão ORION"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player)
		local now = os.clock()
		if now - (lastSale[player] or -math.huge) < 0.5 then
			return
		end
		lastSale[player] = now
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not prompt.Enabled or not root or not humanoid or humanoid.Health <= 0 then
			return
		end
		-- O prompt é só a entrada; validar a proximidade novamente no servidor.
		if (root.Position - counter.Position).Magnitude > prompt.MaxActivationDistance then
			return
		end
		local earned = getInventory(player):Sell()
		publish(player, earned > 0 and ("Venda concluída: +" .. earned .. " Créditos.") or "Sua mochila está vazia.")
	end)
	prompt.Parent = counter

	-- Compra presencial em expositores separados. IDs, preços e efeitos são do servidor.
	local shop = counter.Parent
	local offers = {
		{ Id = "TitaniumDrill", Display = "Display-74", Key = Enum.KeyCode.F, GamepadKey = Enum.KeyCode.ButtonY },
		{ Id = "ReinforcedBackpack", Display = "Display-62", Key = Enum.KeyCode.G, GamepadKey = Enum.KeyCode.ButtonB },
	}
	for _, offer in ipairs(offers) do
		local display = shop:WaitForChild(offer.Display)
		local upgrade = Config.Upgrades[offer.Id]
		local buyPrompt = Instance.new("ProximityPrompt")
		buyPrompt.Name = "Buy" .. offer.Id
		buyPrompt.ActionText = "Comprar • " .. upgrade.Price .. " Créditos"
		buyPrompt.ObjectText = upgrade.Name
		buyPrompt.KeyboardKeyCode = offer.Key
		buyPrompt.GamepadKeyCode = offer.GamepadKey
		buyPrompt.HoldDuration = 0.4
		buyPrompt.MaxActivationDistance = 10
		buyPrompt.RequiresLineOfSight = false
		buyPrompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		buyPrompt.Triggered:Connect(function(player)
			local now = os.clock()
			if now - (lastSale[player] or -math.huge) < 0.5 then
				return
			end
			lastSale[player] = now
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not buyPrompt.Enabled or not root or not humanoid or humanoid.Health <= 0 then
				return
			end
			if (root.Position - display.Position).Magnitude > buyPrompt.MaxActivationDistance then
				return
			end
			local _, message = getInventory(player):Purchase(offer.Id)
			publish(player, message)
		end)
		buyPrompt.Parent = display
	end

	Players.PlayerRemoving:Connect(function(player)
		inventories[player] = nil
		lastSnapshot[player] = nil
		lastPetChange[player] = nil
		lastSale[player] = nil
	end)
end

return Service
