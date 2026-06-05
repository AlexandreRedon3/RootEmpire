-- NetworkService.luau
-- Branche les RemoteEvents aux services serveur

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.utils.RemoteService)
local Config = require(ReplicatedStorage.constants.Config)

local ServerScriptService = game:GetService("ServerScriptService")
local services = ServerScriptService:WaitForChild("services")

local PlayerService = require(services:WaitForChild("PlayerService"))
local ProductionService = require(services:WaitForChild("ProductionService"))

local NetworkService = {}

-- ============================================================
-- HELPERS
-- ============================================================

local function respond(player: Player, eventName: string, success: boolean, message: string?, data: any?)
    -- Ne pas utiliser PlayerDataUpdate pour les réponses — ça écrase les données
    -- Pour l'instant on log juste côté serveur
    if not success then
        warn("[NetworkService]", eventName, "échoué pour", player.Name, ":", message)
    end
end

-- ============================================================
-- HANDLERS
-- ============================================================

local function handleBuyMachine(player: Player, machineId: any)
    local success, err = ProductionService.buyMachine(player, machineId)
    respond(player, "BuyMachine", success, err)

    if success then
        -- Envoyer les données joueur mises à jour
        local data = PlayerService.getData(player)
        if data then
            RemoteService.fireClient("PlayerDataUpdate", player, data)
        end
    end
end

local function handleStartMachine(player: Player, machineId: any)
    local success, err = ProductionService.startMachine(player, machineId)
    respond(player, "StartMachine", success, err)
end

local function handleStopMachine(player: Player, machineId: any)
    local success, err = ProductionService.stopMachine(player, machineId)
    respond(player, "StopMachine", success, err)
end

local function handleCollectOutput(player: Player, machineId: any)
    local success, err, amount = ProductionService.collectOutput(player, machineId)
    respond(player, "CollectOutput", success, err, { amount = amount })

    if success then
        local data = PlayerService.getData(player)
        if data then
            -- Envoyer les données complètes — coins ET ressources mis à jour
            RemoteService.fireClient("PlayerDataUpdate", player, data)
        end
    end
end

local function handleAddInputStock(player: Player, machineId: any, amount: number)
    local success, err = ProductionService.addInputStock(player, machineId, amount)
    respond(player, "AddInputStock", success, err)

    if success then
        local data = PlayerService.getData(player)
        if data then
            RemoteService.fireClient("PlayerDataUpdate", player, data)
        end
    end
end

local function handleUnlockZone(player: Player, zoneId: any)
    local success, err = PlayerService.unlockZone(player, zoneId)
    respond(player, "UnlockZone", success, err)

    if success then
        local data = PlayerService.getData(player)
        if data then
            RemoteService.fireClient("PlayerDataUpdate", player, data)
        end
    end
end

local function handleRebirth(player: Player)
    local success, err = PlayerService.rebirth(player)
    respond(player, "Rebirth", success, err)

    if success then
        local data = PlayerService.getData(player)
        if data then
            RemoteService.fireClient("PlayerDataUpdate", player, data)
        end
    end
end

-- ============================================================
-- REMOTE FUNCTIONS
-- ============================================================

local function handleGetPlayerData(player: Player)
    return PlayerService.getData(player)
end

local function handleGetConfig(_player: Player)
    return {
        zones = Config.ZONES,
        machines = Config.MACHINES,
        resourceValues = Config.RESOURCE_VALUES,
        rebirth = Config.REBIRTH,
    }
end

-- ============================================================
-- PRODUCTION CALLBACKS → CLIENT
-- ============================================================

local function setupProductionCallbacks()
    -- Notifier le client à chaque update de machine
    ProductionService.onProductionUpdate(function(player, machineId, machineState)
        RemoteService.fireClient("MachineUpdate", player, machineId, machineState)
    end)

    -- Notifier le client à chaque gain de coins
    ProductionService.onCoinsUpdate(function(player, coinsEarned)
        local data = PlayerService.getData(player)
        if data then
            RemoteService.fireClient("CoinsUpdate", player, data.coins, coinsEarned)
        end
    end)
end

-- ============================================================
-- INIT
-- ============================================================

function NetworkService.init()
    -- Brancher les events client → serveur
    RemoteService.onServerEvent("BuyMachine", handleBuyMachine)
    RemoteService.onServerEvent("StartMachine", handleStartMachine)
    RemoteService.onServerEvent("StopMachine", handleStopMachine)
    RemoteService.onServerEvent("CollectOutput", handleCollectOutput)
    RemoteService.onServerEvent("AddInputStock", handleAddInputStock)
    RemoteService.onServerEvent("UnlockZone", handleUnlockZone)
    RemoteService.onServerEvent("Rebirth", handleRebirth)

    -- Brancher les fonctions
    RemoteService.onServerInvoke("GetPlayerData", handleGetPlayerData)
    RemoteService.onServerInvoke("GetConfig", handleGetConfig)

    -- Brancher les callbacks de production
    setupProductionCallbacks()

    -- Envoyer les données au joueur quand il rejoint
    PlayerService.onPlayerJoined(function(player, data)
        task.wait(1) -- Laisser le client charger
        RemoteService.fireClient("PlayerDataUpdate", player, data)
    end)

    print("[NetworkService] Initialisé")
end

return NetworkService