-- Valores do GDD; alcance provisório. Depósitos renovam imediatamente.
return table.freeze({
	Power = 5,
	LuminiBonus = 0.10,
	HitInterval = 0.2,
	TrainingClicksPerPoint = 10,
	TrainingPowerCap = 3,
	Reach = 18,
	BackpackCapacity = 20,
	Upgrades = table.freeze({
		TitaniumDrill = table.freeze({ Name = "Broca de Titânio", Kind = "Tool", Power = 12, Price = 250 }),
		ReinforcedBackpack = table.freeze({ Name = "Mochila Reforçada", Kind = "Backpack", Capacity = 50, Price = 150 }),
	}),
	Ores = table.freeze({
		Iron = table.freeze({ Name = "Ferro espacial", Resistance = 10, Weight = 1, Value = 5 }),
		Copper = table.freeze({ Name = "Cobre lunar", Resistance = 25, Weight = 2, Value = 12 }),
		Crystal = table.freeze({ Name = "Cristal azul", Resistance = 60, Weight = 3, Value = 30 }),
	}),
})
