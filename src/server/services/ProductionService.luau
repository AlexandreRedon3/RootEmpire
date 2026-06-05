-- ProductionService.luau
-- Gère la boucle de production des machines

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Types = require(ReplicatedStorage.types.Types)
local Config = require(ReplicatedStorage.constants.Config)
local PlayerService = require(script.Parent.PlayerService)
local DataService = require(script.Parent.Parent.data.DataService)

-- ============================================================
-- SETUP
-- ============================================================

local ProductionService = {}

-- Timers de production par joueur/machine
-- { [userId]: { [machineId]: lastTickTime } }
local productionTimers: { [number]: { [string]: number } } = {}

-- Callbacks pour notifier le client des mises à jour
local onProductionUpdateCallbacks: { (Player, Types.MachineId, Types.MachineState) -> () } = {}
local onCoinsUpdateCallbacks: { (Player, number) -> () } = {}

-- ============================================================
-- PRIVATE
-- ============================================================

local function getMachineMultiplier(data: Types.PlayerData): number
    return data.multiplier
end

local function initPlayerTimers(player: Player)
    productionTimers[player.UserId] = {}
    print("[ProductionService] Timers initialisés pour", player.Name)
end

local function cleanPlayerTimers(player: Player)
    productionTimers[player.UserId] = nil
    print("[ProductionService] Timers nettoyés pour", player.Name)
end

local function notifyProductionUpdate(player: Player, machineId: Types.MachineId, state: Types.MachineState)
    for _, callback in ipairs(onProductionUpdateCallbacks) do
        task.spawn(function()
            callback(player, machineId, state)
        end)
    end
end

local function _notifyCoinsUpdate(player: Player, coins: number)
    for _, callback in ipairs(onCoinsUpdateCallbacks) do
        task.spawn(function()
            callback(player, coins)
        end)
    end
end

local function processMachine(player: Player, machineId: Types.MachineId, now: number)
    local data = PlayerService.getData(player)
    if not data then return end

    local machineState = data.ownedMachines[machineId]
    if not machineState or not machineState.isRunning then return end

    local machineConfig = Config.MACHINES[machineId]
    if not machineConfig then return end

    -- Vérifier le stock d'entrée
    if machineState.inputStock <= 0 then
        machineState.isRunning = false
        machineState.progress = 0
        notifyProductionUpdate(player, machineId, machineState)
        return
    end

    local timers = productionTimers[player.UserId]
    if not timers then return end

    local lastTick = timers[machineId] or now
    local elapsed = now - lastTick
    local multiplier = getMachineMultiplier(data)

    -- Temps de production ajusté par le multiplicateur
    local adjustedTime = machineConfig.productionTime / multiplier

    -- Mettre à jour le progress
    machineState.progress = math.min(1, (now - lastTick) / adjustedTime)

    -- Cycle terminé ?
    if elapsed >= adjustedTime then
        -- Consommer l'input
        machineState.inputStock -= 1

        -- Produire l'output
        local produced = machineConfig.outputAmount
        machineState.outputStock += produced

        -- Mettre à jour les stats
        PlayerService.updateData(player, function(d)
            d.stats.totalProduced += produced
        end)

        -- Reset le timer
        timers[machineId] = now
        machineState.progress = 0

        print("[ProductionService]", player.Name, "- Machine", machineId, "a produit", produced, machineConfig.output)
    else
        timers[machineId] = timers[machineId] or now
    end

    notifyProductionUpdate(player, machineId, machineState)
end

-- ============================================================
-- PUBLIC
-- ============================================================

function ProductionService.onProductionUpdate(callback: (Player, Types.MachineId, Types.MachineState) -> ())
    table.insert(onProductionUpdateCallbacks, callback)
end

function ProductionService.onCoinsUpdate(callback: (Player, number) -> ())
    table.insert(onCoinsUpdateCallbacks, callback)
end

-- Acheter une machine
function ProductionService.buyMachine(player: Player, machineId: Types.MachineId): (boolean, string?)
    local data = PlayerService.getData(player)
    if not data then return false, "Données introuvables" end

    local machineConfig = Config.MACHINES[machineId]
    if not machineConfig then return false, "Machine invalide" end

    -- Vérifier si la zone est débloquée
    local zoneUnlocked = false
    for _, zoneId in ipairs(data.unlockedZones) do
        if zoneId == machineConfig.zone then
            zoneUnlocked = true
            break
        end
    end

    if not zoneUnlocked then
        return false, "Zone non débloquée"
    end

    -- Vérifier si déjà achetée
    if data.ownedMachines[machineId] then
        return false, "Machine déjà achetée"
    end

    -- Vérifier les coins
    local success = PlayerService.spendCoins(player, machineConfig.cost)
    if not success then
        return false, "Pas assez de coins (" .. machineConfig.cost .. " requis)"
    end

    -- Ajouter la machine
    PlayerService.updateData(player, function(d)
        d.ownedMachines[machineId] = {
            id = machineId,
            isRunning = false,
            progress = 0,
            inputStock = 0,
            outputStock = 0,
        }
    end)

    -- Init le timer
    if productionTimers[player.UserId] then
        productionTimers[player.UserId][machineId] = os.clock()
    end

    print("[ProductionService]", player.Name, "a acheté la machine :", machineId)
    return true, nil
