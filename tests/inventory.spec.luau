local InventoryModel = require("../src/server/InventoryModel")
local Config = require("../src/shared/MiningConfig")
local function equal(actual, expected, message)
	assert(actual == expected, message .. ": esperado " .. tostring(expected) .. ", recebido " .. tostring(actual))
end

local inventory = InventoryModel.new(Config)
equal(inventory:Sell(), 0, "Venda vazia")
equal(inventory:Add("Invalid"), false, "Minério inválido")
for _ = 1, 6 do
	equal(inventory:Add("Crystal"), true, "Cristal cabe")
end
equal(inventory:Snapshot().Weight, 18, "Peso dos cristais")
equal(inventory:Add("Crystal"), false, "Não ultrapassa capacidade")
equal(inventory:Add("Copper"), true, "Cobre completa capacidade")
equal(inventory:Snapshot().Weight, 20, "Capacidade exata")
equal(inventory:Add("Iron"), false, "Mochila cheia")
local copy = inventory:Snapshot()
copy.Items.Crystal = 999
equal(inventory:Snapshot().Items.Crystal, 6, "Snapshot não altera inventário")
equal(inventory:Sell(), 192, "6 cristais e 1 cobre")
equal(inventory:Snapshot().Credits, 192, "Créditos da venda")
equal(inventory:Snapshot().Weight, 0, "Venda esvazia mochila")
equal(inventory:Sell(), 0, "Venda repetida não duplica Créditos")
equal(inventory:Snapshot().Credits, 192, "Saldo após venda repetida")
local other = InventoryModel.new(Config)
equal(other:Snapshot().Credits, 0, "Saldo independente")
equal(other:Snapshot().Weight, 0, "Mochila independente")
equal(inventory:Add("Iron"), true, "Coleta após venda")
equal(inventory:Sell(), 5, "Venda de ferro")
equal(inventory:Snapshot().Credits, 197, "Acumula Créditos")
print("PASS: capacidade, pesos, venda, duplicação e isolamento de inventários.")

equal(inventory:Purchase("Unknown"), false, "Compra inválida")
equal(inventory:Purchase("TitaniumDrill"), false, "Broca sem saldo suficiente")
equal(inventory:Snapshot().Credits, 197, "Compra recusada preserva saldo")
equal(inventory:Snapshot().Power, 5, "Compra recusada preserva poder")
inventory:Add("Iron")
equal(#Config.Backpacks, 20, "20 mochilas de Poeira Cósmica")
equal(inventory:Snapshot().PowerCap, 3, "Mochila inicial limita poder em 3")
equal(inventory:BuyBackpack("Unknown"), false, "Mochila inválida")
equal(inventory:BuyBackpack("Dust01"), false, "Mochila inicial já possuída")
equal(inventory:BuyBackpack("Dust02"), true, "Compra da mochila")
equal(inventory:Snapshot().Credits, 47, "Desconta 150 Créditos")
equal(inventory:Snapshot().Capacity, 50, "Capacidade aumenta para 50")
equal(inventory:Snapshot().PowerCap, 5, "Limite de poder acompanha a mochila")
equal(inventory:Snapshot().Weight, 1, "Compra preserva carga")
equal(inventory:BuyBackpack("Dust02"), false, "Compra duplicada rejeitada")
equal(inventory:Snapshot().Credits, 47, "Compra duplicada não cobra novamente")
equal(inventory:BuyBackpack("Dust20"), false, "Mochila sem saldo")
equal(inventory:EquipBackpack("Dust03"), false, "Não equipa mochila não possuída")
for _ = 1, 24 do
	equal(inventory:Add("Copper"), true, "Usa capacidade ampliada")
end
equal(inventory:Snapshot().Weight, 49, "Carga na mochila ampliada")
equal(inventory:Add("Copper"), false, "Limite ampliado respeitado")
equal(inventory:Sell(), 293, "Venda de carga preservada e nova")
equal(inventory:Purchase("TitaniumDrill"), true, "Compra da broca")
equal(inventory:Snapshot().Credits, 90, "Desconta 250 Créditos")
equal(inventory:Snapshot().Power, 12, "Broca equipa poder 12")
equal(inventory:Purchase("TitaniumDrill"), false, "Broca duplicada rejeitada")
equal(inventory:Snapshot().Credits, 90, "Não cobra broca duplicada")
equal(other:Snapshot().Capacity, 20, "Mochila do outro jogador não muda")
equal(other:Snapshot().Power, 5, "Ferramenta do outro jogador não muda")
print("PASS: compras, saldo insuficiente, duplicação, equipamento e carga preservada.")

-- Limite de poder segue a mochila equipada.
local trainer = InventoryModel.new(Config)
for _ = 1, 100 do
	trainer:TrainMining()
end
equal(trainer:Snapshot().TrainingPower, 3, "Treino parado no limite da mochila inicial")
equal(trainer:Snapshot().Power, 8, "Poder = 5 + treino 3")
trainer.credits = 1000
equal(trainer:BuyBackpack("Dust02"), true, "Compra mochila 2")
for _ = 1, 100 do
	trainer:TrainMining()
end
equal(trainer:Snapshot().TrainingPower, 5, "Treino sobe até o novo limite")
trainer:Add("Iron")
for _ = 1, 40 do
	trainer:Add("Iron")
end
equal(trainer:EquipBackpack("Dust01"), false, "Não troca para mochila menor com carga acima")
trainer:Sell()
equal(trainer:EquipBackpack("Dust01"), true, "Troca para mochila inicial vazia")
equal(trainer:Snapshot().TrainingPower, 3, "Poder efetivo cai ao limite da mochila equipada")
print("PASS: 20 mochilas, compra, equipar e limite de poder por mochila.")

-- Ferramentas, minérios e pets ampliados.
equal(#Config.Backpacks, 20, "20 mochilas")
local count = 0
for id, upgrade in pairs(Config.Upgrades) do
	if upgrade.Kind == "Tool" then count += 1 end
end
equal(count, 20, "Broca de Titânio + 19 novas ferramentas")
local oreCount = 0
for _ in pairs(Config.Ores) do oreCount += 1 end
equal(oreCount, 9, "3 minérios originais + 6 novos")
equal(#Config.Pets, 6, "Lumini + 5 novos pets")
local pets = InventoryModel.new(Config)
pets.credits = 100
equal(pets:HatchEgg("NovaEgg"), false, "Ovo Supernova sem saldo")
equal(pets:HatchEgg("StarEgg"), true, "Abre Ovo Estelar por 75")
equal(pets:Snapshot().Credits, 25, "Desconta 75")
equal(pets:Snapshot().EquippedPet, "Lumini", "Primeiro ovo garante Lumini equipada")
equal(pets:Snapshot().Power, 5.5, "Bônus de +10% sobre poder 5")
pets.credits = 75
local _, _, repeated = pets:HatchEgg("StarEgg", function() return 0 end)
equal(repeated.Duplicate, true, "Lumini repetida")
equal(pets:Snapshot().Credits, 37, "Repetido devolve 50% do ovo")
equal(pets:EquipPet(nil), true, "Guarda pet")
equal(pets:Snapshot().Power, 5, "Sem pet, sem bônus")
equal(pets:EquipPet("Solari"), false, "Não equipa pet não possuído")
pets.credits = 5000
equal(pets:Purchase("Tool03"), true, "Compra ferramenta nova")
equal(pets:Purchase("TitaniumDrill"), false, "Não compra ferramenta inferior")
equal(pets:Snapshot().ToolPower, 50, "Ferramenta nova equipada")
print("PASS: 20 ferramentas, 9 minérios, 6 pets.")
