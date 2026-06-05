-- HUD.luau
-- Interface principale du joueur

local Players = game:GetService("Players")

local DataController = require(script.Parent.Parent.controllers.DataController)
local FormatNumber = require(game.ReplicatedStorage.utils.FormatNumber)

local HUD = {}

-- ============================================================
-- CONFIGURATION RESSOURCES
-- ============================================================

local RESOURCES = {
	{ key = "raw_wood",  label = "Bois",   icon = "🌲", color = Color3.fromRGB(151, 196, 89)  },
	{ key = "stone", label = "Pierre", icon = "⛏",  color = Color3.fromRGB(239, 159, 39)  },
	{ key = "wheat", label = "Blé",    icon = "🌾", color = Color3.fromRGB(93, 202, 165)  },
}

-- ============================================================
-- CRÉATION DE L'UI
-- ============================================================

local function createLabel(parent: Instance, props: {
	name: string?,
	size: UDim2,
	position: UDim2?,
	text: string,
	color: Color3?,
	font: Enum.Font?,
	textSize: number?,
	xAlign: Enum.TextXAlignment?,
}): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = props.name or "Label"
	label.Size = props.size
	if props.position then label.Position = props.position end
	label.BackgroundTransparency = 1
	label.Text = props.text
	label.TextColor3 = props.color or Color3.fromRGB(255, 255, 255)
	label.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
	label.Font = props.font or Enum.Font.Gotham
	label.TextSize = props.textSize or 14
	label.Parent = parent
	return label
end

local function createFrame(parent: Instance, props: {
	name: string?,
	size: UDim2,
	position: UDim2?,
	transparent: boolean?,
}): Frame
	local frame = Instance.new("Frame")
	frame.Name = props.name or "Frame"
	frame.Size = props.size
	if props.position then frame.Position = props.position end
	frame.BackgroundTransparency = props.transparent and 1 or 0
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

local function addCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addPadding(parent: Instance, px: number)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, px)
	pad.PaddingRight  = UDim.new(0, px)
	pad.PaddingTop    = UDim.new(0, px)
	pad.PaddingBottom = UDim.new(0, px)
	pad.Parent = parent
end

local function addListLayout(parent: Instance, dir: Enum.FillDirection, padding: number)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = dir
	layout.Padding = UDim.new(0, padding)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
end

