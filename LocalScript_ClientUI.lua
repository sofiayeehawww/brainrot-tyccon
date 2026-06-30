-- ============================================================
-- BRAINROT TYCOON - ClientUI (StarterPlayerScripts)
-- Place this LocalScript inside StarterPlayerScripts
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for remotes
local RemoteFolder = ReplicatedStorage:WaitForChild("BrainrotRemotes", 10)
if not RemoteFolder then error("BrainrotRemotes not found!") end

local Remotes = {
	BuyCreature      = RemoteFolder:WaitForChild("BuyCreature"),
	BuyUpgrade       = RemoteFolder:WaitForChild("BuyUpgrade"),
	ClickEarn        = RemoteFolder:WaitForChild("ClickEarn"),
	Prestige         = RemoteFolder:WaitForChild("Prestige"),
	UpdateData       = RemoteFolder:WaitForChild("UpdateData"),
	ShowNotification = RemoteFolder:WaitForChild("ShowNotification"),
}
local RemoteFunctions = {
	GetCreatures = RemoteFolder:WaitForChild("GetCreatures"),
	GetUpgrades  = RemoteFolder:WaitForChild("GetUpgrades"),
}

-- Fetch static data
local CREATURES = RemoteFunctions.GetCreatures:InvokeServer()
local UPGRADES  = RemoteFunctions.GetUpgrades:InvokeServer()

-- Local cache of last received state
local GameState = {
	coins        = 0,
	totalEarned  = 0,
	counts       = {},
	upgrades     = {},
	clickPower   = 1,
	totalCPS     = 0,
	prestigeMult  = 1,
	prestigeCount = 0,
}

-- ============================================================
-- NUMBER FORMATTING
-- ============================================================
local function fmtNum(n)
	n = math.floor(n)
	if n >= 1e12 then return string.format("%.2fT", n / 1e12) end
	if n >= 1e9  then return string.format("%.2fB", n / 1e9)  end
	if n >= 1e6  then return string.format("%.2fM", n / 1e6)  end
	if n >= 1000 then return string.format("%.1fK", n / 1000) end
	return tostring(n)
end

-- ============================================================
-- BUILD THE GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BrainrotTycoonGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- ── Background Panel ──────────────────────────────────────
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 620)
MainFrame.Position = UDim2.new(1, -440, 0.5, -310)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(80, 60, 140)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

local MainPadding = Instance.new("UIPadding")
MainPadding.PaddingLeft   = UDim.new(0, 12)
MainPadding.PaddingRight  = UDim.new(0, 12)
MainPadding.PaddingTop    = UDim.new(0, 10)
MainPadding.PaddingBottom = UDim.new(0, 10)
MainPadding.Parent = MainFrame

local MainLayout = Instance.new("UIListLayout")
MainLayout.FillDirection = Enum.FillDirection.Vertical
MainLayout.SortOrder = Enum.SortOrder.LayoutOrder
MainLayout.Padding = UDim.new(0, 8)
MainLayout.Parent = MainFrame

-- ── Helper: create label ──────────────────────────────────
local function makeLabel(parent, text, size, color, weight, order)
	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.TextSize = size
	lbl.TextColor3 = color or Color3.fromRGB(255,255,255)
	lbl.Font = weight or Enum.Font.GothamBold
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.LayoutOrder = order or 0
	lbl.Parent = parent
	return lbl
end

local function makeButton(parent, text, bgColor, textColor, order)
	local btn = Instance.new("TextButton")
	btn.Text = text
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = textColor or Color3.fromRGB(255,255,255)
	btn.BackgroundColor3 = bgColor or Color3.fromRGB(80, 60, 200)
	btn.BorderSizePixel = 0
	btn.AutomaticSize = Enum.AutomaticSize.Y
	btn.Size = UDim2.new(1, 0, 0, 0)
	btn.LayoutOrder = order or 0
	btn.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn
	return btn
end

