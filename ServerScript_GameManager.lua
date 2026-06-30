-- ============================================================
-- BRAINROT TYCOON - GameManager (ServerScriptService)
-- Place this Script inside ServerScriptService
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local DataStore = DataStoreService:GetDataStore("BrainrotTycoonV1")

-- ============================================================
-- CREATURE DEFINITIONS
-- ============================================================
local CREATURES = {
	{
		id = "tralalero",
		name = "Tralalero Tralala",
		emoji = "🐊",
		baseCost = 10,
		baseCPS = 0.5,
		unlockAt = 0,
		color = Color3.fromRGB(34, 197, 94),
	},
	{
		id = "bombardiro",
		name = "Bombardiro Crocodilo",
		emoji = "🐊💣",
		baseCost = 80,
		baseCPS = 2,
		unlockAt = 50,
		color = Color3.fromRGB(234, 88, 12),
	},
	{
		id = "tungtung",
		name = "Tung Tung Sahur",
		emoji = "🥁",
		baseCost = 300,
		baseCPS = 8,
		unlockAt = 150,
		color = Color3.fromRGB(168, 85, 247),
	},
	{
		id = "vacasaturno",
		name = "La Vaca Saturno Saturnita",
		emoji = "🐄🪐",
		baseCost = 1200,
		baseCPS = 30,
		unlockAt = 600,
		color = Color3.fromRGB(59, 130, 246),
	},
	{
		id = "cappuccino",
		name = "Capuccino Assassino",
		emoji = "☕🗡️",
		baseCost = 5000,
		baseCPS = 100,
		unlockAt = 2000,
		color = Color3.fromRGB(161, 98, 7),
	},
	{
		id = "fruli",
		name = "Fruli Frula",
		emoji = "🌸🎵",
		baseCost = 20000,
		baseCPS = 350,
		unlockAt = 8000,
		color = Color3.fromRGB(236, 72, 153),
	},
	{
		id = "lirili",
		name = "Lirilì Larilà",
		emoji = "🦄✨",
		baseCost = 80000,
		baseCPS = 1200,
		unlockAt = 30000,
		color = Color3.fromRGB(99, 102, 241),
	},
	{
		id = "brrbrr",
		name = "Brr Brr Patapim",
		emoji = "❄️🔔",
		baseCost = 350000,
		baseCPS = 5000,
		unlockAt = 120000,
		color = Color3.fromRGB(14, 165, 233),
	},
}

local UPGRADES = {
	{ id = "u1", name = "Double Click", cost = 100, desc = "×2 click power", type = "clickMult", value = 2 },
	{ id = "u2", name = "Brainrot Boost", cost = 500, desc = "All CPS ×1.5", type = "cpsMult", value = 1.5 },
	{ id = "u3", name = "Sahur Power", cost = 2000, desc = "×3 click power", type = "clickMult", value = 3 },
	{ id = "u4", name = "Galaxy Brain", cost = 8000, desc = "All CPS ×2", type = "cpsMult", value = 2 },
	{ id = "u5", name = "Mega Moo", cost = 30000, desc = "×5 click power", type = "clickMult", value = 5 },
	{ id = "u6", name = "Tralala MAX", cost = 120000, desc = "All CPS ×3", type = "cpsMult", value = 3 },
}

-- ============================================================
-- REMOTE EVENTS SETUP
-- ============================================================
local function setupRemotes()
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotRemotes"
	folder.Parent = ReplicatedStorage

	local events = {
		"BuyCreature",
		"BuyUpgrade",
		"ClickEarn",
		"Prestige",
		"UpdateData",      -- Server -> Client
		"ShowNotification", -- Server -> Client
	}
	local remotes = {}
	for _, name in ipairs(events) do
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = folder
		remotes[name] = re
	end

	local funcs = { "GetCreatures", "GetUpgrades" }
	local remoteFunctions = {}
	for _, name in ipairs(funcs) do
		local rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = folder
		remoteFunctions[name] = rf
	end

	return remotes, remoteFunctions
end

local Remotes, RemoteFunctions = setupRemotes()

-- ============================================================
-- PLAYER DATA
-- ============================================================
local PlayerData = {}

local function defaultData()
	local counts = {}
	for _, c in ipairs(CREATURES) do
		counts[c.id] = 0
	end
	local upgrades = {}
	for _, u in ipairs(UPGRADES) do
		upgrades[u.id] = false
	end
	return {
		coins = 0,
		totalEarned = 0,
		counts = counts,
		upgrades = upgrades,
		clickMult = 1,
		cpsMult = 1,
		prestigeMult = 1,
		prestigeCount = 0,
	}
end

local function loadData(player)
	local success, data = pcall(function()
		return DataStore:GetAsync("player_" .. player.UserId)
	end)
	if success and data then
		-- Merge with default to handle new fields
		local def = defaultData()
		for k, v in pairs(def) do
			if data[k] == nil then
				data[k] = v
			end
		end
		-- Ensure all creature/upgrade keys exist
		for _, c in ipairs(CREATURES) do
			if data.counts[c.id] == nil then data.counts[c.id] = 0 end
		end
		for _, u in ipairs(UPGRADES) do
			if data.upgrades[u.id] == nil then data.upgrades[u.id] = false end
		end
		return data
	else
		return defaultData()
	end
end

