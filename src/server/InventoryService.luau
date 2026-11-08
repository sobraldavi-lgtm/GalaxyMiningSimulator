local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local InventoryModel = require(script.Parent:WaitForChild("InventoryModel"))
local Service = {}
local inventories = {}
local lastSnapshot = {}
local lastPetChange = {}
local lastSale = {}
local lastBackpack = {}
local initialized = false
local remote
local shopFloor
local petTerminal

local function getInventory(player)
	if not inventories[player] then
		inventories[player] = InventoryModel.new(Config)
	end
	return inventories[player]
end

-- Tone é só apresentação: indica ao cliente a cor e o ícone da notificação
-- (success, error, warning, sale, power, pickup). Não carrega regras.
local function publish(player, message, petReveal, tone)
	local snapshot = getInventory(player):Snapshot()
	-- Atributo replicado só para apresentação: todos os clientes desenham a ferramenta.
	if player:GetAttribute("EquippedTool") ~= snapshot.ToolId then
		player:SetAttribute("EquippedTool", snapshot.ToolId)
	end
	snapshot.Message = message
	snapshot.PetReveal = petReveal
	snapshot.Tone = tone
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
		publish(player, gained and "Treino • +1 de poder" or nil, nil, "power")
	end
end

function Service.Add(player, oreType)
	local success = getInventory(player):Add(oreType)
	if success then
		publish(player, "+1 " .. Config.Ores[oreType].Name, nil, "pickup")
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
		if action == "BuyPet" or action == "EquipPet" or action == "UnequipPet" then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if (action ~= "UnequipPet" and typeof(equipped) ~= "string") or not root or not humanoid
				or humanoid.Health <= 0 or now - (lastPetChange[player] or -math.huge) < 0.6 then
				return
			end
			lastPetChange[player] = now
			local inventory = getInventory(player)
			local ok, message
			if action == "BuyPet" then
				-- Resgate presencial no OVNI da Estação de Pets.
				if not petTerminal or (root.Position - petTerminal.Position).Magnitude > 40 then
					publish(player, "Vá até a Estação de Pets para resgatar.", nil, "warning")
					return
				end
				ok, message = inventory:BuyPet(equipped)
			elseif action == "EquipPet" then
				ok, message = inventory:EquipPet(equipped)
			else
				ok, message = inventory:EquipPet(nil)
			end
			player:SetAttribute("EquippedPet", inventory.equippedPet)
			publish(player, message, (ok and action == "BuyPet") and equipped or nil, ok and "success" or "error")
			return
		end
		if action == "BuyBackpack" or action == "EquipBackpack" or action == "BuyUpgrade" then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if typeof(equipped) ~= "string" or not root or not humanoid or humanoid.Health <= 0
				or now - (lastBackpack[player] or -math.huge) < 0.5 then
				return
			end
			lastBackpack[player] = now
			local inventory = getInventory(player)
			if action == "BuyBackpack" or action == "BuyUpgrade" then
				-- Compra presencial: exige estar perto da Loja Orion.
				if not shopFloor or (root.Position - shopFloor.Position).Magnitude > 45 then
					publish(player, "Vá até a Loja Orion para comprar.", nil, "warning")
					return
				end
				local ok, message
				if action == "BuyBackpack" then
					ok, message = inventory:BuyBackpack(equipped)
				else
					ok, message = inventory:Purchase(equipped)
				end
				publish(player, message, nil, ok and "success" or "error")
			else
				local ok, message = inventory:EquipBackpack(equipped)
				publish(player, message, nil, ok and "success" or "error")
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

	local world = workspace:WaitForChild("TerraNova")
	local counter = world:WaitForChild("SaleStation"):WaitForChild("Counter")
	petTerminal = world:WaitForChild("PetShop"):WaitForChild("Terminal")
	local openPets = Instance.new("ProximityPrompt")
	openPets.Name = "OpenPets"
	openPets.ActionText = "Resgatar / equipar pets"
	openPets.ObjectText = "OVNI de resgate"
	openPets.HoldDuration = 0
	openPets.MaxActivationDistance = 10
	openPets.RequiresLineOfSight = false
	openPets.Parent = petTerminal
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellMinerals"
	prompt.ActionText = "Vender minerais"
	prompt.ObjectText = "Estação de Venda"
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
		publish(player, earned > 0 and ("Venda concluída: +" .. earned .. " Créditos.") or "Sua mochila está vazia.",
			nil, earned > 0 and "sale" or "warning")
	end)
	prompt.Parent = counter

	-- A loja é um menu: o prompt só pede ao cliente para abrir a interface.
	-- Preços, saldo e efeitos continuam validados pelo servidor nas compras.
	local shop = world:WaitForChild("Shop")
	shopFloor = shop:WaitForChild("Floor")
	local openShop = Instance.new("ProximityPrompt")
	openShop.Name = "OpenShop"
	openShop.ActionText = "Abrir loja"
	openShop.ObjectText = "Loja Orion"
	openShop.KeyboardKeyCode = Enum.KeyCode.E
	openShop.GamepadKeyCode = Enum.KeyCode.ButtonX
	openShop.HoldDuration = 0
	openShop.MaxActivationDistance = 14
	openShop.RequiresLineOfSight = false
	openShop.Parent = shop:WaitForChild("PurchaseDesk")

	local function equipDefaults(player)
		player:SetAttribute("EquippedTool", getInventory(player).toolId)
	end
	Players.PlayerAdded:Connect(equipDefaults)
	for _, player in ipairs(Players:GetPlayers()) do equipDefaults(player) end

	Players.PlayerRemoving:Connect(function(player)
		inventories[player] = nil
		lastSnapshot[player] = nil
		lastPetChange[player] = nil
		lastSale[player] = nil
		lastBackpack[player] = nil
	end)
end

return Service