local function sectionLabel(text, order)
	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.TextSize = 11
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.fromRGB(140, 120, 200)
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Size = UDim2.new(1, 0, 0, 18)
	lbl.LayoutOrder = order
	lbl.Parent = MainFrame
	return lbl
end

-- ── HEADER ────────────────────────────────────────────────
local HeaderFrame = Instance.new("Frame")
HeaderFrame.BackgroundTransparency = 1
HeaderFrame.Size = UDim2.new(1, 0, 0, 36)
HeaderFrame.LayoutOrder = 1
HeaderFrame.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "🌀 BRAINROT TYCOON"
TitleLabel.TextSize = 20
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextColor3 = Color3.fromRGB(210, 160, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Size = UDim2.new(0.6, 0, 1, 0)
TitleLabel.Parent = HeaderFrame

local CoinLabel = Instance.new("TextLabel")
CoinLabel.Name = "CoinLabel"
CoinLabel.Text = "🪙 0"
CoinLabel.TextSize = 15
CoinLabel.Font = Enum.Font.GothamBold
CoinLabel.TextColor3 = Color3.fromRGB(253, 230, 138)
CoinLabel.BackgroundColor3 = Color3.fromRGB(60, 45, 10)
CoinLabel.BackgroundTransparency = 0.4
CoinLabel.BorderSizePixel = 0
CoinLabel.Size = UDim2.new(0.38, 0, 0.85, 0)
CoinLabel.Position = UDim2.new(0.62, 0, 0.08, 0)
CoinLabel.TextXAlignment = Enum.TextXAlignment.Center
CoinLabel.Parent = HeaderFrame
local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(1,0) cc.Parent = CoinLabel

-- ── STATS ROW ─────────────────────────────────────────────
local StatsFrame = Instance.new("Frame")
StatsFrame.BackgroundTransparency = 1
StatsFrame.Size = UDim2.new(1, 0, 0, 46)
StatsFrame.LayoutOrder = 2
StatsFrame.Parent = MainFrame
local StatsLayout = Instance.new("UIListLayout")
StatsLayout.FillDirection = Enum.FillDirection.Horizontal
StatsLayout.SortOrder = Enum.SortOrder.LayoutOrder
StatsLayout.Padding = UDim.new(0, 6)
StatsLayout.Parent = StatsFrame

local function statBox(labelText, order)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.fromRGB(25, 20, 50)
	f.BorderSizePixel = 0
	f.Size = UDim2.new(0.32, 0, 1, 0)
	f.LayoutOrder = order
	f.Parent = StatsFrame
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,8) c.Parent = f
	local lbl = Instance.new("TextLabel")
	lbl.Text = labelText
	lbl.TextSize = 10
	lbl.Font = Enum.Font.Gotham
	lbl.TextColor3 = Color3.fromRGB(160, 140, 210)
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 0.45, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.Parent = f
	local val = Instance.new("TextLabel")
	val.Text = "0"
	val.TextSize = 16
	val.Font = Enum.Font.GothamBlack
	val.TextColor3 = Color3.fromRGB(255, 255, 255)
	val.BackgroundTransparency = 1
	val.Size = UDim2.new(1, 0, 0.55, 0)
	val.Position = UDim2.new(0, 0, 0.45, 0)
	val.TextXAlignment = Enum.TextXAlignment.Center
	val.Parent = f
	return val
end

local CPSValue   = statBox("PER SEC", 1)
local TotalValue = statBox("TOTAL", 2)
local CPCValue   = statBox("PER CLICK", 3)

-- ── CLICK BUTTON ──────────────────────────────────────────
local ClickFrame = Instance.new("Frame")
ClickFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 50)
ClickFrame.BorderSizePixel = 0
ClickFrame.Size = UDim2.new(1, 0, 0, 90)
ClickFrame.LayoutOrder = 3
ClickFrame.Parent = MainFrame
local ClickCorner = Instance.new("UICorner") ClickCorner.CornerRadius = UDim.new(0,14) ClickCorner.Parent = ClickFrame
local ClickStroke = Instance.new("UIStroke") ClickStroke.Color = Color3.fromRGB(100,70,180) ClickStroke.Thickness = 1.5 ClickStroke.Parent = ClickFrame

