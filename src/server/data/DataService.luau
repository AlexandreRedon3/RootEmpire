-- DataService.luau
-- Persistance et cache des données joueur

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.types.Types)

local DataService = {}

local cache: { [number]: Types.PlayerData } = {}

local AUTO_SAVE_INTERVAL = 60

-- ============================================================
-- DEFAULT DATA
-- ============================================================

local function createDefaultData(): Types.PlayerData
	return {
		coins = 0,
		rebirths = 0,
		multiplier = 1.0,
		resources = {
			-- Forest
			raw_wood  = 0,
			plank     = 0,
			furniture = 0,
			-- Mine
			stone     = 0,
			ore       = 0,
			ingot     = 0,
			tool      = 0,
			-- Farm
			wheat     = 0,
			flour     = 0,
			bread     = 0,
			-- Coastal
			raw_fish    = 0,
			canned_fish = 0,
			-- Volcanic
			magma_rock       = 0,
			refined_crystal  = 0,
		},
		unlockedZones = { "forest" },
		ownedMachines = {},
		stats = {
			totalProduced = 0,
			totalEarned   = 0,
			playTime      = 0,
		},
	}
end

-- ============================================================
-- PUBLIC
-- ============================================================

function DataService.loadPlayer(player: Player): Types.PlayerData
	local userId = player.UserId
	if not cache[userId] then
		-- TODO: charger depuis DataStore
		cache[userId] = createDefaultData()
	end
	return cache[userId]
end

function DataService.savePlayer(player: Player): boolean
	local data = cache[player.UserId]
	if not data then
		return false
	end
	-- TODO: sauvegarder dans DataStore
	return true
end

function DataService.startAutoSave(player: Player)
	local userId = player.UserId
	task.spawn(function()
		while player.Parent and cache[userId] do
			task.wait(AUTO_SAVE_INTERVAL)
			if cache[userId] then
				DataService.savePlayer(player)
			end
		end
	end)
end

function DataService.getData(player: Player): Types.PlayerData?
	return cache[player.UserId]
end

function DataService.updateData(player: Player, updater: (Types.PlayerData) -> ()): boolean
	local data = cache[player.UserId]
	if not data then
		return false
	end
	updater(data)
	return true
end

-- ============================================================
-- HELPERS RESSOURCES
-- ============================================================

-- Ajoute une quantité à une ressource et retourne le nouveau total
function DataService.addResource(
	player: Player,
	resourceId: Types.ResourceId,
	amount: number
): number
	local data = cache[player.UserId]
	if not data then return 0 end

	data.resources[resourceId] = (data.resources[resourceId] or 0) + amount
	return data.resources[resourceId]
end

-- Retire une quantité d'une ressource — retourne false si stock insuffisant
function DataService.removeResource(
	player: Player,
	resourceId: Types.ResourceId,
	amount: number
): boolean
	local data = cache[player.UserId]
	if not data then return false end

	local current = data.resources[resourceId] or 0
	if current < amount then return false end

	data.resources[resourceId] = current - amount
	return true
end

-- Vérifie si le joueur a assez d'une ressource
function DataService.hasResource(
	player: Player,
	resourceId: Types.ResourceId,
	amount: number
): boolean
	local data = cache[player.UserId]
	if not data then return false end
	return (data.resources[resourceId] or 0) >= amount
end

function DataService.removePlayer(player: Player)
	DataService.savePlayer(player)
	cache[player.UserId] = nil
end

return DataService
