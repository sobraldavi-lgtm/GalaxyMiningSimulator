-- Testes de progressão: XP, níveis, missões, renascimento e salvamento.
-- Executar na raiz do projeto: luau tests/progression.spec.luau
local InventoryModel = require("../src/server/InventoryModel")
local Config = require("../src/shared/MiningConfig")
local function equal(actual, expected, message)
	assert(actual == expected, message .. ": esperado " .. tostring(expected) .. ", recebido " .. tostring(actual))
end

-- Níveis do GDD: 0 / 100 / 250 / 450 / 700, depois +300 por nível.
local leveler = InventoryModel.new(Config)
equal(leveler:GetLevel(), 1, "Começa no nível 1")
equal(leveler:AddXp(99), nil, "99 XP não sobe de nível")
equal(leveler:AddXp(1), 2, "100 XP: nível 2")
leveler.xp = 249
equal(leveler:GetLevel(), 2, "249 XP ainda nível 2")
leveler.xp = 700
equal(leveler:GetLevel(), 5, "700 XP: nível 5")
leveler.xp = 999
equal(leveler:GetLevel(), 5, "999 XP: nível 5")
leveler.xp = 1000
local level, floorXp, nextXp = leveler:GetLevel()
equal(level, 6, "1000 XP: nível 6 (hipótese +300)")
equal(floorXp, 1000, "Início do nível 6")
equal(nextXp, 1300, "Próximo nível em 1300")
print("PASS: tabela de níveis.")