local ClickEmoji = Instance.new("TextLabel")
ClickEmoji.Text = "🐊"
ClickEmoji.TextSize = 52
ClickEmoji.Font = Enum.Font.GothamBlack
ClickEmoji.TextColor3 = Color3.fromRGB(255,255,255)
ClickEmoji.BackgroundTransparency = 1
ClickEmoji.Size = UDim2.new(0.3, 0, 1, 0)
ClickEmoji.TextXAlignment = Enum.TextXAlignment.Center
ClickEmoji.Parent = ClickFrame

local ClickInfo = Instance.new("Frame")
ClickInfo.BackgroundTransparency = 1
ClickInfo.Size = UDim2.new(0.68, 0, 1, 0)
ClickInfo.Position = UDim2.new(0.3, 0, 0, 0)
ClickInfo.Parent = ClickFrame
local ClickInfoLayout = Instance.new("UIListLayout") ClickInfoLayout.VerticalAlignment = Enum.VerticalAlignment.Center ClickInfoLayout.Padding = UDim.new(0,2) ClickInfoLayout.Parent = ClickInfo

local ClickCreatureName = Instance.new("TextLabel")
ClickCreatureName.Text = "Tralalero Tralala"
ClickCreatureName.TextSize = 14
ClickCreatureName.Font = Enum.Font.GothamBold
ClickCreatureName.TextColor3 = Color3.fromRGB(200, 180, 255)
ClickCreatureName.BackgroundTransparency = 1
ClickCreatureName.Size = UDim2.new(1, -8, 0, 20)
ClickCreatureName.TextXAlignment = Enum.TextXAlignment.Left
ClickCreatureName.Parent = ClickInfo

local ClickHint = Instance.new("TextLabel")
ClickHint.Text = "🖱️ Click here to earn coins!"
ClickHint.TextSize = 11
ClickHint.Font = Enum.Font.Gotham
ClickHint.TextColor3 = Color3.fromRGB(140, 120, 170)
ClickHint.BackgroundTransparency = 1
ClickHint.Size = UDim2.new(1, -8, 0, 16)
ClickHint.TextXAlignment = Enum.TextXAlignment.Left
ClickHint.Parent = ClickInfo

local ClickBtn = Instance.new("TextButton")
ClickBtn.Text = ""
ClickBtn.BackgroundTransparency = 1
ClickBtn.Size = UDim2.new(1, 0, 1, 0)
ClickBtn.ZIndex = 5
ClickBtn.Parent = ClickFrame

-- ── SECTION: CREATURES ────────────────────────────────────
sectionLabel("🧬 EVOLVE CREATURES", 4)

local CreaturesScroll = Instance.new("ScrollingFrame")
CreaturesScroll.Name = "CreaturesScroll"
CreaturesScroll.BackgroundTransparency = 1
CreaturesScroll.BorderSizePixel = 0
CreaturesScroll.Size = UDim2.new(1, 0, 0, 180)
CreaturesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
CreaturesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
CreaturesScroll.ScrollBarThickness = 4
CreaturesScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 200)
CreaturesScroll.LayoutOrder = 5
CreaturesScroll.Parent = MainFrame

local CreaturesGrid = Instance.new("UIGridLayout")
CreaturesGrid.CellSize = UDim2.new(0, 92, 0, 82)
CreaturesGrid.CellPadding = UDim2.new(0, 6, 0, 6)
CreaturesGrid.SortOrder = Enum.SortOrder.LayoutOrder
CreaturesGrid.Parent = CreaturesScroll

-- ── SECTION: UPGRADES ─────────────────────────────────────
sectionLabel("⚡ UPGRADES", 6)

local UpgradesScroll = Instance.new("ScrollingFrame")
UpgradesScroll.BackgroundTransparency = 1
UpgradesScroll.BorderSizePixel = 0
UpgradesScroll.Size = UDim2.new(1, 0, 0, 130)
UpgradesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
UpgradesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
UpgradesScroll.ScrollBarThickness = 4
UpgradesScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 200)
UpgradesScroll.LayoutOrder = 7
UpgradesScroll.Parent = MainFrame

