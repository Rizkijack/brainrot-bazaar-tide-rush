-- BrainrotConfig: the single source of truth for rarity, mutation, and the brainrot cast.
-- Both server and client require this from ReplicatedStorage.Shared.

local Config = {}

Config.RARITIES = {
	{ name = "Common",    multiplier = 1,  color = Color3.fromRGB(190, 198, 210) },
	{ name = "Spicy",     multiplier = 2,  color = Color3.fromRGB(255, 122, 61) },
	{ name = "Rare",      multiplier = 4,  color = Color3.fromRGB(74, 162, 255) },
	{ name = "Epic",      multiplier = 8,  color = Color3.fromRGB(186, 85, 255) },
	{ name = "Legendary", multiplier = 16, color = Color3.fromRGB(255, 202, 58) },
	{ name = "Mythic",    multiplier = 32, color = Color3.fromRGB(255, 71, 148) },
	{ name = "Cosmic",    multiplier = 64, color = Color3.fromRGB(93, 255, 224) },
	{ name = "OMEGA",     multiplier = 128, color = Color3.fromRGB(255, 45, 45) },
}

Config.MUTATIONS = {
	{ name = "Normal",    multiplier = 1,  color = Color3.fromRGB(230, 230, 235) },
	{ name = "Golden",    multiplier = 2,  color = Color3.fromRGB(255, 215, 64) },
	{ name = "Frozen",    multiplier = 3,  color = Color3.fromRGB(150, 235, 255) },
	{ name = "Neon",      multiplier = 5,  color = Color3.fromRGB(120, 255, 120) },
	{ name = "CORRUPTED", multiplier = 10, color = Color3.fromRGB(170, 0, 255) },
}

-- Twelve original citizens of the Bazaar. rate is money per second, cost is the shop price.
Config.BRAINROTS = {
	{ name = "Blorp the Toaster",  rate = 1,          cost = 25,         rarity = "Common",    color = Color3.fromRGB(255, 170, 70),  shape = "sphere" },
	{ name = "Capichungus",        rate = 6,          cost = 120,        rarity = "Common",    color = Color3.fromRGB(120, 220, 120), shape = "cylinder" },
	{ name = "Sir Wafflesworth",   rate = 30,         cost = 650,        rarity = "Spicy",     color = Color3.fromRGB(230, 180, 90),  shape = "cone" },
	{ name = "Meowzilla Prime",    rate = 150,        cost = 3200,       rarity = "Spicy",     color = Color3.fromRGB(255, 130, 190), shape = "sphere" },
	{ name = "Chungus Bussin",     rate = 800,        cost = 15000,      rarity = "Rare",      color = Color3.fromRGB(90, 200, 255),  shape = "cube" },
	{ name = "Skibidi Geyser",     rate = 4000,       cost = 75000,      rarity = "Epic",      color = Color3.fromRGB(90, 255, 210),  shape = "cone" },
	{ name = "Toaster Titan",      rate = 20000,      cost = 350000,     rarity = "Legendary", color = Color3.fromRGB(255, 90, 70),   shape = "cylinder" },
	{ name = "Giga Noodle",        rate = 100000,     cost = 1600000,    rarity = "Mythic",    color = Color3.fromRGB(255, 230, 120), shape = "torus" },
	{ name = "Nyan Biblio",        rate = 500000,     cost = 8000000,    rarity = "Cosmic",    color = Color3.fromRGB(180, 130, 255), shape = "cube" },
	{ name = "Freaky Fennec",      rate = 2500000,    cost = 40000000,   rarity = "Cosmic",    color = Color3.fromRGB(255, 140, 60),  shape = "cone" },
	{ name = "Void Avocado",       rate = 12000000,   cost = 200000000,  rarity = "OMEGA",     color = Color3.fromRGB(160, 255, 90),  shape = "sphere" },
	{ name = "OMEGA Brainrot",     rate = 60000000,   cost = 1000000000, rarity = "OMEGA",     color = Color3.fromRGB(255, 60, 60),   shape = "torus" },
}

function Config.GetTier(index)
	local list = Config.RARITIES
	return list[math.clamp(index, 1, #list)]
end

function Config.CostFor(index)
	local entry = Config.BRAINROTS[index]
	if entry then
		return entry.cost
	end
	-- Beyond the cast the price keeps climbing so the shop never dead-ends.
	local last = Config.BRAINROTS[#Config.BRAINROTS].cost
	return last * 5 * (index - #Config.BRAINROTS)
end

local function rollWeighted(list, luck)
	luck = luck or 0
	local weights, total = {}, 0
	for i, item in ipairs(list) do
		-- Luck biases the roll toward the rare end of the table.
		local w = math.max(0.5, (i ^ 2) / (1 + luck * (i - 1) * 0.35))
		weights[i] = w
		total += w
	end
	local pick = math.random() * total
	for i, w in ipairs(weights) do
		pick -= w
		if pick <= 0 then return list[i] end
	end
	return list[#list]
end

function Config.RollRarity(luck)
	return rollWeighted(Config.RARITIES, luck).name
end

function Config.RollMutation(luck)
	luck = luck or 0
	-- Mutation odds: 55 / 25 / 12 / 6 / 2 percent, nudged by luck.
	local chance = math.random()
	local bonus = math.min(0.35, luck * 0.02)
	if chance < 0.02 + bonus then return "CORRUPTED" end
	if chance < 0.08 + bonus then return "Neon" end
	if chance < 0.20 + bonus then return "Frozen" end
	if chance < 0.45 + bonus then return "Golden" end
	return "Normal"
end

local function suffix(n)
	if n >= 1e12 then return "T" end
	if n >= 1e9 then return "B" end
	if n >= 1e6 then return "M" end
	if n >= 1e3 then return "K" end
	return ""
end

function Config.MoneyString(value)
	value = math.floor(tonumber(value) or 0)
	local div = 1
	local s = suffix(value)
	if s == "T" then div = 1e12 elseif s == "B" then div = 1e9 elseif s == "M" then div = 1e6 elseif s == "K" then div = 1e3 end
	local scaled = value / div
	local text
	if s == "" then text = tostring(value)
	elseif scaled >= 100 then text = string.format("%.0f", scaled)
	elseif scaled >= 10 then text = string.format("%.1f", scaled)
	else text = string.format("%.2f", scaled) end
	return "$" .. text .. s
end

function Config.RarityColor(name)
	for _, item in ipairs(Config.RARITIES) do
		if item.name == name then return item.color end
	end
	return Config.RARITIES[1].color
end

function Config.MutationColor(name)
	for _, item in ipairs(Config.MUTATIONS) do
		if item.name == name then return item.color end
	end
	return Config.MUTATIONS[1].color
end

function Config.RarityMultiplier(name)
	for _, item in ipairs(Config.RARITIES) do
		if item.name == name then return item.multiplier end
	end
	return 1
end

function Config.MutationMultiplier(name)
	for _, item in ipairs(Config.MUTATIONS) do
		if item.name == name then return item.multiplier end
	end
	return 1
end

return Config
