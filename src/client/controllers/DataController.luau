-- DataController.luau
-- Reçoit et stocke les données joueur côté client

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage.utils.RemoteService)
local Types = require(ReplicatedStorage.types.Types)

local DataController = {}

-- ============================================================
-- STATE
-- ============================================================

local playerData: Types.PlayerData? = nil
local config: any = nil

local onDataUpdateCallbacks: { (Types.PlayerData) -> () } = {}
local onCoinsUpdateCallbacks: { (number, number?) -> () } = {}
local onMachineUpdateCallbacks: { (Types.MachineId, Types.MachineState) -> () } = {}

-- ============================================================
-- PUBLIC
-- ============================================================

function DataController.getData(): Types.PlayerData?
    return playerData
end

function DataController.getConfig(): any
    return config
end

function DataController.onDataUpdate(callback: (Types.PlayerData) -> ())
    table.insert(onDataUpdateCallbacks, callback)
    -- Si on a déjà les données, appeler immédiatement
    if playerData then
        callback(playerData)
    end
end

function DataController.onCoinsUpdate(callback: (number, number?) -> ())
    table.insert(onCoinsUpdateCallbacks, callback)
end

function DataController.onMachineUpdate(callback: (Types.MachineId, Types.MachineState) -> ())
    table.insert(onMachineUpdateCallbacks, callback)
end

-- ============================================================
-- INIT
-- ============================================================

function DataController.init()
    RemoteService.init()

    -- Recevoir les données joueur
    RemoteService.onClientEvent("PlayerDataUpdate", function(data: Types.PlayerData)
        playerData = data
        for _, callback in ipairs(onDataUpdateCallbacks) do
            task.spawn(callback, data)
        end
    end)

    -- Recevoir les mises à jour de coins
    RemoteService.onClientEvent("CoinsUpdate", function(totalCoins: number, earned: number?)
        if playerData then
            playerData.coins = totalCoins
        end
        for _, callback in ipairs(onCoinsUpdateCallbacks) do
            task.spawn(callback, totalCoins, earned)
        end
    end)

    -- Recevoir les mises à jour de machines
    RemoteService.onClientEvent("MachineUpdate", function(machineId: Types.MachineId, machineState: Types.MachineState)
        if playerData and playerData.ownedMachines then
            playerData.ownedMachines[machineId] = machineState
        end
        for _, callback in ipairs(onMachineUpdateCallbacks) do
            task.spawn(callback, machineId, machineState)
        end
    end)

    -- Charger la config depuis le serveur
    config = RemoteService.invokeServer("GetConfig")

    print("[DataController] Initialisé")
end

return DataController