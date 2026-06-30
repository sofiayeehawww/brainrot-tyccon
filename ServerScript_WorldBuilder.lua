-- ============================================================
-- BRAINROT TYCOON - WorldBuilder (ServerScriptService)
-- Place this Script inside ServerScriptService
-- Creates the 3D world: baseplate, tycoon pads, decorations
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ── Palette ───────────────────────────────────────────────
local COLORS = {
	ground   = Color3.fromRGB(15, 12, 35),
	pad      = Color3.fromRGB(30, 20, 70),
	accent   = Color3.fromRGB(130, 60, 255),
	glow     = Color3.fromRGB(180, 100, 255),
	gold     = Color3.fromRGB(255, 200, 50),
}

-- ── World Setup ───────────────────────────────────────────
local Workspace = game:GetService("Workspace")

-- Baseplate
local baseplate = Instance.new("Part")
baseplate.Name = "Baseplate"
baseplate.Size = Vector3.new(512, 4, 512)
baseplate.Position = Vector3.new(0, -2, 0)
baseplate.Anchored = true
baseplate.Material = Enum.Material.SmoothPlastic
baseplate.Color = COLORS.ground
baseplate.Parent = Workspace

-- Ambient lighting
local lighting = game:GetService("Lighting")
lighting.Ambient = Color3.fromRGB(30, 20, 60)
lighting.OutdoorAmbient = Color3.fromRGB(50, 30, 90)
lighting.FogEnd = 800
lighting.FogColor = Color3.fromRGB(15, 10, 40)
lighting.Brightness = 1.5
lighting.ClockTime = 0  -- night time = more brainrot vibes

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.1
atmosphere.Haze = 0.2
atmosphere.Parent = lighting

local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxassetid://159454020"
sky.SkyboxDn = "rbxassetid://159454020"
sky.SkyboxFt = "rbxassetid://159454020"
sky.SkyboxLf = "rbxassetid://159454020"
sky.SkyboxRt = "rbxassetid://159454020"
sky.SkyboxUp = "rbxassetid://159454020"
sky.Parent = lighting

-- ── Helper functions ──────────────────────────────────────
local function makePart(name, size, position, color, material, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = anchored ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = Workspace
	return p
end

local function makeNeon(name, size, position, color)
	local p = makePart(name, size, position, color, Enum.Material.Neon)
	return p
end

local function makeBillboardLabel(parent, text, studSize)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, studSize or 200, 0, 60)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = false
	bb.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.TextSize = 18
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.TextScaled = true
	lbl.TextWrapped = true
	lbl.Parent = bb
	return lbl
end

-- ── Spawn Platform ────────────────────────────────────────
local spawnPad = makePart("SpawnPad", Vector3.new(20, 1, 20), Vector3.new(0, 0, 0), Color3.fromRGB(40, 30, 80))
local spawnNeon1 = makeNeon("SpawnNeon", Vector3.new(20, 0.3, 0.3), Vector3.new(0, 0.7, 10), COLORS.accent)
local spawnNeon2 = makeNeon("SpawnNeon2", Vector3.new(20, 0.3, 0.3), Vector3.new(0, 0.7, -10), COLORS.accent)
local spawnNeon3 = makeNeon("SpawnNeon3", Vector3.new(0.3, 0.3, 20), Vector3.new(10, 0.7, 0), COLORS.accent)
local spawnNeon4 = makeNeon("SpawnNeon4", Vector3.new(0.3, 0.3, 20), Vector3.new(-10, 0.7, 0), COLORS.accent)

-- Title sign
local signBase = makePart("TitleSign", Vector3.new(24, 8, 1), Vector3.new(0, 8, -18), Color3.fromRGB(20, 15, 50))
local signGlow = makeNeon("SignGlow", Vector3.new(24, 8.4, 0.3), Vector3.new(0, 8, -17.6), COLORS.accent)
signGlow.Transparency = 0.7

local signBB = Instance.new("BillboardGui")
signBB.Size = UDim2.new(0, 480, 0, 160)
signBB.StudsOffset = Vector3.new(0, 0, 1)
signBB.AlwaysOnTop = false
signBB.Parent = signBase

local signTitle = Instance.new("TextLabel")
signTitle.Text = "🌀 BRAINROT TYCOON"
signTitle.TextSize = 42
signTitle.Font = Enum.Font.GothamBlack
signTitle.TextColor3 = Color3.fromRGB(220, 170, 255)
signTitle.BackgroundTransparency = 1
signTitle.Size = UDim2.new(1, 0, 0.6, 0)
signTitle.TextScaled = true
signTitle.Parent = signBB

