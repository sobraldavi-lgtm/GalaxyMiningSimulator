-- Valores do GDD; alcance provisório. Depósitos renovam imediatamente.
return table.freeze({
	Power = 5,
	LuminiBonus = 0.10,
	HitInterval = 0.2,
	TrainingClicksPerPoint = 10,
	-- O limite de poder de treino vem da Mochila de Poeira Cósmica equipada (PowerCap).
	Reach = 18,
	BackpackCapacity = 20,
	StartingBackpack = "Dust01",
	-- 20 Mochilas de Poeira Cósmica da Terra Nova, em ordem de progressão.
	Backpacks = table.freeze({
		table.freeze({ Id = "Dust01", Name = "Poeira Cinzenta", Capacity = 20, PowerCap = 3, Price = 0, Color = "#9AA3B5" }),
		table.freeze({ Id = "Dust02", Name = "Poeira Lunar", Capacity = 50, PowerCap = 5, Price = 150, Color = "#B9C7E0" }),
		table.freeze({ Id = "Dust03", Name = "Poeira Ferrosa", Capacity = 80, PowerCap = 8, Price = 400, Color = "#C9D4E8" }),
		table.freeze({ Id = "Dust04", Name = "Poeira Cúprica", Capacity = 120, PowerCap = 11, Price = 900, Color = "#FF9A52" }),
		table.freeze({ Id = "Dust05", Name = "Poeira Azulada", Capacity = 170, PowerCap = 15, Price = 1800, Color = "#3FA9FF" }),
		table.freeze({ Id = "Dust06", Name = "Poeira de Cometa", Capacity = 230, PowerCap = 19, Price = 3200, Color = "#5CE1E6" }),
		table.freeze({ Id = "Dust07", Name = "Poeira Estelar", Capacity = 300, PowerCap = 24, Price = 5500, Color = "#7C5CFF" }),
		table.freeze({ Id = "Dust08", Name = "Poeira Solar", Capacity = 380, PowerCap = 30, Price = 9000, Color = "#FFCA3A" }),
		table.freeze({ Id = "Dust09", Name = "Poeira Nebulosa", Capacity = 470, PowerCap = 36, Price = 14000, Color = "#FF6FB5" }),
		table.freeze({ Id = "Dust10", Name = "Poeira Aurora", Capacity = 580, PowerCap = 43, Price = 21000, Color = "#36D985" }),
		table.freeze({ Id = "Dust11", Name = "Poeira Quasar", Capacity = 700, PowerCap = 51, Price = 31000, Color = "#B05CFF" }),
		table.freeze({ Id = "Dust12", Name = "Poeira Pulsar", Capacity = 840, PowerCap = 60, Price = 45000, Color = "#00D8FF" }),
		table.freeze({ Id = "Dust13", Name = "Poeira Galáctica", Capacity = 1000, PowerCap = 70, Price = 65000, Color = "#5C7CFF" }),
		table.freeze({ Id = "Dust14", Name = "Poeira Vórtice", Capacity = 1200, PowerCap = 81, Price = 95000, Color = "#9B30FF" }),
		table.freeze({ Id = "Dust15", Name = "Poeira Cósmica", Capacity = 1450, PowerCap = 93, Price = 140000, Color = "#FF3D81" }),
		table.freeze({ Id = "Dust16", Name = "Poeira Antimatéria", Capacity = 1750, PowerCap = 106, Price = 200000, Color = "#FF5252" }),
		table.freeze({ Id = "Dust17", Name = "Poeira Supernova", Capacity = 2100, PowerCap = 120, Price = 290000, Color = "#FF8A1F" }),
		table.freeze({ Id = "Dust18", Name = "Poeira Buraco Negro", Capacity = 2500, PowerCap = 135, Price = 420000, Color = "#4A4A6A" }),
		table.freeze({ Id = "Dust19", Name = "Poeira Eterna", Capacity = 3000, PowerCap = 151, Price = 600000, Color = "#FFE066" }),
		table.freeze({ Id = "Dust20", Name = "Poeira de Asterion", Capacity = 3600, PowerCap = 168, Price = 850000, Color = "#FFFFFF" }),
	}),
	Upgrades = table.freeze({
		TitaniumDrill = table.freeze({ Name = "Broca de Titânio", Kind = "Tool", Power = 12, Price = 250 }),
	}),
	Ores = table.freeze({
		Iron = table.freeze({ Name = "Ferro espacial", Resistance = 10, Weight = 1, Value = 5 }),
		Copper = table.freeze({ Name = "Cobre lunar", Resistance = 25, Weight = 2, Value = 12 }),
		Crystal = table.freeze({ Name = "Cristal azul", Resistance = 60, Weight = 3, Value = 30 }),
	}),
})