local UpgradesGrid = Instance.new("UIGridLayout")
UpgradesGrid.CellSize = UDim2.new(0, 126, 0, 58)
UpgradesGrid.CellPadding = UDim2.new(0, 6, 0, 6)
UpgradesGrid.SortOrder = Enum.SortOrder.LayoutOrder
UpgradesGrid.Parent = UpgradesScroll

-- ── PRESTIGE BUTTON ───────────────────────────────────────
sectionLabel("🔁 PRESTIGE", 8)

local PrestigeBtn = makeButton(MainFrame, "🔁 PRESTIGE — Reset for ×2 bonus (need 10,000 🪙)", Color3.fromRGB(120, 40, 20), Color3.fromRGB(255, 200, 180), 9)
PrestigeBtn.Size = UDim2.new(1, 0, 0, 36)
PrestigeBtn.TextWrapped = true

-- ── NOTIFICATION BANNER ───────────────────────────────────
local NotifLabel = Instance.new("TextLabel")
NotifLabel.Name = "NotifLabel"
NotifLabel.Text = ""
NotifLabel.TextSize = 14
NotifLabel.Font = Enum.Font.GothamBold
NotifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
NotifLabel.BackgroundColor3 = Color3.fromRGB(40, 30, 80)
NotifLabel.BackgroundTransparency = 0
NotifLabel.BorderSizePixel = 0
NotifLabel.Size = UDim2.new(0, 360, 0, 44)
NotifLabel.Position = UDim2.new(0.5, -180, 0, -60)
NotifLabel.TextXAlignment = Enum.TextXAlignment.Center
NotifLabel.TextWrapped = true
NotifLabel.ZIndex = 20
NotifLabel.Visible = false
NotifLabel.Parent = ScreenGui
local nc = Instance.new("UICorner") nc.CornerRadius = UDim.new(0,10) nc.Parent = NotifLabel
local ns = Instance.new("UIStroke") ns.Color = Color3.fromRGB(120,80,200) ns.Thickness = 2 ns.Parent = NotifLabel

-- ============================================================
-- CREATURE CARD BUILDER
-- ============================================================
local CreatureCards = {}

