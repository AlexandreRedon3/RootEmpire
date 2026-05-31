local Types = require(script.Parent.Parent.types.Types)

local Config = {}

-- ============================================================
-- ZONES
-- ============================================================

local ZONES: { [Types.ZoneId]: Types.Zone } = {
	forest = {
		id = "forest",
		displayName = "Forêt",
		unlockCost = 0,
		requiredRebirths = 0,
		machines = { "sawmill", "planer", "workshop" },
	},
	mine = {
		id = "mine",
		displayName = "Mine",
		unlockCost = 5000,
		requiredRebirths = 0,
		machines = { "drill", "furnace", "forge" },
	},
	farm = {
		id = "farm",
		displayName = "Ferme",
		unlockCost = 15000,
		requiredRebirths = 1,
		machines = { "mill", "oven", "silo" },
	},
	coastal = {
		id = "coastal",
		displayName = "Côtière",
		unlockCost = 40000,
		requiredRebirths = 2,
		machines = { "fishing_boat", "cannery" },
	},
	volcanic = {
		id = "volcanic",
		displayName = "Volcanique",
		unlockCost = 100000,
		requiredRebirths = 5,
		machines = { "lava_extractor", "crystal_refiner" },
	},
}

-- ============================================================
-- MACHINES
-- ============================================================

local MACHINES: { [Types.MachineId]: Types.Machine } = {
	-- Forest
	sawmill = {
		id = "sawmill",
		displayName = "Scierie",
		input = "raw_wood",
		output = "plank",
		productionTime = 3,
		outputAmount = 2,
		cost = 100,
		zone = "forest",
	},
	planer = {
		id = "planer",
		displayName = "Raboteuse",
		input = "plank",
		output = "plank",
		productionTime = 5,
		outputAmount = 1,
		cost = 500,
		zone = "forest",
	},
	workshop = {
		id = "workshop",
		displayName = "Atelier",
		input = "plank",
		output = "furniture",
		productionTime = 8,
		outputAmount = 1,
		cost = 1500,
		zone = "forest",
	},

	-- Mine
	drill = {
		id = "drill",
		displayName = "Foreuse",
		input = "stone",
		output = "ore",
		productionTime = 4,
		outputAmount = 2,
		cost = 2000,
		zone = "mine",
	},
	furnace = {
		id = "furnace",
		displayName = "Fonderie",
		input = "ore",
		output = "ingot",
		productionTime = 6,
		outputAmount = 1,
		cost = 4000,
		zone = "mine",
	},
	forge = {
		id = "forge",
		displayName = "Forge",
		input = "ingot",
		output = "tool",
		productionTime = 10,
		outputAmount = 1,
		cost = 8000,
		zone = "mine",
	},

	-- Farm
	mill = {
		id = "mill",
		displayName = "Moulin",
		input = "wheat",
		output = "flour",
		productionTime = 4,
		outputAmount = 2,
		cost = 10000,
		zone = "farm",
	},
	oven = {
		id = "oven",
		displayName = "Four",
		input = "flour",
		output = "bread",
		productionTime = 7,
		outputAmount = 1,
		cost = 20000,
		zone = "farm",
	},
	silo = {
		id = "silo",
		displayName = "Silo",
		input = "wheat",
		output = "wheat",
		productionTime = 2,
		outputAmount = 3,
		cost = 15000,
		zone = "farm",
	},

	-- Coastal
	fishing_boat = {
		id = "fishing_boat",
		displayName = "Bateau de pêche",
		input = "raw_fish",
		output = "raw_fish",
		productionTime = 5,
		outputAmount = 4,
		cost = 30000,
		zone = "coastal",
	},
	cannery = {
		id = "cannery",
		displayName = "Conserverie",
		input = "raw_fish",
		output = "canned_fish",
		productionTime = 8,
		outputAmount = 2,
		cost = 50000,
		zone = "coastal",
	},

	-- Volcanic
	lava_extractor = {
		id = "lava_extractor",
		displayName = "Extracteur de lave",
		input = "stone",
		output = "magma_rock",
		productionTime = 6,
		outputAmount = 2,
		cost = 120000,
		zone = "volcanic",
	},
	crystal_refiner = {
		id = "crystal_refiner",
		displayName = "Raffineur de cristaux",
		input = "magma_rock",
		output = "refined_crystal",
		productionTime = 12,
		outputAmount = 1,
		cost = 200000,
		zone = "volcanic",
	},
}

local RESOURCE_VALUES: { [Types.ResourceId]: number } = {
	raw_wood = 5,
	plank = 15,
	furniture = 50,
	stone = 8,
	ore = 25,
	ingot = 75,
	tool = 200,
	wheat = 10,
	flour = 30,
	bread = 90,
	raw_fish = 12,
	canned_fish = 100,
	magma_rock = 150,
	refined_crystal = 500,
}

Config.ZONES = ZONES
Config.MACHINES = MACHINES
Config.RESOURCE_VALUES = RESOURCE_VALUES

Config.REBIRTH = {
	MIN_COINS_REQUIRED = 50000,
	KEPT_PROGRESS_RATIO = 0.1,
	BASE_MULTIPLIER = 0.25,
}

return Config
