-- Main.client.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local controllers = script.Parent:WaitForChild("controllers")
local DataController = require(controllers:WaitForChild("DataController"))
local RemoteService = require(ReplicatedStorage.utils.RemoteService)
local HUD = require(script.Parent.ui.HUD)

-- HUD d'abord : visible même si le réseau échoue
HUD.init()
DataController.init()

-- Réception du slot assigné par le serveur
RemoteService.onClientEvent("SlotAssigned", function(payload)
    local slotNumber   = payload.slotNumber
    local spawnPos     = payload.spawnPosition

    print("[Client] Slot assigné :", slotNumber)

    -- Téléporter le joueur sur son slot
    local character = Players.LocalPlayer.Character
        or Players.LocalPlayer.CharacterAdded:Wait()

    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = CFrame.new(spawnPos + Vector3.new(0, 5, 0))
end)

-- Mise à jour de l'état des slots (pour affichage map future)
RemoteService.onClientEvent("SlotsStateUpdate", function(state)
    -- TODO : mettre à jour l'affichage des slots sur la map
    -- state = { [1] = "Alex", [2] = nil, [3] = "Graig", ... }
    print("[Client] Slots mis à jour :", state)
end)

print("[RootEmpire] Client initialisé ✅")