-- ── Panel générique (fond semi-transparent + coins arrondis)
local function createPanel(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
	local panel = createFrame(parent, { name = name, size = size, position = position })
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.2
	addCorner(panel, 12)
	return panel
end

local function createHUD(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- ──────────────────────────────────────────────────────────
	-- PANEL COINS / REBIRTH / MULTIPLICATEUR (haut gauche)
	-- ──────────────────────────────────────────────────────────
	local topBar = createPanel(screenGui, "TopBar",
		UDim2.new(0, 280, 0, 90),
		UDim2.new(0, 16, 0, 16)
	)
	addPadding(topBar, 14)
	addListLayout(topBar, Enum.FillDirection.Vertical, 6)

	-- Ligne coins
	local coinsFrame = createFrame(topBar, { name = "CoinsFrame", size = UDim2.new(1, 0, 0, 28), transparent = true })
	coinsFrame.LayoutOrder = 1
	createLabel(coinsFrame, { size = UDim2.new(0, 24, 1, 0), position = UDim2.new(0,0,0,0), text = "🪙", font = Enum.Font.GothamBold, textSize = 16 })
	createLabel(coinsFrame, {
		name = "CoinsLabel",
		size = UDim2.new(1, -28, 1, 0), position = UDim2.new(0, 28, 0, 0),
		text = "0 coins",
		color = Color3.fromRGB(255, 214, 80),
		font = Enum.Font.GothamBold, textSize = 16,
	})

	-- Ligne rebirth
	local rebirthFrame = createFrame(topBar, { name = "RebirthFrame", size = UDim2.new(1, 0, 0, 22), transparent = true })
	rebirthFrame.LayoutOrder = 2
	createLabel(rebirthFrame, { size = UDim2.new(0, 24, 1, 0), position = UDim2.new(0,0,0,0), text = "🔄", textSize = 14 })
	createLabel(rebirthFrame, {
		name = "RebirthLabel",
		size = UDim2.new(1, -28, 1, 0), position = UDim2.new(0, 28, 0, 0),
		text = "Rebirth x0",
		color = Color3.fromRGB(180, 140, 255),
		textSize = 14,
	})

	-- Ligne multiplicateur
	local multFrame = createFrame(topBar, { name = "MultFrame", size = UDim2.new(1, 0, 0, 18), transparent = true })
	multFrame.LayoutOrder = 3
	createLabel(multFrame, {
		name = "MultLabel",
		size = UDim2.new(1, 0, 1, 0),
		text = "Multiplicateur : x1.00",
		color = Color3.fromRGB(120, 220, 160),
		textSize = 12,
	})

	-- ──────────────────────────────────────────────────────────
	-- PANEL RESSOURCES (haut gauche, sous le TopBar)
	-- ──────────────────────────────────────────────────────────
	local resourcesPanel = createPanel(screenGui, "ResourcesPanel",
		UDim2.new(0, 280, 0, 10),   -- hauteur dynamique via AutomaticSize
		UDim2.new(0, 16, 0, 120)    -- 16px du bord gauche, 120px du haut
	)
	resourcesPanel.AutomaticSize = Enum.AutomaticSize.Y
	addPadding(resourcesPanel, 12)
	addListLayout(resourcesPanel, Enum.FillDirection.Vertical, 6)

	-- Titre du panel
	local resTitle = createLabel(resourcesPanel, {
		name = "ResourcesTitle",
		size = UDim2.new(1, 0, 0, 14),
		text = "RESSOURCES",
		color = Color3.fromRGB(120, 120, 140),
		textSize = 11,
	})
	resTitle.LayoutOrder = 0

	-- Lignes de ressources
	for i, res in ipairs(RESOURCES) do
		local row = createFrame(resourcesPanel, {
			name = "Res_" .. res.key,
			size = UDim2.new(1, 0, 0, 22),
			transparent = true,
		})
		row.LayoutOrder = i

		-- Icône
		createLabel(row, {
			size = UDim2.new(0, 22, 1, 0),
			position = UDim2.new(0, 0, 0, 0),
			text = res.icon,
			textSize = 14,
		})

		-- Nom ressource
		createLabel(row, {
			size = UDim2.new(0, 80, 1, 0),
			position = UDim2.new(0, 26, 0, 0),
			text = res.label,
			color = Color3.fromRGB(180, 180, 190),
			textSize = 13,
		})

		-- Quantité (mise à jour dynamique)
		createLabel(row, {
			name = "Value",
			size = UDim2.new(1, -110, 1, 0),
			position = UDim2.new(0, 110, 0, 0),
			text = "0",
			color = res.color,
			font = Enum.Font.GothamBold,
			textSize = 13,
			xAlign = Enum.TextXAlignment.Right,
		})
	end

	return screenGui
end

-- ============================================================
-- MISE À JOUR DE L'UI
-- ============================================================

local screenGui: ScreenGui
local coinsLabel: TextLabel
local rebirthLabel: TextLabel
local multLabel: TextLabel
local resourceValues: { [string]: TextLabel } = {}

local function updateHUD(data: any)
	if not coinsLabel then return end

	-- Coins avec FormatNumber
	coinsLabel.Text = FormatNumber.format(data.coins) .. " coins"
	rebirthLabel.Text = "Rebirth x" .. tostring(data.rebirths)
	multLabel.Text = "Multiplicateur : x" .. string.format("%.2f", data.multiplier or 1.0)

	-- Ressources
	if data.resources then
		for _, res in ipairs(RESOURCES) do
			local label = resourceValues[res.key]
			if label then
				local qty = data.resources[res.key] or 0
				label.Text = FormatNumber.format(qty)
			end
		end
	end
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

	-- Récupérer les labels principaux
	local topBar = screenGui:WaitForChild("TopBar")
	coinsLabel   = topBar:WaitForChild("CoinsFrame"):WaitForChild("CoinsLabel")
	rebirthLabel = topBar:WaitForChild("RebirthFrame"):WaitForChild("RebirthLabel")
	multLabel    = topBar:WaitForChild("MultFrame"):WaitForChild("MultLabel")

	-- Récupérer les labels de ressources
	local resPanel = screenGui:WaitForChild("ResourcesPanel")
	for _, res in ipairs(RESOURCES) do
		local row = resPanel:FindFirstChild("Res_" .. res.key)
		if row then
			resourceValues[res.key] = row:FindFirstChild("Value")
		end
	end

	-- S'abonner aux mises à jour
	DataController.onDataUpdate(updateHUD)
	DataController.onCoinsUpdate(function(totalCoins: number)
		if coinsLabel then
			coinsLabel.Text = FormatNumber.format(totalCoins) .. " coins"
		end
	end)

	print("[HUD] Initialisé avec ressources")
end

return HUD