local signSub = Instance.new("TextLabel")
signSub.Text = "Press T to open your tycoon!"
signSub.TextSize = 18
signSub.Font = Enum.Font.GothamBold
signSub.TextColor3 = Color3.fromRGB(160, 140, 200)
signSub.BackgroundTransparency = 1
signSub.Size = UDim2.new(1, 0, 0.4, 0)
signSub.Position = UDim2.new(0, 0, 0.6, 0)
signSub.TextScaled = true
signSub.Parent = signBB

-- ── CREATURE PEDESTALS ────────────────────────────────────
-- Each creature gets a glowing pedestal in a circle around spawn

local CREATURE_DEFS = {
	{ name = "Tralalero Tralala",       emoji = "🐊",   color = Color3.fromRGB(34,197,94),   cost = "10🪙"    },
	{ name = "Bombardiro Crocodilo",    emoji = "🐊💣", color = Color3.fromRGB(234,88,12),   cost = "80🪙"    },
	{ name = "Tung Tung Sahur",         emoji = "🥁",   color = Color3.fromRGB(168,85,247),  cost = "300🪙"   },
	{ name = "La Vaca Saturno Saturnita", emoji = "🐄🪐", color = Color3.fromRGB(59,130,246),  cost = "1,200🪙" },
	{ name = "Capuccino Assassino",     emoji = "☕🗡️", color = Color3.fromRGB(161,98,7),    cost = "5,000🪙" },
	{ name = "Fruli Frula",             emoji = "🌸🎵", color = Color3.fromRGB(236,72,153),  cost = "20K🪙"   },
	{ name = "Lirilì Larilà",           emoji = "🦄✨", color = Color3.fromRGB(99,102,241),  cost = "80K🪙"   },
	{ name = "Brr Brr Patapim",         emoji = "❄️🔔", color = Color3.fromRGB(14,165,233),  cost = "350K🪙"  },
}

local PEDESTAL_RADIUS = 55
local PEDESTAL_COUNT = #CREATURE_DEFS

local PedestalFolder = Instance.new("Folder")
PedestalFolder.Name = "CreaturePedestals"
PedestalFolder.Parent = Workspace

for i, cdef in ipairs(CREATURE_DEFS) do
	local angle = (math.pi * 2 / PEDESTAL_COUNT) * (i - 1) - math.pi / 2
	local px = math.cos(angle) * PEDESTAL_RADIUS
	local pz = math.sin(angle) * PEDESTAL_RADIUS

	-- Base pedestal
	local ped = makePart("Ped_" .. cdef.name, Vector3.new(8, 1, 8), Vector3.new(px, 0, pz), Color3.fromRGB(25,20,55))
	ped.Parent = PedestalFolder

	-- Glow ring around pedestal base
	local ring = makeNeon("Ring_" .. i, Vector3.new(8, 0.2, 8), Vector3.new(px, 0.6, pz), cdef.color)
	ring.Transparency = 0.4
	ring.Parent = PedestalFolder

	-- Pillar
	local pillar = makePart("Pillar_" .. i, Vector3.new(2, 5, 2), Vector3.new(px, 3, pz), Color3.fromRGB(30,22,62))
	pillar.Parent = PedestalFolder

	-- Top platform
	local top = makePart("Top_" .. i, Vector3.new(6, 0.5, 6), Vector3.new(px, 5.75, pz), cdef.color)
	top.Material = Enum.Material.Neon
	top.Transparency = 0.3
	top.Parent = PedestalFolder

	-- Billboard label on top
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 220, 0, 100)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = false
	bb.Parent = top

	local bbLayout = Instance.new("UIListLayout")
	bbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	bbLayout.Parent = bb

	local emojiL = Instance.new("TextLabel")
	emojiL.Text = cdef.emoji
	emojiL.TextSize = 36
	emojiL.Font = Enum.Font.GothamBlack
	emojiL.BackgroundTransparency = 1
	emojiL.TextColor3 = Color3.fromRGB(255,255,255)
	emojiL.Size = UDim2.new(1, 0, 0, 40)
	emojiL.TextXAlignment = Enum.TextXAlignment.Center
	emojiL.Parent = bb

	local nameL = Instance.new("TextLabel")
	nameL.Text = cdef.name
	nameL.TextSize = 13
	nameL.Font = Enum.Font.GothamBold
	nameL.BackgroundTransparency = 1
	nameL.TextColor3 = Color3.fromRGB(220, 200, 255)
	nameL.Size = UDim2.new(1, 0, 0, 30)
	nameL.TextWrapped = true
	nameL.TextXAlignment = Enum.TextXAlignment.Center
	nameL.Parent = bb

	local costL = Instance.new("TextLabel")
	costL.Text = "🪙 " .. cdef.cost
	costL.TextSize = 12
	costL.Font = Enum.Font.GothamBold
	costL.BackgroundTransparency = 1
	costL.TextColor3 = Color3.fromRGB(253, 230, 138)
	costL.Size = UDim2.new(1, 0, 0, 20)
	costL.TextXAlignment = Enum.TextXAlignment.Center
	costL.Parent = bb

	-- Floating animation for top glow platform
	task.spawn(function()
		local baseY = 5.75
		local t = (i / PEDESTAL_COUNT) * math.pi * 2 -- offset phase per pedestal
		while true do
			local dt = task.wait(0.05)
			t = t + dt * 1.2
			top.Position = Vector3.new(px, baseY + math.sin(t) * 0.4, pz)
			ring.Transparency = 0.3 + math.sin(t * 0.7) * 0.2
		end
	end)