local function saveData(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	pcall(function()
		DataStore:SetAsync("player_" .. player.UserId, data)
	end)
end

-- ============================================================
-- GAME LOGIC HELPERS
-- ============================================================
local function getCreatureCost(data, creatureId)
	local creature
	for _, c in ipairs(CREATURES) do
		if c.id == creatureId then creature = c break end
	end
	if not creature then return math.huge end
	local count = data.counts[creatureId] or 0
	return math.floor(creature.baseCost * (1.15 ^ count))
end

local function getTotalCPS(data)
	local cps = 0
	for _, c in ipairs(CREATURES) do
		cps = cps + (c.baseCPS * (data.counts[c.id] or 0) * data.cpsMult * data.prestigeMult)
	end
	return cps
end

local function getClickPower(data)
	return math.max(1, math.floor(data.clickMult * data.prestigeMult))
end

local function sendUpdate(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	Remotes["UpdateData"]:FireClient(player, {
		coins       = data.coins,
		totalEarned = data.totalEarned,
		counts      = data.counts,
		upgrades    = data.upgrades,
		clickPower  = getClickPower(data),
		totalCPS    = getTotalCPS(data),
		prestigeMult = data.prestigeMult,
		prestigeCount = data.prestigeCount,
	})
end

-- ============================================================
-- REMOTE FUNCTION HANDLERS
-- ============================================================
RemoteFunctions["GetCreatures"].OnServerInvoke = function(player)
	return CREATURES
end

RemoteFunctions["GetUpgrades"].OnServerInvoke = function(player)
	return UPGRADES
end

-- ============================================================
-- REMOTE EVENT HANDLERS
-- ============================================================

-- CLICK EARN
Remotes["ClickEarn"].OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data then return end

	local power = getClickPower(data)
	data.coins = data.coins + power
	data.totalEarned = data.totalEarned + power
	sendUpdate(player)
end)

-- BUY CREATURE
Remotes["BuyCreature"].OnServerEvent:Connect(function(player, creatureId)
	local data = PlayerData[player.UserId]
	if not data then return end

	-- Validate creature id
	local creature
	for _, c in ipairs(CREATURES) do
		if c.id == creatureId then creature = c break end
	end
	if not creature then return end

	-- Check unlock threshold
	if data.totalEarned < creature.unlockAt and data.counts[creatureId] == 0 then
		return
	end

	local cost = getCreatureCost(data, creatureId)
	if data.coins < cost then return end

	data.coins = data.coins - cost
	data.counts[creatureId] = (data.counts[creatureId] or 0) + 1

	sendUpdate(player)
	Remotes["ShowNotification"]:FireClient(player, "✅ Bought " .. creature.name .. "!", Color3.fromRGB(74, 222, 128))
end)

-- BUY UPGRADE
Remotes["BuyUpgrade"].OnServerEvent:Connect(function(player, upgradeId)
	local data = PlayerData[player.UserId]
	if not data then return end

	local upgrade
	for _, u in ipairs(UPGRADES) do
		if u.id == upgradeId then upgrade = u break end
	end
	if not upgrade then return end
	if data.upgrades[upgradeId] then return end -- already owned
	if data.coins < upgrade.cost then return end

	data.coins = data.coins - upgrade.cost
	data.upgrades[upgradeId] = true

	if upgrade.type == "clickMult" then
		data.clickMult = data.clickMult * upgrade.value
	elseif upgrade.type == "cpsMult" then
		data.cpsMult = data.cpsMult * upgrade.value
	end

	sendUpdate(player)
	Remotes["ShowNotification"]:FireClient(player, "⚡ Upgrade unlocked: " .. upgrade.name .. "!", Color3.fromRGB(167, 139, 250))
end)

-- PRESTIGE
Remotes["Prestige"].OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	if data.totalEarned < 10000 then
		Remotes["ShowNotification"]:FireClient(player, "⚠️ Need 10,000 total coins to prestige!", Color3.fromRGB(251, 191, 36))
		return
	end

	data.prestigeMult = data.prestigeMult * 2
	data.prestigeCount = data.prestigeCount + 1
	data.coins = 0
	data.totalEarned = 0
	data.clickMult = 1
	data.cpsMult = 1
	for _, c in ipairs(CREATURES) do
		data.counts[c.id] = 0
	end
	for _, u in ipairs(UPGRADES) do
		data.upgrades[u.id] = false
	end

	sendUpdate(player)
	Remotes["ShowNotification"]:FireClient(player,
		"🔁 PRESTIGE #" .. data.prestigeCount .. "! Earning ×" .. data.prestigeMult .. " permanently!",
		Color3.fromRGB(249, 115, 22))
end)

-- ============================================================
-- PLAYER JOIN / LEAVE
-- ============================================================
Players.PlayerAdded:Connect(function(player)
	local data = loadData(player)
	PlayerData[player.UserId] = data

	-- Wait for character and then send initial data
	task.wait(1)
	sendUpdate(player)
	Remotes["ShowNotification"]:FireClient(player, "🌀 Welcome to Brainrot Tycoon!", Color3.fromRGB(167, 139, 250))
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	PlayerData[player.UserId] = nil
end)

-- Auto-save every 60 seconds
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end
end)

-- ============================================================
-- CPS TICK - Add coins from passive income every second
-- ============================================================
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerData[player.UserId]
			if data then
				local cps = getTotalCPS(data)
				if cps > 0 then
					data.coins = data.coins + cps
					data.totalEarned = data.totalEarned + cps
					sendUpdate(player)
				end
			end
		end
	end
end)

print("✅ BrainrotTycoon GameManager loaded!")
