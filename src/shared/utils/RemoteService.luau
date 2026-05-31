-- RemoteService.luau
-- Centralise tous les RemoteEvents et RemoteFunctions

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = {}

-- ============================================================
-- DÉFINITION DES EVENTS
-- ============================================================

type RemoteEventName =
    -- Production
    "MachineUpdate" |       -- Serveur → Client : état d'une machine
    "CoinsUpdate" |         -- Serveur → Client : mise à jour des coins
    "PlayerDataUpdate" |    -- Serveur → Client : données joueur complètes

    -- Actions client → serveur
    "BuyMachine" |          -- Client → Serveur
    "StartMachine" |        -- Client → Serveur
    "StopMachine" |         -- Client → Serveur
    "CollectOutput" |       -- Client → Serveur
    "AddInputStock" |       -- Client → Serveur
    "UnlockZone" |          -- Client → Serveur
    "Rebirth"               -- Client → Serveur

type RemoteFunctionName =
    "GetPlayerData" |       -- Client demande ses données
    "GetConfig"             -- Client demande la config

-- ============================================================
-- SETUP
-- ============================================================

local REMOTES_FOLDER_NAME = "Remotes"
local FUNCTIONS_FOLDER_NAME = "Functions"

local remotesFolder: Folder
local functionsFolder: Folder

local function getOrCreateFolder(parent: Instance, name: string): Folder
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder :: Folder
end

local function getOrCreateRemoteEvent(name: string): RemoteEvent
    local remote = remotesFolder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    return remote :: RemoteEvent
end

local function getOrCreateRemoteFunction(name: string): RemoteFunction
    local fn = functionsFolder:FindFirstChild(name)
    if not fn then
        fn = Instance.new("RemoteFunction")
        fn.Name = name
        fn.Parent = functionsFolder
    end
    return fn :: RemoteFunction
end

-- ============================================================
-- PUBLIC
-- ============================================================

function RemoteService.init()
    -- Uniquement le serveur crée les remotes
    if RunService:IsServer() then
        remotesFolder = getOrCreateFolder(ReplicatedStorage, REMOTES_FOLDER_NAME)
        functionsFolder = getOrCreateFolder(ReplicatedStorage, FUNCTIONS_FOLDER_NAME)

        -- Créer tous les RemoteEvents
        local events: { RemoteEventName } = {
            "MachineUpdate",
            "CoinsUpdate",
            "PlayerDataUpdate",
            "BuyMachine",
            "StartMachine",
            "StopMachine",
            "CollectOutput",
            "AddInputStock",
            "UnlockZone",
            "Rebirth",
        }

        for _, name in ipairs(events) do
            getOrCreateRemoteEvent(name)
        end

        -- Créer tous les RemoteFunctions
        local functions: { RemoteFunctionName } = {
            "GetPlayerData",
            "GetConfig",
        }

        for _, name in ipairs(functions) do
            getOrCreateRemoteFunction(name)
        end

        print("[RemoteService] Initialisé côté serveur")
    else
        -- Client : attendre que les dossiers existent
        remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
        functionsFolder = ReplicatedStorage:WaitForChild(FUNCTIONS_FOLDER_NAME)
        print("[RemoteService] Initialisé côté client")
    end
end

-- Récupérer un RemoteEvent
function RemoteService.getEvent(name: RemoteEventName): RemoteEvent
    return remotesFolder:WaitForChild(name) :: RemoteEvent
end

-- Récupérer une RemoteFunction
function RemoteService.getFunction(name: RemoteFunctionName): RemoteFunction
    return functionsFolder:WaitForChild(name) :: RemoteFunction
end

-- Helpers côté serveur
function RemoteService.fireClient(name: RemoteEventName, player: Player, ...: any)
    RemoteService.getEvent(name):FireClient(player, ...)
end

function RemoteService.fireAllClients(name: RemoteEventName, ...: any)
    RemoteService.getEvent(name):FireAllClients(...)
end

function RemoteService.onServerEvent(name: RemoteEventName, callback: (Player, ...any) -> ())
    RemoteService.getEvent(name).OnServerEvent:Connect(callback)
end

function RemoteService.onServerInvoke(name: RemoteFunctionName, callback: (Player, ...any) -> ...any)
    RemoteService.getFunction(name).OnServerInvoke = callback
end

-- Helpers côté client
function RemoteService.fireServer(name: RemoteEventName, ...: any)
    RemoteService.getEvent(name):FireServer(...)
end

function RemoteService.onClientEvent(name: RemoteEventName, callback: (...any) -> ())
    RemoteService.getEvent(name).OnClientEvent:Connect(callback)
end

function RemoteService.invokeServer(name: RemoteFunctionName, ...: any): ...any
    return RemoteService.getFunction(name):InvokeServer(...)
end

return RemoteService