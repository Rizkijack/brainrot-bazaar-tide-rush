-- EconomySystem: money ticks, purchases, capacity/income upgrades. All prices are checked server-side.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotConfig"))
local State = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("State"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local GameState = require(game.ServerScriptService:FindFirstChild("GameState", true))
local WorldApi = require(game.ServerScriptService:FindFirstChild("WorldApi", true))

local EconomySystem = {}
local remotes

local function toast(player, message, color)
	remotes.Toast:FireClient(player, message, color or Color3.fromRGB(255, 220, 120))
end

local function sendMoney(player)
	local s = GameState.Get(player)
	remotes.Money:FireClient(player, s.money, GameState.IncomePerSecond(player), s.lifetime, s.rebirths, s.multiplier, s.capacity)
end

local function sendOwned(player)
	remotes.Owned:FireClient(player, GameState.Get(player).owned)
end

local function definitionFor(index)
	local def = Config.BRAINROTS[index]
	if def then return def end
	local base = Config.BRAINROTS[#Config.BRAINROTS]
	return {
		name = "OMEGA Brainrot Mk" .. tostring(index - #Config.BRAINROTS),
		rate = base.rate * (index - #Config.BRAINROTS),
		cost = Config.CostFor(index),
		rarity = "OMEGA",
		color = base.color,
		shape = base.shape,
	}
end

function EconomySystem.HandlePurchase(player, requestedIndex)
	local ok, result = GameState.CanPurchase(player, math.floor(tonumber(requestedIndex) or 0))
	if not ok then
		toast(player, result, Color3.fromRGB(255, 90, 90))
		return false
	end

	local index = math.floor(tonumber(requestedIndex))
	local def = definitionFor(index)
	local state = GameState.Get(player)
	local luck = state.rebirths + state.incomeLevel
	local rarity = Config.RollRarity(luck)
	local mutation = Config.RollMutation(luck)

	GameState.SpendMoney(player, result)
	local entry = GameState.AddBrainrot(player, {
		index = index,
		name = def.name,
		rate = def.rate,
		rarity = rarity,
		mutation = mutation,
	})
	if not entry then
		toast(player, "Base is full", Color3.fromRGB(255, 90, 90))
		return false
	end

	local model = WorldApi.SpawnBrainrotModel(def, mutation, entry.pedestal, player.UserId)
	if model then model:SetAttribute("BrainrotId", entry.id) end

	toast(player, "SUMMONED " .. def.name .. " - " .. mutation .. " " .. rarity, Config.RarityColor(rarity))
	sendOwned(player)
	sendMoney(player)
	return true
end

function EconomySystem.HandleUpgrade(player, kind)
	local state = GameState.Get(player)
	if kind ~= State.UpgradeKind.Capacity and kind ~= State.UpgradeKind.Income then return false end
	local level = kind == State.UpgradeKind.Capacity and state.capacityLevel or state.incomeLevel
	local cost = math.floor(500 * ((level + 1) ^ 2) * (kind == State.UpgradeKind.Capacity and 1 or 2))
	if state.money < cost then
		toast(player, "Upgrade needs " .. Config.MoneyString(cost), Color3.fromRGB(255, 90, 90))
		return false
	end
	GameState.SpendMoney(player, cost)
	if kind == State.UpgradeKind.Capacity then
		state.capacityLevel += 1
		state.capacity += 2
		toast(player, "BASE EXPANDED - capacity " .. state.capacity, Color3.fromRGB(150, 220, 255))
	else
		state.incomeLevel += 1
		toast(player, "MONEY PRINTER UPGRADED - x" .. string.format("%.2f", GameState.Multiplier(player)), Color3.fromRGB(255, 210, 90))
	end
	sendMoney(player)
	return true
end

function EconomySystem.Start()
	remotes = Net.CreateRemotes()
	remotes.Purchase.OnServerEvent:Connect(EconomySystem.HandlePurchase)
	remotes.Upgrade.OnServerEvent:Connect(EconomySystem.HandleUpgrade)

	local function spawnOwned(player)
		local state = GameState.Get(player)
		for _, entry in ipairs(state.owned) do
			local model = WorldApi.SpawnBrainrotModel(definitionFor(entry.index), entry.mutation, entry.pedestal, player.UserId)
			if model then model:SetAttribute("BrainrotId", entry.id) end
		end
		sendOwned(player)
		sendMoney(player)
	end

	Players.PlayerAdded:Connect(function(player)
		task.delay(0.2, function()
			if player.Parent then spawnOwned(player) end
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do spawnOwned(player) end

	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local state = GameState.Get(player)
				GameState.AddMoney(player, GameState.IncomePerSecond(player))
				remotes.Money:FireClient(player, state.money, GameState.IncomePerSecond(player), state.lifetime, state.rebirths, state.multiplier, state.capacity)
			end
		end
	end)
end

return EconomySystem