local function buildCreatureCards()
	-- Clear old cards
	for _, child in ipairs(CreaturesScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	CreatureCards = {}

	for i, creature in ipairs(CREATURES) do
		local card = Instance.new("Frame")
		card.Name = "Card_" .. creature.id
		card.BackgroundColor3 = Color3.fromRGB(22, 18, 48)
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = CreaturesScroll
		local cc2 = Instance.new("UICorner") cc2.CornerRadius = UDim.new(0,10) cc2.Parent = card
		local cs = Instance.new("UIStroke") cs.Name = "Stroke" cs.Color = Color3.fromRGB(60,50,100) cs.Thickness = 1.5 cs.Parent = card
		local cl = Instance.new("UIListLayout") cl.HorizontalAlignment = Enum.HorizontalAlignment.Center cl.VerticalAlignment = Enum.VerticalAlignment.Center cl.Padding = UDim.new(0,1) cl.Parent = card

		local emojiLbl = Instance.new("TextLabel")
		emojiLbl.Text = creature.emoji
		emojiLbl.TextSize = 26
		emojiLbl.Font = Enum.Font.GothamBold
		emojiLbl.BackgroundTransparency = 1
		emojiLbl.TextColor3 = Color3.fromRGB(255,255,255)
		emojiLbl.Size = UDim2.new(1, 0, 0, 30)
		emojiLbl.TextXAlignment = Enum.TextXAlignment.Center
		emojiLbl.Parent = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "NameLbl"
		nameLbl.Text = creature.name
		nameLbl.TextSize = 8
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextColor3 = Color3.fromRGB(200,180,255)
		nameLbl.Size = UDim2.new(1, -4, 0, 20)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Center
		nameLbl.TextWrapped = true
		nameLbl.Parent = card

		local costLbl = Instance.new("TextLabel")
		costLbl.Name = "CostLbl"
		costLbl.Text = "🪙" .. fmtNum(creature.baseCost)
		costLbl.TextSize = 10
		costLbl.Font = Enum.Font.GothamBold
		costLbl.BackgroundTransparency = 1
		costLbl.TextColor3 = Color3.fromRGB(253, 230, 138)
		costLbl.Size = UDim2.new(1, 0, 0, 14)
		costLbl.TextXAlignment = Enum.TextXAlignment.Center
		costLbl.Parent = card

		local countLbl = Instance.new("TextLabel")
		countLbl.Name = "CountLbl"
		countLbl.Text = ""
		countLbl.TextSize = 11
		countLbl.Font = Enum.Font.GothamBlack
		countLbl.BackgroundTransparency = 1
		countLbl.TextColor3 = Color3.fromRGB(74, 222, 128)
		countLbl.Size = UDim2.new(1, -4, 0, 14)
		countLbl.TextXAlignment = Enum.TextXAlignment.Right
		countLbl.Position = UDim2.new(0, 0, 0, 2)
		countLbl.ZIndex = 3
		countLbl.Parent = card

		-- Invisible button overlay for click
		local btn = Instance.new("TextButton")
		btn.Text = ""
		btn.BackgroundTransparency = 1
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.ZIndex = 5
		btn.Parent = card

		btn.MouseButton1Click:Connect(function()
			Remotes.BuyCreature:FireServer(creature.id)
		end)

		CreatureCards[creature.id] = {
			frame    = card,
			stroke   = cs,
			costLbl  = costLbl,
			countLbl = countLbl,
		}
	end
end

-- ============================================================
-- UPGRADE CARD BUILDER
-- ============================================================
local UpgradeCards = {}

local function buildUpgradeCards()
	for _, child in ipairs(UpgradesScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	UpgradeCards = {}

	for i, upg in ipairs(UPGRADES) do
		local card = Instance.new("Frame")
		card.Name = "Upg_" .. upg.id
		card.BackgroundColor3 = Color3.fromRGB(28, 18, 55)
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = UpgradesScroll
		local uc = Instance.new("UICorner") uc.CornerRadius = UDim.new(0,8) uc.Parent = card
		local us = Instance.new("UIStroke") us.Name = "Stroke" us.Color = Color3.fromRGB(90, 60, 150) us.Thickness = 1.5 us.Parent = card
		local ul = Instance.new("UIListLayout") ul.HorizontalAlignment = Enum.HorizontalAlignment.Center ul.VerticalAlignment = Enum.VerticalAlignment.Center ul.Padding = UDim.new(0,2) ul.Parent = card

		local nameL = Instance.new("TextLabel")
		nameL.Text = upg.name
		nameL.TextSize = 11
		nameL.Font = Enum.Font.GothamBold
		nameL.BackgroundTransparency = 1
		nameL.TextColor3 = Color3.fromRGB(200, 170, 255)
		nameL.Size = UDim2.new(1, -6, 0, 16)
		nameL.TextXAlignment = Enum.TextXAlignment.Center
		nameL.Parent = card

		local costL = Instance.new("TextLabel")
		costL.Name = "CostL"
		costL.Text = "🪙" .. fmtNum(upg.cost)
		costL.TextSize = 11
		costL.Font = Enum.Font.GothamBold
		costL.BackgroundTransparency = 1
		costL.TextColor3 = Color3.fromRGB(253, 230, 138)
		costL.Size = UDim2.new(1, -6, 0, 14)
		costL.TextXAlignment = Enum.TextXAlignment.Center
		costL.Parent = card

		local descL = Instance.new("TextLabel")
		descL.Text = upg.desc
		descL.TextSize = 9
		descL.Font = Enum.Font.Gotham
		descL.BackgroundTransparency = 1
		descL.TextColor3 = Color3.fromRGB(150, 130, 180)
		descL.Size = UDim2.new(1, -6, 0, 12)
		descL.TextXAlignment = Enum.TextXAlignment.Center
		descL.Parent = card

		local btn = Instance.new("TextButton")
		btn.Text = ""
		btn.BackgroundTransparency = 1
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.ZIndex = 5
		btn.Parent = card

		btn.MouseButton1Click:Connect(function()
			Remotes.BuyUpgrade:FireServer(upg.id)
		end)

		UpgradeCards[upg.id] = {
			frame  = card,
			stroke = us,
			costL  = costL,
		}
	end
end

-- ============================================================
-- REFRESH UI FROM STATE
-- ============================================================
local function getCreatureCost(creatureId)
	for _, c in ipairs(CREATURES) do
		if c.id == creatureId then
			local count = GameState.counts[creatureId] or 0
			return math.floor(c.baseCost * (1.15 ^ count))
		end
	end
	return math.huge
end

local function refreshUI()
	-- Header
	CoinLabel.Text = "🪙 " .. fmtNum(GameState.coins)
	CPSValue.Text   = fmtNum(GameState.totalCPS)
	TotalValue.Text = fmtNum(GameState.totalEarned)
	CPCValue.Text   = fmtNum(GameState.clickPower)

	-- Best creature for click emoji
	local bestCreature = CREATURES[1]
	for i = #CREATURES, 1, -1 do
		if (GameState.counts[CREATURES[i].id] or 0) > 0 then
			bestCreature = CREATURES[i]
			break
		end
	end
	ClickEmoji.Text = bestCreature.emoji
	ClickCreatureName.Text = bestCreature.name

	-- Prestige label
	if GameState.prestigeCount and GameState.prestigeCount > 0 then
		PrestigeBtn.Text = "🔁 PRESTIGE #" .. (GameState.prestigeCount+1) .. " — Reset for ×" .. (GameState.prestigeMult*2) .. " bonus (need 10,000 🪙)"
	end

	-- Creature cards
	for _, creature in ipairs(CREATURES) do
		local card = CreatureCards[creature.id]
		if not card then continue end

		local count = GameState.counts[creature.id] or 0
		local cost = getCreatureCost(creature.id)
		local isLocked = (GameState.totalEarned or 0) < creature.unlockAt and count == 0
		local canAfford = GameState.coins >= cost

		card.frame.BackgroundTransparency = isLocked and 0.6 or 0
		card.countLbl.Text = count > 0 and ("×" .. count) or ""

		if isLocked then
			card.costLbl.Text = "🔒 " .. fmtNum(creature.unlockAt)
			card.costLbl.TextColor3 = Color3.fromRGB(140, 120, 160)
			card.stroke.Color = Color3.fromRGB(50, 40, 80)
		elseif canAfford then
			card.costLbl.Text = "🪙" .. fmtNum(cost)
			card.costLbl.TextColor3 = Color3.fromRGB(253, 230, 138)
			card.stroke.Color = Color3.fromRGB(100, 220, 120)
		else
			card.costLbl.Text = "🪙" .. fmtNum(cost)
			card.costLbl.TextColor3 = Color3.fromRGB(180, 120, 100)
			card.stroke.Color = Color3.fromRGB(60, 50, 100)
		end
	end

	-- Upgrade cards
	for _, upg in ipairs(UPGRADES) do
		local card = UpgradeCards[upg.id]
		if not card then continue end

		local bought = GameState.upgrades[upg.id]
		if bought then
			card.frame.BackgroundColor3 = Color3.fromRGB(20, 40, 20)
			card.stroke.Color = Color3.fromRGB(60, 160, 80)
			card.costL.Text = "✅ Owned"
			card.costL.TextColor3 = Color3.fromRGB(100, 220, 100)
		elseif GameState.coins >= upg.cost then
			card.frame.BackgroundColor3 = Color3.fromRGB(28, 18, 55)
			card.stroke.Color = Color3.fromRGB(130, 80, 220)
			card.costL.Text = "🪙" .. fmtNum(upg.cost)
			card.costL.TextColor3 = Color3.fromRGB(253, 230, 138)
		else
			card.frame.BackgroundColor3 = Color3.fromRGB(22, 15, 40)
			card.stroke.Color = Color3.fromRGB(60, 50, 80)
			card.costL.Text = "🪙" .. fmtNum(upg.cost)
			card.costL.TextColor3 = Color3.fromRGB(160, 100, 80)
		end
	end
end

-- ============================================================
-- FLOATING COIN TEXT (visual feedback on click)
-- ============================================================
local function spawnFloatText(amount)
	local floatLbl = Instance.new("TextLabel")
	floatLbl.Text = "+" .. fmtNum(amount)
	floatLbl.TextSize = 18
	floatLbl.Font = Enum.Font.GothamBlack
	floatLbl.TextColor3 = Color3.fromRGB(253, 230, 138)
	floatLbl.BackgroundTransparency = 1
	floatLbl.ZIndex = 30
	floatLbl.AnchorPoint = Vector2.new(0.5, 0.5)

	local rx = math.random(-60, 60)
	floatLbl.Size = UDim2.new(0, 100, 0, 30)
	floatLbl.Position = UDim2.new(0.5, rx, 0, 380)
	floatLbl.Parent = ScreenGui

	local tween = TweenService:Create(floatLbl, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, rx, 0, 320),
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function() floatLbl:Destroy() end)
end

-- ============================================================
-- CLICK BUTTON HANDLER
-- ============================================================
ClickBtn.MouseButton1Click:Connect(function()
	Remotes.ClickEarn:FireServer()
	spawnFloatText(GameState.clickPower)

	-- Bounce animation
	local tween1 = TweenService:Create(ClickEmoji, TweenInfo.new(0.07, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 64
	})
	local tween2 = TweenService:Create(ClickEmoji, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextSize = 52
	})
	tween1:Play()
	tween1.Completed:Connect(function() tween2:Play() end)
end)