end

-- Démarrer une machine
function ProductionService.startMachine(player: Player, machineId: Types.MachineId): (boolean, string?)
    local data = PlayerService.getData(player)
    if not data then return false, "Données introuvables" end

    local machineState = data.ownedMachines[machineId]
    if not machineState then return false, "Machine non possédée" end

    if machineState.inputStock <= 0 then
        return false, "Pas de stock d'entrée"
    end

    PlayerService.updateData(player, function(d)
        d.ownedMachines[machineId].isRunning = true
    end)

    if productionTimers[player.UserId] then
        productionTimers[player.UserId][machineId] = os.clock()
    end

    return true, nil
end

-- Arrêter une machine
function ProductionService.stopMachine(player: Player, machineId: Types.MachineId): (boolean, string?)
    local data = PlayerService.getData(player)
    if not data then return false, "Données introuvables" end

    local machineState = data.ownedMachines[machineId]
    if not machineState then return false, "Machine non possédée" end

    PlayerService.updateData(player, function(d)
        d.ownedMachines[machineId].isRunning = false
        d.ownedMachines[machineId].progress = 0
    end)

    return true, nil
end

-- Ajouter du stock d'entrée à une machine
function ProductionService.addInputStock(player: Player, machineId: Types.MachineId, amount: number): (boolean, string?)
    local data = PlayerService.getData(player)
    if not data then return false, "Données introuvables" end

    local machineState = data.ownedMachines[machineId]
    if not machineState then return false, "Machine non possédée" end

    local machineConfig = Config.MACHINES[machineId]
    if not machineConfig then return false, "Machine invalide" end

    -- Vérifier si le joueur a assez de la ressource input
    local hasEnough = DataService.hasResource(player, machineConfig.input, amount)
    if not hasEnough then
        return false, "Pas assez de " .. machineConfig.input .. " dans l'inventaire"
    end

    -- Consommer depuis l'inventaire
    DataService.removeResource(player, machineConfig.input, amount)

    -- Ajouter dans le stock de la machine
    PlayerService.updateData(player, function(d)
        d.ownedMachines[machineId].inputStock += amount
    end)

    print("[ProductionService]", player.Name, "a chargé", amount, machineConfig.input, "dans", machineId)
    return true, nil
end

-- Collecter l'output d'une machine et le convertir en coins
function ProductionService.collectOutput(player: Player, machineId: Types.MachineId): (boolean, string?, number?)
    local data = PlayerService.getData(player)
    if not data then return false, "Données introuvables", nil end

    local machineState = data.ownedMachines[machineId]
    if not machineState then return false, "Machine non possédée", nil end

    if machineState.outputStock <= 0 then
        return false, "Pas de stock à collecter", nil
    end

    local machineConfig = Config.MACHINES[machineId]
    if not machineConfig then return false, "Machine invalide", nil end

    local amount = machineState.outputStock

    -- Vider l'output de la machine
    PlayerService.updateData(player, function(d)
        d.ownedMachines[machineId].outputStock = 0
    end)

    -- Ajouter dans l'inventaire ressources du joueur
    DataService.addResource(player, machineConfig.output, amount)

    -- Mettre à jour les stats
    PlayerService.updateData(player, function(d)
        d.stats.totalProduced += amount
    end)

    print("[ProductionService]", player.Name, "a collecté", amount, machineConfig.output, "depuis", machineId)
    return true, nil, amount
end

-- ============================================================
-- BOUCLE DE PRODUCTION
-- ============================================================

local function productionLoop()
    local Players = game:GetService("Players")

    RunService.Heartbeat:Connect(function()
        local now = os.clock()

        for _, player in ipairs(Players:GetPlayers()) do
            local data = PlayerService.getData(player)
            if not data then continue end

            for machineId, machineState in pairs(data.ownedMachines) do
                if machineState.isRunning then
                    processMachine(player, machineId :: Types.MachineId, now)
                end
            end
        end
    end)
end

-- ============================================================
-- INIT
-- ============================================================

function ProductionService.init()
    -- S'abonner aux événements joueur
    PlayerService.onPlayerJoined(function(player, _data)
        initPlayerTimers(player)
    end)

    PlayerService.onPlayerLeaving(function(player, _data)
        cleanPlayerTimers(player)
    end)

    -- Lancer la boucle
    productionLoop()

    print("[ProductionService] Initialisé")
end

return ProductionService