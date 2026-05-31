-- PlayerService.luau
-- Orchestre l'arrivée/départ des joueurs

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.types.Types)
local Config = require(ReplicatedStorage.constants.Config)
local DataService = require(script.Parent.Parent.data.DataService)

-- ============================================================
-- SETUP
-- ============================================================

local PlayerService = {}

-- Callbacks enregistrés par d'autres services
local onPlayerJoinedCallbacks: { (Player, Types.PlayerData) -> () } = {}
local onPlayerLeavingCallbacks: { (Player, Types.PlayerData) -> () } = {}

-- ============================================================
-- PRIVATE
-- ============================================================

local function onPlayerAdded(player: Player)
    print("[PlayerService] Joueur connecté :", player.Name)

    -- Charger les données
    local data = DataService.loadPlayer(player)

    -- Lancer la sauvegarde auto
    DataService.startAutoSave(player)

    -- Notifier les autres services
    for _, callback in ipairs(onPlayerJoinedCallbacks) do
        task.spawn(function()
            callback(player, data)
        end)
    end
end

local function onPlayerRemoving(player: Player)
    print("[PlayerService] Joueur déconnecté :", player.Name)

    local data = DataService.getData(player)

    if data then
        -- Notifier les autres services avant de sauvegarder
        for _, callback in ipairs(onPlayerLeavingCallbacks) do
            task.spawn(function()
                callback(player, data)
            end)
        end
    end

    -- Sauvegarder et nettoyer
    DataService.removePlayer(player)
end

-- ============================================================
-- PUBLIC
-- ============================================================

-- S'abonner aux événements joueur
function PlayerService.onPlayerJoined(callback: (Player, Types.PlayerData) -> ())
    table.insert(onPlayerJoinedCallbacks, callback)
end

function PlayerService.onPlayerLeaving(callback: (Player, Types.PlayerData) -> ())
    table.insert(onPlayerLeavingCallbacks, callback)
end

-- Récupérer les données d'un joueur
function PlayerService.getData(player: Player): Types.PlayerData?
    return DataService.getData(player)
end

-- Modifier les données d'un joueur
function PlayerService.updateData(player: Player, updater: (Types.PlayerData) -> ()): boolean
    return DataService.updateData(player, updater)
end

-- Ajouter des coins
function PlayerService.addCoins(player: Player, amount: number): boolean
    return PlayerService.updateData(player, function(data)
        data.coins += amount
        data.stats.totalEarned += amount
    end)
end

-- Dépenser des coins
function PlayerService.spendCoins(player: Player, amount: number): boolean
    local data = PlayerService.getData(player)
    if not data then return false end
    if data.coins < amount then return false end

    return PlayerService.updateData(player, function(d)
        d.coins -= amount
    end)
end

-- Débloquer une zone
function PlayerService.unlockZone(player: Player, zoneId: Types.ZoneId): (boolean, string?)
    local data = PlayerService.getData(player)
    if not data then return false, "Données introuvables" end

    local zone = Config.ZONES[zoneId]
    if not zone then return false, "Zone invalide" end

    -- Vérifier si déjà débloquée
    for _, unlockedZone in ipairs(data.unlockedZones) do
        if unlockedZone == zoneId then
            return false, "Zone déjà débloquée"
        end
    end

    -- Vérifier les rebirths requis
    if data.rebirths < zone.requiredRebirths then
        return false, "Pas assez de rebirths (" .. zone.requiredRebirths .. " requis)"
    end

    -- Vérifier les coins
    if data.coins < zone.unlockCost then
        return false, "Pas assez de coins (" .. zone.unlockCost .. " requis)"
    end

    -- Débloquer
    PlayerService.spendCoins(player, zone.unlockCost)
    PlayerService.updateData(player, function(d)
        table.insert(d.unlockedZones, zoneId)
    end)

    print("[PlayerService]", player.Name, "a débloqué la zone :", zone.displayName)
    return true, nil
end

-- Rebirth
function PlayerService.rebirth(player: Player): (boolean, string?)
    local data = PlayerService.getData(player)
    if not data then return false, "Données introuvables" end

    if data.coins < Config.REBIRTH.MIN_COINS_REQUIRED then
        return false, "Pas assez de coins (" .. Config.REBIRTH.MIN_COINS_REQUIRED .. " requis)"
    end

    local newRebirths = 0
    PlayerService.updateData(player, function(d)
        -- Garder un % des coins
        d.coins = math.floor(d.coins * Config.REBIRTH.KEPT_PROGRESS_RATIO)

        -- Incrémenter le rebirth et le multiplicateur
        d.rebirths += 1
        d.multiplier = 1.0 + (d.rebirths * Config.REBIRTH.BASE_MULTIPLIER)

        -- Reset les machines
        d.ownedMachines = {}

        -- Garder uniquement la forêt
        d.unlockedZones = { "forest" }

        newRebirths = d.rebirths
    end)

    print("[PlayerService]", player.Name, "a fait un rebirth ! Total :", newRebirths)
    return true, nil
end

-- ============================================================
-- INIT
-- ============================================================

function PlayerService.init()
    -- Connecter les événements
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    -- Gérer les joueurs déjà connectés (si le script charge tard)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(onPlayerAdded, player)
    end

    print("[PlayerService] Initialisé")
end

return PlayerService