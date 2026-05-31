-- Main.server.luau
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local services = ServerScriptService:WaitForChild("services")

local RemoteService = require(ReplicatedStorage.utils.RemoteService)

local PlayerService = require(services:WaitForChild("PlayerService"))
local ZoneService = require(services:WaitForChild("ZoneService"))
local ProductionService = require(services:WaitForChild("ProductionService"))
local NetworkService = require(services:WaitForChild("NetworkService"))


-- RemoteService en tout premier
RemoteService.init()

-- 1. PlayerService
PlayerService.init()

-- 2. ProductionService
ProductionService.init()

-- 3. ZoneService
ZoneService.init()

-- 4. NetworkService en dernier — dépend de tout le reste
NetworkService.init()

print("[RootEmpire] Serveur initialisé ✅")