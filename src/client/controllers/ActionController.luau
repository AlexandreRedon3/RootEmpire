-- ActionController.luau
-- Expose les actions client → serveur

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage.utils.RemoteService)
local Types = require(ReplicatedStorage.types.Types)

local ActionController = {}

function ActionController.buyMachine(machineId: Types.MachineId)
    RemoteService.fireServer("BuyMachine", machineId)
end

function ActionController.startMachine(machineId: Types.MachineId)
    RemoteService.fireServer("StartMachine", machineId)
end

function ActionController.stopMachine(machineId: Types.MachineId)
    RemoteService.fireServer("StopMachine", machineId)
end

function ActionController.collectOutput(machineId: Types.MachineId)
    RemoteService.fireServer("CollectOutput", machineId)
end

function ActionController.addInputStock(machineId: Types.MachineId, amount: number)
    RemoteService.fireServer("AddInputStock", machineId, amount)
end

function ActionController.unlockZone(zoneId: Types.ZoneId)
    RemoteService.fireServer("UnlockZone", zoneId)
end

function ActionController.rebirth()
    RemoteService.fireServer("Rebirth")
end

return ActionController