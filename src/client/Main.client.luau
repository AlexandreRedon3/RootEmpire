-- init.client.luau
-- Point d'entrée client

local controllers = script.Parent:WaitForChild("controllers")
local DataController = require(controllers:WaitForChild("DataController"))

-- Init dans l'ordre
DataController.init()

print("[RootEmpire] Client initialisé ✅")