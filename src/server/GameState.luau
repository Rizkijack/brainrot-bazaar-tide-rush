-- GameState: the one authoritative store of per-player state. Nothing economic is trusted from clients.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotConfig"))
local State = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("State"))

local GameState = {}
local store = {}

local function finite(n)
	return type(n) == "number" and n == n and n > -math.huge and n < math.huge
end

local function ensure(player)
	if not player then return nil end
	local key = player.UserId
	local s = store[key]
	if not s then
		s = State.NewPlayerState()
		store[key] = s
		-- A fresh player starts with three real brainrots so the base is never empty.
		for i = 1, 3 do
			local def = Config.BRAINROTS[i]
			s.owned[#s.owned + 1] = {
				id = key .. "-seed-" .. i,
				index = i,
				name = def.name,
				rate = def.rate,
				rarity = def.rarity,
				mutation = "Normal",
				pedestal = #s.owned + 1,
			}
		end
	end
	return s
end

function GameState.Get(player)
	return ensure(player)
end

function GameState.AddMoney(player, amount)
	if not finite(amount) or amount <= 0 then return 0 end
	local s = ensure(player)
	if not s then return 0 end
	s.money += amount
	s.lifetime += amount
	return s.money
end

function GameState.SpendMoney(player, amount)
	if not finite(amount) or amount < 0 then return false end
	local s = ensure(player)
	if not s or s.money < amount then return false end
	s.money -= amount
	return true
end

function GameState.AddBrainrot(player, entry)
	local s = ensure(player)
	if not s or type(entry) ~= "table" or #s.owned >= s.capacity then return nil end
	entry.pedestal = #s.owned + 1
	entry.id = entry.id or (player.UserId .. "-" .. os.time() .. "-" .. math.random(100000))
	s.owned[#s.owned + 1] = entry
	return entry
end

function GameState.RemoveNewest(player)
	local s = ensure(player)
	if not s or #s.owned == 0 then return nil end
	return table.remove(s.owned)
end

function GameState.RemoveById(player, id)
	local s = ensure(player)
	if not s then return nil end
	for i, entry in ipairs(s.owned) do
		if entry.id == id then return table.remove(s.owned, i) end
	end
	return nil
end

function GameState.ResetForRebirth(player)
	local s = ensure(player)
	if not s then return nil end
	s.money = State.START_MONEY
	s.lifetime = 0
	s.owned = {}
	s.rebirths += 1
	s.multiplier *= 2
	s.lockUntil = 0
	s.lastLock = 0
	return s
end

function GameState.Multiplier(player)
	local s = ensure(player)
	if not s then return 1 end
	return s.multiplier * (1 + s.incomeLevel * 0.25)
end

function GameState.IncomePerSecond(player)
	local s = ensure(player)
	if not s then return 0 end
	local total = 0
	for _, entry in ipairs(s.owned) do
		local rate = tonumber(entry.rate) or 0
		total += rate * Config.RarityMultiplier(entry.rarity) * Config.MutationMultiplier(entry.mutation)
	end
	return total * GameState.Multiplier(player)
end

function GameState.IsLocked(player)
	local s = ensure(player)
	if not s then return false end
	return os.time() < s.lockUntil
end

function GameState.SetLock(player, duration, cooldown)
	local s = ensure(player)
	if not s then return false end
	local now = os.time()
	if now < s.lastLock + (cooldown or State.LOCK_COOLDOWN) then return false end
	s.lastLock = now
	s.lockUntil = now + (duration or State.LOCK_DURATION)
	return true
end

-- Authoritative validation helpers. The client only sends an intent, never a price or a result.
function GameState.CanPurchase(player, index)
	local s = ensure(player)
	if not s then return false, "No state" end
	if type(index) ~= "number" or index ~= math.floor(index) or index < 1 or index > #Config.BRAINROTS + 4 then
		return false, "Invalid summon"
	end
	if #s.owned >= s.capacity then return false, "Base is full - upgrade capacity" end
	local cost = Config.CostFor(index)
	if s.money < cost then return false, "Need " .. Config.MoneyString(cost) end
	return true, cost
end

function GameState.CanRebirth(player)
	local s = ensure(player)
	if not s then return false, "No state" end
	if s.lifetime < State.REBIRTH_LIFETIME then
		return false, "Need " .. Config.MoneyString(State.REBIRTH_LIFETIME) .. " lifetime"
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false, "No character" end
	if (root.Position - Vector3.new(-60, 0, 0)).Magnitude > 24 then return false, "Reach the Vault" end
	return true, nil
end

Players.PlayerRemoving:Connect(function(player)
	store[player.UserId] = nil
end)

return GameState
