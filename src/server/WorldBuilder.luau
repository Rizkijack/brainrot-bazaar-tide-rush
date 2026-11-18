-- WorldBuilder: constructs the whole 3D Bazaar at runtime. No grey baseplate, no saved scenery.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotConfig"))
local WorldApi = require(game.ServerScriptService:FindFirstChild("WorldApi", true))

local WorldBuilder = {}

local BASE = Vector3.new(0, 0, 0)
local ALTAR = Vector3.new(60, 0, 0)
local VAULT = Vector3.new(-60, 0, 0)
local pedestals = {}
local shield
local brainrotsFolder

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or workspace
	return f
end

local SHAPE_ENUM = {
	Block = Enum.PartType.Block,
	Cube = Enum.PartType.Block,
	Sphere = Enum.PartType.Ball,
	Ball = Enum.PartType.Ball,
	Cone = Enum.PartType.Ball,
	Torus = Enum.PartType.Cylinder,
	Cylinder = Enum.PartType.Cylinder,
}

local function part(name, className, size, position, color, parent, material)
	local p = Instance.new("Part")
	p.Name = name
	local shape = SHAPE_ENUM[className] or Enum.PartType.Block
	p.Shape = shape
	if shape == Enum.PartType.Cylinder then
		-- Roblox cylinders run along X: swap the axes and stand them upright.
		p.Size = Vector3.new(size.Y, size.X, size.Z)
		p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	else
		p.Size = size
		p.Position = position
	end
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.Anchored = true
	p.Parent = parent
	return p
end

local function ring(name, center, radius, thickness, color, parent, plane)
	local group = Instance.new("Model")
	group.Name = name
	for i = 1, 18 do
		local angle = (i / 18) * math.pi * 2
		local offset = plane == "xy"
			and Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)
			or Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local seg = part("Segment", "Block", Vector3.new(thickness, thickness, thickness) * 1.7,
			center + offset, color, group, Enum.Material.Neon)
		seg.CastShadow = false
	end
	group.Parent = parent
	return group
end

local function light(parent, color, range, brightness, position)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Parent = parent
	return l
end

