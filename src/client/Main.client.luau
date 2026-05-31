-- init.client.luau

local controllers = script.Parent:WaitForChild("controllers")
local DataController = require(controllers:WaitForChild("DataController"))
local HUD = require(script.Parent.ui.HUD)

-- HUD d'abord : visible même si le réseau échoue
HUD.init()
DataController.init()

print("[RootEmpire] Client initialisé ✅")