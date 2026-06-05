-- SlotService.luau
-- Gestion des 6 slots joueur sur la map en étoile
-- Un slot = un bras de l'étoile, lié temporairement à un joueur (session uniquement)
-- Les données sont sauvegardées par UserId, pas par slot

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.utils.RemoteService)

local SlotService = {}

-- ============================================================
-- CONFIGURATION
-- ============================================================

local MAX_SLOTS = 6

-- Positions des spawns de chaque slot (à ajuster selon ta map)
-- Angles en étoile : 0°, 60°, 120°, 180°, 240°, 300°
local SLOT_SPAWN_POSITIONS = {
	[1] = Vector3.new(0,   0, -80),   -- Haut
	[2] = Vector3.new(70,  0, -40),   -- Haut droite
	[3] = Vector3.new(70,  0,  40),   -- Bas droite
	[4] = Vector3.new(0,   0,  80),   -- Bas
	[5] = Vector3.new(-70, 0,  40),   -- Bas gauche
	[6] = Vector3.new(-70, 0, -40),   -- Haut gauche
}

-- ============================================================
-- STATE
-- ============================================================

-- slot → userId (nil si libre)
local slots: { [number]: number? } = {}

-- userId → slotNumber (lookup inverse)
local playerSlots: { [number]: number } = {}

-- Callbacks
local onSlotAssignedCallbacks:  { (Player, number) -> () } = {}
local onSlotReleasedCallbacks:  { (Player, number) -> () } = {}

-- ============================================================
-- PRIVATE
-- ============================================================

local function initSlots()
	for i = 1, MAX_SLOTS do
		slots[i] = nil
	end
end

local function getFirstFreeSlot(): number?
	for i = 1, MAX_SLOTS do
		if slots[i] == nil then
			return i
		end
	end
	return nil
end

local function assignSlot(player: Player, slotNumber: number)
	slots[slotNumber]           = player.UserId
	playerSlots[player.UserId]  = slotNumber

	print("[SlotService]", player.Name, "→ Slot", slotNumber)

	-- Notifier le client
	RemoteService.fireClient("SlotAssigned", player, {
		slotNumber   = slotNumber,
		spawnPosition = SLOT_SPAWN_POSITIONS[slotNumber],
	})

	-- Notifier les callbacks
	for _, cb in ipairs(onSlotAssignedCallbacks) do
		task.spawn(cb, player, slotNumber)
	end
end

local function releaseSlot(player: Player)
	local slotNumber = playerSlots[player.UserId]
	if not slotNumber then return end

	slots[slotNumber]          = nil
	playerSlots[player.UserId] = nil

	print("[SlotService]", player.Name, "a libéré le Slot", slotNumber)

	-- Notifier tous les clients (mise à jour de la map)
	RemoteService.fireAllClients("SlotReleased", {
		slotNumber = slotNumber,
	})

	-- Notifier les callbacks
	for _, cb in ipairs(onSlotReleasedCallbacks) do
		task.spawn(cb, player, slotNumber)
	end
end

local function broadcastSlotState()
	-- Envoie l'état complet des slots à tous les clients
	local state: { [number]: string? } = {}
	for i = 1, MAX_SLOTS do
		if slots[i] then
			local player = Players:GetPlayerByUserId(slots[i])
			state[i] = player and player.Name or nil
		else
			state[i] = nil
		end
	end
	RemoteService.fireAllClients("SlotsStateUpdate", state)
end

-- ============================================================
-- PUBLIC
-- ============================================================

-- Récupère le slot d'un joueur (nil si pas de slot)
function SlotService.getSlot(player: Player): number?
	return playerSlots[player.UserId]
end

-- Récupère le joueur d'un slot (nil si libre)
function SlotService.getPlayerInSlot(slotNumber: number): Player?
	local userId = slots[slotNumber]
	if not userId then return nil end
	return Players:GetPlayerByUserId(userId)
end

-- Retourne l'état de tous les slots
function SlotService.getSlotsState(): { [number]: string? }
	local state: { [number]: string? } = {}
	for i = 1, MAX_SLOTS do
		if slots[i] then
			local player = Players:GetPlayerByUserId(slots[i])
			state[i] = player and player.Name or nil
		else
			state[i] = nil
		end
	end
	return state
end

-- Retourne le nombre de slots libres
function SlotService.getFreeSlotCount(): number
	local count = 0
	for i = 1, MAX_SLOTS do
		if slots[i] == nil then count += 1 end
	end
	return count
end

-- S'abonner aux événements
function SlotService.onSlotAssigned(callback: (Player, number) -> ())
	table.insert(onSlotAssignedCallbacks, callback)
end

function SlotService.onSlotReleased(callback: (Player, number) -> ())
	table.insert(onSlotReleasedCallbacks, callback)
end

-- ============================================================
-- INIT
-- ============================================================

function SlotService.init(playerService: any)
	initSlots()

	-- Branché sur PlayerService
	playerService.onPlayerJoined(function(player: Player, _data: any)
		local slotNumber = getFirstFreeSlot()

		if not slotNumber then
			-- Serveur plein — kick propre
			player:Kick("Le serveur est complet (6/6 slots). Réessaie dans quelques instants !")
			return
		end

		assignSlot(player, slotNumber)
		broadcastSlotState()
	end)

	playerService.onPlayerLeaving(function(player: Player, _data: any)
		releaseSlot(player)
		broadcastSlotState()
	end)

	-- Demande d'état des slots depuis un client (ex: affichage map)
	RemoteService.onServerInvoke("GetSlotsState", function(_player: Player)
		return SlotService.getSlotsState()
	end)

	print("[SlotService] Initialisé —", MAX_SLOTS, "slots disponibles")
end

return SlotService