-- Missão 1: minerar 5 ferros (XP 1 por minério).
local player = InventoryModel.new(Config)
for index = 1, 4 do
	local ok, _, done = player:Mine("Iron")
	equal(ok, true, "Ferro " .. index .. " coletado")
	equal(#done, 0, "Missão ainda em andamento")
end
equal(player:Mine("Copper"), true, "Cobre não conta para a missão de ferro")
equal(player.missionProgress, 4, "Progresso só com ferro")
local _, _, done = player:Mine("Iron")
equal(#done, 1, "Quinto ferro conclui a missão")
equal(done[1].Id, "FirstContact", "Missão Primeiro contato")
equal(player.credits, 50, "Recompensa de 50 Créditos")
equal(player.fragments, 1, "Recompensa de 1 Fragmento")
equal(player.xp, 6, "6 minérios = 6 XP")
print("PASS: missão de mineração, XP e recompensa.")

-- Missão 2: vender (10 XP por venda).
local earned, _, sold = player:SellAll()
equal(earned, 37, "5 ferros e 1 cobre = 37")
equal(#sold, 1, "Venda conclui Primeira venda")
equal(player.credits, 50 + 37 + 75, "Venda + recompensa da missão 2")
equal(player.xp, 16, "Venda dá 10 XP")
equal(select(1, player:SellAll()), 0, "Venda vazia não dá XP nem progresso")
equal(player.xp, 16, "XP sem venda vazia")

-- Missão 3: qualquer compra. Missão 4: equipar Lumini (estado já alcançado conclui na hora).
equal(player:BuyBackpack("Dust02"), true, "Compra mochila")
local bought = player:Progress("Buy")
equal(#bought, 1, "Compra conclui Tecnologia aprimorada")
player.credits = 200
equal(player:BuyPet("Lumini"), true, "Resgata Lumini")
local pet = player:Progress("Pet", "Lumini")
equal(#pet, 1, "Lumini equipada conclui Amigo alienígena")
equal(player:CurrentMission().Id, "UnknownSignal", "Missão 5 ativa")

-- Missão 5 exige nível 3 (acesso à caverna azul).
equal(player:CanUseTransmitter(), false, "Transmissor bloqueado abaixo do nível 3")
player.xp = 250
equal(player:CanUseTransmitter(), true, "Transmissor liberado no nível 3")
equal(#player:Progress("Transmitter"), 1, "Transmissor conclui a campanha")
equal(player:CurrentMission(), nil, "Campanha concluída")
equal(player.fragments, 5, "5 Fragmentos ao todo")
equal(#player:Progress("Mine", "Iron"), 0, "Sem missões depois da campanha")
print("PASS: cinco missões em sequência, estado já alcançado e nível da caverna.")

-- Missões encadeadas: se a compra já aconteceu, a missão 3 conclui ao chegar nela.
local eager = InventoryModel.new(Config)
eager.credits = 1000
eager:Purchase("TitaniumDrill")
eager.missionIndex = 3
equal(#eager:Progress(nil), 1, "Compra anterior conclui a missão 3 na hora")

-- Renascimento: custo 50.000 × (n + 1), +25% na venda; mantém pets, XP e missões.
local reborn = InventoryModel.new(Config)
reborn.credits = 49999
equal(reborn:Rebirth(), false, "Sem Créditos suficientes")
reborn.credits = 60000
reborn.ownedPets.Lumini = true
reborn.equippedPet = "Lumini"
reborn.xp = 500
reborn:Purchase("TitaniumDrill")
reborn:BuyBackpack("Dust02")
reborn:Add("Iron")
equal(reborn:Rebirth(), true, "Renasce com 50.000")
local snap = reborn:Snapshot()
equal(snap.Credits, 0, "Créditos zerados")
equal(snap.Weight, 0, "Carga zerada")
equal(snap.ToolPower, Config.Power, "Ferramenta básica")
equal(snap.BackpackId, Config.StartingBackpack, "Mochila inicial")
equal(snap.OwnedUpgrades.TitaniumDrill, nil, "Ferramentas compradas reiniciadas")
equal(snap.EquippedPet, "Lumini", "Pet mantido")
equal(snap.Xp, 500, "XP mantida")
equal(snap.Rebirths, 1, "1 renascimento")
equal(snap.RebirthCost, 100000, "Próximo custa 100.000")
reborn:Add("Crystal")
equal(reborn:Sell(), 37, "Cristal 30 × 1,25 = 37 (arredonda para baixo)")
equal(reborn.lifetimeCredits, 37, "Créditos ganhos acumulados")
print("PASS: renascimento, custo crescente e bônus de venda.")

-- Salvamento: ida e volta preserva tudo, menos o treino (por sessão).
local saved = InventoryModel.new(Config)
saved.credits = 5000
saved:BuyBackpack("Dust02")
saved:Purchase("Tool03")
saved:BuyPet("Lumini")
saved:Mine("Iron")
saved:TrainMining()
saved.rebirths = 2
local data = saved:Serialize()
equal(data.Version, InventoryModel.SaveVersion, "Versão do formato")
local loaded = InventoryModel.fromData(Config, data)
local a, b = saved:Snapshot(), loaded:Snapshot()
for _, key in ipairs({ "Credits", "Weight", "Capacity", "BackpackId", "ToolId", "ToolPower", "EquippedPet",
	"Xp", "Fragments", "MissionIndex", "Rebirths", "LifetimeCredits" }) do
	equal(b[key], a[key], "Salvo e carregado: " .. key)
end
equal(b.Items.Iron, 1, "Itens preservados")
equal(b.TrainingClicks, 0, "Treino não é salvo")

-- Dados corrompidos ou de catálogo antigo são descartados com segurança.
local broken = InventoryModel.fromData(Config, {
	Items = { Iron = 3, Unknown = 9, Copper = -4 },
	Credits = -50,
	BackpackId = "Dust20",
	OwnedBackpacks = { Dust20 = "sim" },
	ToolId = "Tool19",
	OwnedUpgrades = {},
	OwnedPets = { Ghost = true },
	EquippedPet = "Ghost",
	Xp = 0 / 0,
	MissionIndex = 99,
})
local fixed = broken:Snapshot()
equal(fixed.Weight, 3, "Só ferro válido")
equal(fixed.Credits, 0, "Créditos negativos viram 0")
equal(fixed.BackpackId, Config.StartingBackpack, "Mochila não possuída não equipa")
equal(fixed.ToolPower, Config.Power, "Ferramenta não possuída não equipa")
equal(fixed.EquippedPet, nil, "Pet inexistente descartado")
equal(fixed.Xp, 0, "XP NaN vira 0")
equal(fixed.MissionIndex, #Config.Missions + 1, "Índice de missão limitado")
equal(InventoryModel.fromData(Config, nil):Snapshot().Credits, 0, "Sem dados: jogador novo")
print("PASS: salvamento, ida e volta, e dados inválidos.")
