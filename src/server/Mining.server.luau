local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))
local deposits = workspace:WaitForChild("TerraNova"):WaitForChild("OreDeposits")
local Inventory = require(script.Parent:WaitForChild("InventoryService"))
Inventory.Init()

-- O cliente envia a ação e, para golpes, o alvo. O servidor controla o progresso.
local remote = Instance.new("RemoteEvent")
remote.Name = "MiningRequest"
remote.Parent = script.Parent
-- Replicar somente o canal de comunicação; nenhum estado de jogador fica no cliente.
remote.Parent = ReplicatedStorage

local byPart = {}
for oreType, definition in pairs(Config.Ores) do
	local group = deposits:WaitForChild(oreType)
	for index = 0, 2 do
		local base = group:WaitForChild("Base" .. index)
		local sample = group:WaitForChild("Sample" .. index)
		local deposit = { Base = base, Definition = definition, OreType = oreType }
		byPart[base] = deposit
		byPart[sample] = deposit
		base:SetAttribute("Mineable", true)
		sample:SetAttribute("Mineable", true)
		for _, piece in ipairs({ base, sample }) do
			piece:SetAttribute("OreType", oreType)
			piece:SetAttribute("DepositIndex", index)
		end
	end
end

local states = {}
local lastRequests = {}

remote.OnServerEvent:Connect(function(player, action, target)
	local now = os.clock()
	if now - (lastRequests[player] or -math.huge) < Config.HitInterval then
		return
	end
	lastRequests[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if action == "Practice" and target == nil then
		Inventory.Train(player)
		return
	end
	if (action ~= "Hit" and action ~= "HitOnly") or typeof(target) ~= "Instance" then
		return
	end
	local deposit = byPart[target]
	if not deposit or not target:IsDescendantOf(deposits) then
		return
	end
	if (root.Position - target.Position).Magnitude > Config.Reach then
		remote:FireClient(player, { Message = "Aproxime-se do depósito (até 18 studs)." })
		return
	end
	local origin = character:FindFirstChild("Head") or root
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(origin.Position, target.Position - origin.Position, params)
	if not hit or byPart[hit.Instance] ~= deposit then
		remote:FireClient(player, { Message = "O depósito está bloqueado por um obstáculo." })
		return
	end

	if not Inventory.CanFit(player, deposit.OreType) then
		remote:FireClient(player, { Message = "Sem espaço para este minério. Venda no balcão da loja à esquerda." })
		return
	end
	local playerStates = states[player]
	if not playerStates then
		playerStates = {}
		states[player] = playerStates
	end
	local state = playerStates[deposit.Base]
	if not state then
		state = { Remaining = deposit.Definition.Resistance }
		playerStates[deposit.Base] = state
	end
	local power = Inventory.GetPower(player)
	local nextRemaining = math.max(0, math.round((state.Remaining - power) * 100) / 100)
	local damage = math.round((state.Remaining - nextRemaining) * 100) / 100
	if nextRemaining == 0 and not Inventory.Add(player, deposit.OreType) then
		return
	end
	state.Remaining = nextRemaining
	if state.Remaining == 0 then
		-- O próximo golpe já começa uma nova extração, sem espera após quebrar.
		playerStates[deposit.Base] = nil
	end
	if action == "Hit" then
		Inventory.Train(player)
	end
	remote:FireClient(player, {
		Target = deposit.Base,
		Damage = damage,
		Name = deposit.Definition.Name,
		Remaining = state.Remaining,
		Maximum = deposit.Definition.Resistance,
		Message = state.Remaining == 0
			and "Extração concluída! +1 minério. Pode continuar minerando."
			or "Golpe aceito • poder " .. power,
	})
end)

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
	lastRequests[player] = nil
end)
