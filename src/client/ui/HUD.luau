-- HUD.luau
-- Interface principale du joueur

local Players = game:GetService("Players")

local DataController = require(script.Parent.Parent.controllers.DataController)

local HUD = {}

-- ============================================================
-- CRÉATION DE L'UI
-- ============================================================

local function createHUD(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- ── Conteneur principal (haut gauche)
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(0, 280, 0, 90)
	topBar.Position = UDim2.new(0, 16, 0, 16)
	topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	topBar.BackgroundTransparency = 0.2
	topBar.BorderSizePixel = 0
	topBar.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = topBar

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = topBar

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 6)
	layout.Parent = topBar

	-- ── Ligne coins
	local coinsFrame = Instance.new("Frame")
	coinsFrame.Name = "CoinsFrame"
	coinsFrame.Size = UDim2.new(1, 0, 0, 28)
	coinsFrame.BackgroundTransparency = 1
	coinsFrame.Parent = topBar

	local coinsIcon = Instance.new("TextLabel")
	coinsIcon.Size = UDim2.new(0, 24, 1, 0)
	coinsIcon.Position = UDim2.new(0, 0, 0, 0)
	coinsIcon.BackgroundTransparency = 1
	coinsIcon.Text = "🪙"
	coinsIcon.TextScaled = true
	coinsIcon.Parent = coinsFrame

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(1, -28, 1, 0)
	coinsLabel.Position = UDim2.new(0, 28, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "0 coins"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 214, 80)
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextSize = 16
	coinsLabel.Parent = coinsFrame

	-- ── Ligne rebirths
	local rebirthFrame = Instance.new("Frame")
	rebirthFrame.Name = "RebirthFrame"
	rebirthFrame.Size = UDim2.new(1, 0, 0, 22)
	rebirthFrame.BackgroundTransparency = 1
	rebirthFrame.Parent = topBar

	local rebirthIcon = Instance.new("TextLabel")
	rebirthIcon.Size = UDim2.new(0, 24, 1, 0)
	rebirthIcon.Position = UDim2.new(0, 0, 0, 0)
	rebirthIcon.BackgroundTransparency = 1
	rebirthIcon.Text = "🔄"
	rebirthIcon.TextScaled = true
	rebirthIcon.Parent = rebirthFrame

	local rebirthLabel = Instance.new("TextLabel")
	rebirthLabel.Name = "RebirthLabel"
	rebirthLabel.Size = UDim2.new(1, -28, 1, 0)
	rebirthLabel.Position = UDim2.new(0, 28, 0, 0)
	rebirthLabel.BackgroundTransparency = 1
	rebirthLabel.Text = "Rebirth x0"
	rebirthLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
	rebirthLabel.Font = Enum.Font.Gotham
	rebirthLabel.TextSize = 14
	rebirthLabel.Parent = rebirthFrame

	-- ── Ligne multiplicateur
	local multFrame = Instance.new("Frame")
	multFrame.Name = "MultFrame"
	multFrame.Size = UDim2.new(1, 0, 0, 18)
	multFrame.BackgroundTransparency = 1
	multFrame.Parent = topBar

	local multLabel = Instance.new("TextLabel")
	multLabel.Name = "MultLabel"
	multLabel.Size = UDim2.new(1, 0, 1, 0)
	multLabel.BackgroundTransparency = 1
	multLabel.Text = "Multiplicateur : x1.00"
	multLabel.TextColor3 = Color3.fromRGB(120, 220, 160)
	multLabel.TextXAlignment = Enum.TextXAlignment.Left
	multLabel.Font = Enum.Font.Gotham
	multLabel.TextSize = 12
	multLabel.Parent = multFrame

	return screenGui
end

-- ============================================================
-- MISE À JOUR DE L'UI
-- ============================================================

local screenGui: ScreenGui
local coinsLabel: TextLabel
local rebirthLabel: TextLabel
local multLabel: TextLabel

local function formatCoins(coins: number): string
	if coins >= 1_000_000 then
		return string.format("%.1fM", coins / 1_000_000)
	elseif coins >= 1_000 then
		return string.format("%.1fK", coins / 1_000)
	end
	return tostring(math.floor(coins))
end

local function updateHUD(data: any)
	if not coinsLabel then
		return
	end
	coinsLabel.Text = formatCoins(data.coins) .. " coins"
	rebirthLabel.Text = "Rebirth x" .. data.rebirths
	multLabel.Text = "Multiplicateur : x" .. string.format("%.2f", data.multiplier)
end

-- ============================================================
-- INIT
-- ============================================================

function HUD.init()
	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	local playerGui = player:WaitForChild("PlayerGui")

	screenGui = createHUD()
	screenGui.Enabled = true
	screenGui.Parent = playerGui

	-- Récupérer les labels
	local topBar = screenGui:WaitForChild("TopBar")
	coinsLabel = topBar:WaitForChild("CoinsFrame"):WaitForChild("CoinsLabel")
	rebirthLabel = topBar:WaitForChild("RebirthFrame"):WaitForChild("RebirthLabel")
	multLabel = topBar:WaitForChild("MultFrame"):WaitForChild("MultLabel")

	-- S'abonner aux mises à jour
	DataController.onDataUpdate(updateHUD)
	DataController.onCoinsUpdate(function(totalCoins)
		if coinsLabel then
			coinsLabel.Text = formatCoins(totalCoins) .. " coins"
		end
	end)

	print("[HUD] Initialisé")
end

return HUD
