-- Estilo de arte compartilhado: família de cada ferramenta, estilo de cada
-- minério e ícone de cada pet. Usado pelos ícones (HUD/loja) e pelos modelos 3D.
-- Só apresentação.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningConfig"))

local ArtStyle = {}

-- Ferramentas, em ordem de preço, para saber o "nível" visual de cada uma.
local toolOrder = {}
for id, upgrade in pairs(Config.Upgrades) do
	table.insert(toolOrder, { id = id, upgrade = upgrade })
end
table.sort(toolOrder, function(a, b) return a.upgrade.Price < b.upgrade.Price end)
local toolTier = { Basic = 0 }
for index, entry in ipairs(toolOrder) do
	toolTier[entry.id] = index
end
ArtStyle.ToolCount = #toolOrder

-- Família pelo nome: picareta, broca, martelo, lâmina ou emissor (sci-fi).
function ArtStyle.toolFamily(name: string): string
	if name:find("Pico") or name:find("Básico") then return "pickaxe" end
	if name:find("Broca") or name:find("Perfurador") then return "drill" end
	if name:find("Martelo") then return "hammer" end
	if name:find("Lâmina") or name:find("Cortador") or name:find("Lança") then return "blade" end
	return "laser"
end

-- Dados visuais da ferramenta pelo id (ou "Basic").
function ArtStyle.tool(id: string?)
	local upgrade = id and Config.Upgrades[id]
	if not upgrade then
		return { Id = "Basic", Name = "Extrator Básico", Family = "pickaxe", Tier = 0,
			Color = Color3.fromHex("#9AA3B5") }
	end
	return {
		Id = id,
		Name = upgrade.Name,
		Family = ArtStyle.toolFamily(upgrade.Name),
		Tier = toolTier[id] or 1,
		Color = Color3.fromHex(upgrade.Color or "#22E1FF"),
	}
end

-- Ícone vetorial por família de ferramenta.
ArtStyle.ToolIcon = table.freeze({
	pickaxe = "pickaxe", drill = "drill", hammer = "hammer", blade = "blade", laser = "laser",
})

-- Estilo de cada minério: kit de formas 3D e ícone.
ArtStyle.Ore = table.freeze({
	Iron = { Kit = "nugget", Icon = "nugget", Material = Enum.Material.Metal },
	Copper = { Kit = "nugget", Icon = "nugget", Material = Enum.Material.Metal, Patina = Color3.fromHex("#3DD6B0") },
	Silver = { Kit = "shard", Icon = "gem", Material = Enum.Material.Metal },
	Gold = { Kit = "nugget", Icon = "nugget", Material = Enum.Material.Metal, Sparkle = true },
	Crystal = { Kit = "crystal", Icon = "gem", Material = Enum.Material.Glass },
	Emerald = { Kit = "crystal", Icon = "gem", Material = Enum.Material.Glass },
	Ruby = { Kit = "crystal", Icon = "gem", Material = Enum.Material.Glass, Sparkle = true },
	Obsidian = { Kit = "spike", Icon = "shard", Material = Enum.Material.Basalt },
	Diamond = { Kit = "diamond", Icon = "diamond", Material = Enum.Material.Glass, Sparkle = true },
})

function ArtStyle.oreIcon(oreType: string): string
	local style = ArtStyle.Ore[oreType]
	return style and style.Icon or "gem"
end

-- Ícone de cada pet pelo formato (Look).
ArtStyle.PetIcon = table.freeze({
	blob = "pet", rock = "petRock", cloud = "petCloud", bolt = "petBolt", ice = "petIce", sun = "petSun",
})

function ArtStyle.petIcon(look: string?): string
	return look and ArtStyle.PetIcon[look] or "pet"
end

-- Ícone de cada tipo de missão de ORBI.
local missionIcons = { Mine = "pickaxe", Sell = "coin", Buy = "shop", Pet = "pet", Transmitter = "robot" }
function ArtStyle.missionIcon(kind: string?): string
	return kind and missionIcons[kind] or "mission"
end

return ArtStyle
