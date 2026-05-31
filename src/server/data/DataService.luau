-- DataService.luau
-- Persistance et cache des données joueur

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.types.Types)

local DataService = {}

local cache: { [number]: Types.PlayerData } = {}

local AUTO_SAVE_INTERVAL = 60

local function createDefaultData(): Types.PlayerData
	return {
		coins = 0,
		rebirths = 0,
		multiplier = 1.0,
		unlockedZones = { "forest" },
		ownedMachines = {},
		stats = {
			totalProduced = 0,
			totalEarned = 0,
			playTime = 0,
		},
	}
end

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

function DataService.removePlayer(player: Player)
	DataService.savePlayer(player)
	cache[player.UserId] = nil
end

return DataService