local function label(parent, lines, width, height, offset)
	local bg = Instance.new("BillboardGui")
	bg.Name = "Label"
	bg.Size = UDim2.new(0, width, 0, height)
	bg.StudsOffset = offset or Vector3.new(0, 4, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 100
	bg.Parent = parent
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(14, 8, 30)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(180, 90, 255)
	frame.Parent = bg
	for i, line in ipairs(lines) do
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, -8, 1 / #lines, 0)
		text.Position = UDim2.new(0, 4, (i - 1) / #lines, 0)
		text.BackgroundTransparency = 1
		text.Text = line.text
		text.TextColor3 = line.color or Color3.new(1, 1, 1)
		text.TextScaled = true
		text.Font = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
		text.Parent = frame
	end
	return bg
end

function WorldBuilder.BuildIslands()
	local islands = folder("Islands")
	part("Bazaar Island", "Cylinder", Vector3.new(110, 4, 110), Vector3.new(0, -2, 0),
		Color3.fromRGB(48, 24, 76), islands, Enum.Material.Ground)
	part("Altar Island", "Cylinder", Vector3.new(34, 4, 34), ALTAR + Vector3.new(0, -2, 0),
		Color3.fromRGB(70, 30, 110), islands, Enum.Material.Ground)
	part("Vault Island", "Cylinder", Vector3.new(34, 4, 34), VAULT + Vector3.new(0, -2, 0),
		Color3.fromRGB(30, 50, 100), islands, Enum.Material.Ground)

	-- Bright walkways make the three landmarks read as one connected world from above.
	part("Altar Causeway", "Block", Vector3.new(44, 1, 8), Vector3.new(30, 0.5, 0),
		Color3.fromRGB(150, 80, 240), islands, Enum.Material.Neon)
	part("Vault Causeway", "Block", Vector3.new(44, 1, 8), Vector3.new(-30, 0.5, 0),
		Color3.fromRGB(80, 180, 255), islands, Enum.Material.Neon)

	-- Decorative satellite islands around the arena.
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local p = Vector3.new(math.cos(angle) * 92, -6, math.sin(angle) * 92)
		part("Satellite " .. i, "Cylinder", Vector3.new(26, 4, 26), p,
			Color3.fromRGB(38 + i * 6, 20, 70 + i * 8), islands, Enum.Material.Ground)
	end
end

function WorldBuilder.BuildBase()
	local base = folder("Base")
	part("Base Platform", "Cylinder", Vector3.new(40, 2, 40), Vector3.new(0, 1, 0),
		Color3.fromRGB(96, 48, 150), base, Enum.Material.Glass)
	ring("Base Trim", Vector3.new(0, 2, 0), 21, 1.4, Color3.fromRGB(255, 190, 60), base, "xz")
	part("Core", "Sphere", Vector3.new(7, 7, 7), Vector3.new(0, 6, 0),
		Color3.fromRGB(255, 90, 200), base, Enum.Material.Neon)

	shield = part("Raid Shield", "Sphere", Vector3.new(48, 24, 48), Vector3.new(0, 5, 0),
		Color3.fromRGB(100, 220, 255), base, Enum.Material.ForceField)
	shield.Transparency = 0.92
	shield.CastShadow = false

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 2.6, 0)
	spawn.Anchored = true
	spawn.Enabled = true
	spawn.Duration = 0
	spawn.Parent = base

	label(shield, {
		{ text = "THE BAZAAR", color = Color3.fromRGB(255, 220, 120) },
		{ text = "Summon. Defend. Ride the Tide.", color = Color3.new(1, 1, 1) },
	}, 320, 56, Vector3.new(0, 12, 0))
end

function WorldBuilder.BuildPedestals()
	local pedestalFolder = folder("Pedestals")
	pedestals = {}
	for i = 1, 16 do
		local angle = ((i - 1) / 16) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * 25, 0, math.sin(angle) * 25)
		local stand = part("Pedestal " .. i, "Cylinder", Vector3.new(7, 2.4, 7), pos + Vector3.new(0, 1.2, 0),
			Color3.fromRGB(58, 32, 92), pedestalFolder, Enum.Material.Marble)
		local glow = part("Glow", "Cylinder", Vector3.new(7.4, 0.3, 7.4), pos + Vector3.new(0, 2.5, 0),
			Color3.fromRGB(160, 80, 255), stand, Enum.Material.Neon)
		glow.Position = pos + Vector3.new(0, 2.5, 0)
		glow.Anchored = true
		pedestals[i] = CFrame.new(pos + Vector3.new(0, 4.4, 0))
	end
	WorldApi.PedestalCFrame = function(index)
		return pedestals[math.clamp(index or 1, 1, #pedestals)]
	end
end

function WorldBuilder.BuildSummonAltar()
	local altar = folder("SummonAltar")
	part("Altar Base", "Cylinder", Vector3.new(20, 2, 20), ALTAR + Vector3.new(0, 1, 0),
		Color3.fromRGB(80, 36, 130), altar, Enum.Material.Marble)
	ring("Altar Ring", ALTAR + Vector3.new(0, 2.4, 0), 10.5, 1.3, Color3.fromRGB(255, 80, 220), altar, "xz")
	local beam = part("Summon Beam", "Cylinder", Vector3.new(3, 24, 3), ALTAR + Vector3.new(0, 14, 0),
		Color3.fromRGB(190, 90, 255), altar, Enum.Material.Neon)
	beam.Transparency = 0.55
	beam.CastShadow = false
	light(beam, Color3.fromRGB(220, 100, 255), 60, 3)
	label(beam, {
		{ text = "SUMMON ALTAR", color = Color3.fromRGB(255, 150, 255) },
		{ text = "[E] Buy next brainrot", color = Color3.new(1, 1, 1) },
	}, 300, 58, Vector3.new(0, 12, 0))
end

function WorldBuilder.BuildVaultPortal()
	local vault = folder("Vault")
	part("Vault Step", "Cylinder", Vector3.new(18, 2, 18), VAULT + Vector3.new(0, 1, 0),
		Color3.fromRGB(30, 60, 120), vault, Enum.Material.Marble)
	ring("Portal Ring", VAULT + Vector3.new(0, 9, 0), 8, 1.6, Color3.fromRGB(90, 200, 255), vault, "xy")
	local core = part("Portal Core", "Sphere", Vector3.new(11, 11, 11), VAULT + Vector3.new(0, 9, 0),
		Color3.fromRGB(60, 160, 255), vault, Enum.Material.Neon)
	core.Transparency = 0.65
	light(core, Color3.fromRGB(80, 180, 255), 70, 4)
	label(core, {
		{ text = "REBIRTH VAULT", color = Color3.fromRGB(140, 230, 255) },
		{ text = "50,000 lifetime + [E]", color = Color3.new(1, 1, 1) },
	}, 300, 58, Vector3.new(0, 9, 0))
end

function WorldBuilder.BuildTideGates()
	local gates = folder("TideGates")
	for i, x in ipairs({ -45, 45 }) do
		local tower = part("Tide Gate " .. i, "Block", Vector3.new(14, 40, 14), Vector3.new(x, 20, -70),
			Color3.fromRGB(60, 26, 100), gates, Enum.Material.Marble)
		local crown = part("Gate Crown", "Sphere", Vector3.new(16, 8, 16), Vector3.new(x, 42, -70),
			Color3.fromRGB(180, 60, 255), tower, Enum.Material.Neon)
		crown.Position = Vector3.new(x, 42, -70)
		crown.Anchored = true
		light(crown, Color3.fromRGB(190, 70, 255), 90, 5)
	end
	local bar = part("Gate Arch", "Block", Vector3.new(104, 4, 8), Vector3.new(0, 40, -70),
		Color3.fromRGB(170, 60, 255), gates, Enum.Material.Neon)
	label(bar, {
		{ text = "TIDE GATES", color = Color3.fromRGB(240, 170, 255) },
		{ text = "Stay above the wave!", color = Color3.new(1, 1, 1) },
	}, 320, 58, Vector3.new(0, 8, 0))
end

function WorldBuilder.DecorateWithLights()
	local decor = folder("Decor")
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * 34, 5, math.sin(angle) * 34)
		local lamp = part("Sky Lamp " .. i, "Sphere", Vector3.new(1.6, 1.6, 1.6), pos,
			i % 2 == 0 and Color3.fromRGB(255, 120, 220) or Color3.fromRGB(120, 200, 255),
			decor, Enum.Material.Neon)
		light(lamp, lamp.Color, 45, 2)

		local dust = Instance.new("ParticleEmitter")
		dust.Name = "Ambient Dust"
		dust.Rate = 5
		dust.Lifetime = NumberRange.new(4)
		dust.Speed = NumberRange.new(1, 3)
		dust.Size = NumberSequence.new(0.5)
		dust.Color = ColorSequence.new(lamp.Color)
		dust.Parent = lamp
	end
end

local SHAPES = {
	sphere = "Sphere",
	cylinder = "Cylinder",
	cone = "Ball",
	cube = "Block",
	torus = "Cylinder",
}

local function sparkle(parent, color, rate)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Mutation Sparkle"
	emitter.Rate = rate or 12
	emitter.Lifetime = NumberRange.new(1.4)
	emitter.Speed = NumberRange.new(2, 5)
	emitter.Size = NumberSequence.new(0.6)
	emitter.Color = ColorSequence.new(color)
	emitter.Parent = parent
end

function WorldBuilder.SpawnBrainrotModel(def, mutation, pedestalIndex, ownerId)
	if not brainrotsFolder then return nil end
	local mutationColor = Config.MutationColor(mutation)
	local rarityColor = Config.RarityColor(def.rarity)
	local model = Instance.new("Model")
	model.Name = def.name .. " [" .. mutation .. "]"
	model:SetAttribute("BrainrotName", def.name)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Rate", def.rate)
	model:SetAttribute("OwnerId", ownerId or 0)
	local id = ownerId and (ownerId .. "-" .. os.time() .. "-" .. math.random(100000)) or ("decor-" .. math.random(100000))
	model:SetAttribute("BrainrotId", id)

	local basePos = WorldApi.PedestalCFrame(pedestalIndex).Position
	local body = part("Body", SHAPES[def.shape] or "Sphere", Vector3.new(5, 5, 5), basePos,
		def.color:Lerp(mutationColor, 0.35), model,
		(mutation == "Neon" or mutation == "CORRUPTED") and Enum.Material.Neon or Enum.Material.Plastic)
	model.PrimaryPart = body
	body.CastShadow = true

	-- Eyes and a rarity hat make each citizen readable from a distance.
	for _, side in ipairs({ -1, 1 }) do
		local eye = part("Eye", "Sphere", Vector3.new(1.1, 1.1, 1.1),
			basePos + Vector3.new(side * 1.3, 0.8, -2.3), Color3.new(1, 1, 1), model, Enum.Material.Glass)
		local pupil = part("Pupil", "Sphere", Vector3.new(0.5, 0.5, 0.5),
			basePos + Vector3.new(side * 1.3, 0.8, -2.85), Color3.new(0, 0, 0), model)
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = body, eye
		weld.Parent = eye
		local weld2 = Instance.new("WeldConstraint")
		weld2.Part0, weld2.Part1 = eye, pupil
		weld2.Parent = pupil
	end
	local hat = part("Rarity Hat", "Ball", Vector3.new(3.4, 2, 3.4), basePos + Vector3.new(0, 3.4, 0),
		rarityColor, model, Enum.Material.Neon)
	local hatWeld = Instance.new("WeldConstraint")
	hatWeld.Part0, hatWeld.Part1 = body, hat
	hatWeld.Parent = hat

	if mutation ~= "Normal" then
		sparkle(body, mutationColor, mutation == "CORRUPTED" and 24 or 12)
	end

	local tag = label(body, {
		{ text = def.name, color = Color3.new(1, 1, 1) },
		{ text = mutation .. " " .. def.rarity, color = mutationColor },
		{ text = Config.MoneyString(def.rate * Config.RarityMultiplier(def.rarity) * Config.MutationMultiplier(mutation)) .. "/s", color = Color3.fromRGB(140, 255, 160) },
	}, 230, 66, Vector3.new(0, 4.2, 0))
	tag.Name = "RarityLabel" -- client visuals see the tag already exists and do not duplicate it

	model:SetAttribute("HomeX", basePos.X)
	model:SetAttribute("HomeY", basePos.Y)
	model:SetAttribute("HomeZ", basePos.Z)
	model:SetAttribute("Spin", 0.6 + (pedestalIndex % 5) * 0.12)
	model.Parent = brainrotsFolder

	return model
end

function WorldBuilder.FlashShield(on)
	if not shield then return end
	shield.Transparency = on and 0.35 or 0.92
	if on then
		task.delay(10, function()
			if shield and shield.Parent then shield.Transparency = 0.92 end
		end)
	end
end

function WorldBuilder.Start()
	brainrotsFolder = folder("Brainrots")
	WorldBuilder.BuildIslands()
	WorldBuilder.BuildBase()
	WorldBuilder.BuildPedestals()
	WorldBuilder.BuildSummonAltar()
	WorldBuilder.BuildVaultPortal()
	WorldBuilder.BuildTideGates()
	WorldBuilder.DecorateWithLights()
	WorldApi.RemoveBrainrot = function(idToRemove)
		for _, other in ipairs(brainrotsFolder:GetChildren()) do
			if other:GetAttribute("BrainrotId") == idToRemove then other:Destroy() end
		end
	end
	WorldApi.SpawnBrainrotModel = WorldBuilder.SpawnBrainrotModel
	WorldApi.FlashShield = WorldBuilder.FlashShield
	print("[Bazaar] World built: islands, base, 16 pedestals, altar, vault, tide gates.")
end

return WorldBuilder