end

-- ── Connecting path neon strips between pedestals ─────────
for i = 1, PEDESTAL_COUNT do
	local angle = (math.pi * 2 / PEDESTAL_COUNT) * (i - 1) - math.pi / 2
	local px = math.cos(angle) * (PEDESTAL_RADIUS - 4)
	local pz = math.sin(angle) * (PEDESTAL_RADIUS - 4)

	-- Small neon dot along radius leading from center
	local dot = makeNeon("Dot_"..i, Vector3.new(1, 0.3, 1), Vector3.new(px * 0.5, 0.3, pz * 0.5), COLORS.accent)
	dot.Transparency = 0.5
	dot.Parent = Workspace
end

-- ── Central coin fountain ─────────────────────────────────
local fountain = makePart("CoinFountain", Vector3.new(6, 1, 6), Vector3.new(0, 0, 0), Color3.fromRGB(60, 40, 120))
fountain.Shape = Enum.PartType.Cylinder
fountain.Parent = Workspace

local fountainGlow = makeNeon("FountainGlow", Vector3.new(6, 0.5, 6), Vector3.new(0, 0.8, 0), COLORS.gold)
fountainGlow.Transparency = 0.5
fountainGlow.Parent = Workspace

-- Pulse the fountain
task.spawn(function()
	local t = 0
	while true do
		t = t + task.wait(0.05)
		fountainGlow.Transparency = 0.4 + math.sin(t * 2) * 0.2
		fountainGlow.Size = Vector3.new(6 + math.sin(t * 1.5) * 0.5, 0.5, 6 + math.sin(t * 1.5) * 0.5)
	end
end)

-- ── Ambient floating particles (neon spheres) ─────────────
local ParticleFolder = Instance.new("Folder")
ParticleFolder.Name = "AmbientParticles"
ParticleFolder.Parent = Workspace

local particleColors = {
	Color3.fromRGB(180, 100, 255),
	Color3.fromRGB(255, 100, 180),
	Color3.fromRGB(100, 200, 255),
	Color3.fromRGB(255, 220, 80),
}

for i = 1, 20 do
	local px = math.random(-80, 80)
	local pz = math.random(-80, 80)
	local py = math.random(2, 15)
	local clr = particleColors[math.random(1, #particleColors)]
	local sz = math.random(1, 3) * 0.5

	local sphere = makePart("Particle_"..i, Vector3.new(sz, sz, sz), Vector3.new(px, py, pz), clr, Enum.Material.Neon)
	sphere.Shape = Enum.PartType.Ball
	sphere.Transparency = 0.4
	sphere.CastShadow = false
	sphere.Parent = ParticleFolder

	-- Drifting animation
	task.spawn(function()
		local baseX = px
		local baseY = py
		local baseZ = pz
		local t = math.random() * math.pi * 2
		local speed = 0.3 + math.random() * 0.5
		local range = 3 + math.random() * 5
		while true do
			t = t + task.wait(0.05) * speed
			sphere.Position = Vector3.new(
				baseX + math.sin(t) * range,
				baseY + math.sin(t * 0.7) * 2,
				baseZ + math.cos(t * 0.8) * range
			)
			sphere.Transparency = 0.3 + math.abs(math.sin(t * 0.4)) * 0.4
		end
	end)
end

print("✅ BrainrotTycoon WorldBuilder loaded!")