-- ============================================================
-- PRESTIGE BUTTON
-- ============================================================
PrestigeBtn.MouseButton1Click:Connect(function()
	Remotes.Prestige:FireServer()
end)

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local notifActive = false
Remotes.ShowNotification.OnClientEvent:Connect(function(message, color)
	NotifLabel.Text = message
	NotifLabel.BackgroundColor3 = color and Color3.fromRGB(
		math.floor(color.R * 40),
		math.floor(color.G * 40),
		math.floor(color.B * 40)
	) or Color3.fromRGB(40, 30, 80)
	ns.Color = color or Color3.fromRGB(120, 80, 200)
	NotifLabel.Visible = true
	NotifLabel.Position = UDim2.new(0.5, -180, 0, -60)

	local slideIn = TweenService:Create(NotifLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -180, 0, 20)
	})
	slideIn:Play()

	task.delay(3, function()
		local slideOut = TweenService:Create(NotifLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -180, 0, -60)
		})
		slideOut:Play()
		slideOut.Completed:Connect(function() NotifLabel.Visible = false end)
	end)
end)

-- ============================================================
-- RECEIVE STATE FROM SERVER
-- ============================================================
Remotes.UpdateData.OnClientEvent:Connect(function(data)
	GameState.coins        = data.coins
	GameState.totalEarned  = data.totalEarned
	GameState.counts       = data.counts
	GameState.upgrades     = data.upgrades
	GameState.clickPower   = data.clickPower
	GameState.totalCPS     = data.totalCPS
	GameState.prestigeMult  = data.prestigeMult
	GameState.prestigeCount = data.prestigeCount
	refreshUI()
end)

-- ============================================================
-- TOGGLE GUI WITH T KEY
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProc)
	if gameProc then return end
	if input.KeyCode == Enum.KeyCode.T then
		MainFrame.Visible = not MainFrame.Visible
	end
end)

-- ============================================================
-- INIT
-- ============================================================
buildCreatureCards()
buildUpgradeCards()
refreshUI()

print("✅ BrainrotTycoon ClientUI loaded! Press T to toggle.")
