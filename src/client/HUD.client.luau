-- HUD.client: all player-facing information. Keys are bound only through ContextActionService.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotConfig"))
local State = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("State"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local remotes = Net.GetRemotes()
if not remotes then
	warn("[Bazaar] Remotes never arrived; HUD disabled.")
	return
end

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "BazaarHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local money, income, rebirths, multiplier, capacity = State.START_MONEY, 0, 0, 1, State.START_CAPACITY
local nextIndex, ownedCount = 1, 0
local bannerUntil = 0

local function frame(name, size, position, anchor, color)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.AnchorPoint = anchor
	f.BackgroundColor3 = color or Color3.fromRGB(18, 10, 38)
	f.BackgroundTransparency = 0.25
	f.BorderSizePixel = 2
	f.BorderColor3 = Color3.fromRGB(165, 85, 255)
	f.Parent = gui
	return f
end

local function textLabel(parent, name, size, position, text, textSize, color, font)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = position
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = textSize
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = font or Enum.Font.GothamBold
	l.Parent = parent
	return l
end

-- TOP CENTER: money, rate, rebirths. Kept away from the top-left 200x120 corner.
local top = frame("TopStats", UDim2.new(0, 540, 0, 104), UDim2.new(0.5, 0, 0, 16), Vector2.new(0.5, 0))
local moneyLabel = textLabel(top, "Money", UDim2.new(1, 0, 0, 46), UDim2.new(0, 0, 0, 4), "$100", 36, Color3.fromRGB(255, 220, 90))
local incomeLabel = textLabel(top, "Income", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 50), "+0/s", 21, Color3.fromRGB(140, 255, 170))
local rebirthLabel = textLabel(top, "Rebirth", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 78), "Rebirth 0  |  x1 income", 17, Color3.fromRGB(190, 160, 255), Enum.Font.Gotham)

-- RIGHT: shop.
local shop = frame("Shop", UDim2.new(0, 316, 0, 352), UDim2.new(1, -20, 0.5, 0), Vector2.new(1, 0.5))
textLabel(shop, "ShopTitle", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 10), "BAZAAR SHOP", 24, Color3.fromRGB(255, 150, 255))
local nextName = textLabel(shop, "NextName", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 52), "Blorp the Toaster", 19, Color3.new(1, 1, 1))
local nextMeta = textLabel(shop, "NextMeta", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 82), "Common  |  $25", 17, Color3.fromRGB(180, 200, 255), Enum.Font.Gotham)
local ownedLabel = textLabel(shop, "Owned", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 112), "Owned 3 / 8", 16, Color3.fromRGB(180, 255, 200), Enum.Font.Gotham)

local function button(parent, name, size, position, text, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = color or Color3.fromRGB(120, 50, 200)
	b.BorderSizePixel = 2
	b.BorderColor3 = Color3.fromRGB(255, 200, 255)
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 17
	b.Font = Enum.Font.GothamBold
	b.Parent = parent
	return b
end

local buyButton = button(shop, "Buy", UDim2.new(1, -24, 0, 54), UDim2.new(0, 12, 0, 146), "BUY  [B]", Color3.fromRGB(190, 60, 160))
local capButton = button(shop, "UpgradeCapacity", UDim2.new(0.5, -18, 0, 44), UDim2.new(0, 12, 0, 214), "+ CAPACITY", Color3.fromRGB(50, 110, 190))
local incButton = button(shop, "UpgradeIncome", UDim2.new(0.5, -18, 0, 44), UDim2.new(0.5, 6, 0, 214), "+ INCOME", Color3.fromRGB(180, 140, 40))
textLabel(shop, "Hint", UDim2.new(1, -20, 0, 66), UDim2.new(0, 10, 0, 274),
	"E altar: buy   E base: shield   E vault: rebirth\nHigher rarity and mutations multiply every rate.",
	15, Color3.fromRGB(200, 190, 230), Enum.Font.Gotham)

-- BOTTOM: hint bar and shield button.
local bottom = frame("HintBar", UDim2.new(0, 820, 0, 44), UDim2.new(0.5, 0, 1, -18), Vector2.new(0.5, 1))
textLabel(bottom, "HintText", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
	"WASD move / SPACE jump    -    E context action    -    B summon    -    Survive the Tide", 17, Color3.new(1, 1, 1), Enum.Font.Gotham)

local shieldButton = button(gui, "Shield", UDim2.new(0, 190, 0, 48), UDim2.new(1, -20, 1, -78),
	"SHIELD  [E]", Color3.fromRGB(40, 130, 190))
shieldButton.AnchorPoint = Vector2.new(1, 1)

-- CENTER: event banner, hidden until an event fires.
local banner = frame("Banner", UDim2.new(0, 760, 0, 92), UDim2.new(0.5, 0, 0.3, 0), Vector2.new(0.5, 0.5), Color3.fromRGB(40, 8, 70))
banner.Visible = false
local bannerLabel = textLabel(banner, "BannerText", UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0), "", 26, Color3.fromRGB(255, 180, 255))

local function showBanner(message, color, seconds)
	bannerLabel.Text = message
	bannerLabel.TextColor3 = color or Color3.fromRGB(255, 180, 255)
	banner.Visible = true
	bannerUntil = tick() + (seconds or 3)
end

local function refreshShop()
	local def = Config.BRAINROTS[nextIndex]
	if not def then
		nextName.Text = "OMEGA Brainrot Mk" .. (nextIndex - #Config.BRAINROTS)
		nextMeta.Text = "OMEGA  |  " .. Config.MoneyString(Config.CostFor(nextIndex))
	else
		nextName.Text = def.name
		nextMeta.Text = def.rarity .. "  |  " .. Config.MoneyString(def.cost) .. "  |  " .. Config.MoneyString(def.rate) .. "/s"
		nextMeta.TextColor3 = Config.RarityColor(def.rarity)
	end
	ownedLabel.Text = "Owned " .. ownedCount .. " / " .. capacity
	buyButton.Text = "BUY  " .. Config.MoneyString(Config.CostFor(nextIndex)) .. "  [B]"
end

local function refreshStats()
	moneyLabel.Text = Config.MoneyString(money)
	incomeLabel.Text = "+" .. Config.MoneyString(income) .. "/s"
	rebirthLabel.Text = "Rebirth " .. rebirths .. "  |  x" .. string.format("%.2f", multiplier) .. " income"
end

remotes.Money.OnClientEvent:Connect(function(newMoney, newIncome, _lifetime, newRebirths, newMultiplier, newCapacity)
	money = newMoney or money
	income = newIncome or income
	rebirths = newRebirths or rebirths
	multiplier = newMultiplier or multiplier
	capacity = newCapacity or capacity
	refreshStats()
	refreshShop()
end)

remotes.Owned.OnClientEvent:Connect(function(owned)
	ownedCount = owned and #owned or 0
	nextIndex = ownedCount + 1
	refreshShop()
end)

remotes.Toast.OnClientEvent:Connect(function(message, color)
	showBanner(message, color, 2.6)
end)

remotes.Tide.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then return end
	if data.phase == "Idle" then
		banner.Visible = false
	else
		showBanner(data.message or "TIDE EVENT", data.phase == "Hit" and Color3.fromRGB(255, 70, 120) or Color3.fromRGB(210, 120, 255), data.phase == "Warning" and 8 or 4)
	end
end)

remotes.Raid.OnClientEvent:Connect(function(data)
	if type(data) == "table" then showBanner(data.message or "RAID", Color3.fromRGB(255, 90, 90), 3) end
end)

remotes.Rebirth.OnClientEvent:Connect(function(count, mult)
	showBanner("REBIRTH " .. count .. " - INCOME x" .. mult, Color3.fromRGB(255, 220, 90), 4)
end)

remotes.Lock.OnClientEvent:Connect(function(active, untilTime)
	shieldButton.Text = active and "SHIELD UP" or "SHIELD  [E]"
	shieldButton.BackgroundColor3 = active and Color3.fromRGB(80, 220, 190) or Color3.fromRGB(40, 130, 190)
	if active then
		task.delay(math.max(0, (untilTime or 0) - os.time()), function()
			shieldButton.Text = "SHIELD  [E]"
			shieldButton.BackgroundColor3 = Color3.fromRGB(40, 130, 190)
		end)
	end
end)

buyButton.MouseButton1Click:Connect(function() remotes.Purchase:FireServer(nextIndex) end)
capButton.MouseButton1Click:Connect(function() remotes.Upgrade:FireServer(State.UpgradeKind.Capacity) end)
incButton.MouseButton1Click:Connect(function() remotes.Upgrade:FireServer(State.UpgradeKind.Income) end)
shieldButton.MouseButton1Click:Connect(function() remotes.Lock:FireServer() end)

local function near(point, radius)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - point).Magnitude < radius
end

ContextActionService:BindAction("BazaarE", function(_action, inputState, _input)
	if inputState ~= Enum.UserInputState.Begin then return end
	if near(Vector3.new(-60, 0, 0), 26) then
		remotes.Rebirth:FireServer()
	elseif near(Vector3.new(60, 0, 0), 18) then
		remotes.Purchase:FireServer(nextIndex)
	else
		remotes.Lock:FireServer()
	end
end, false, Enum.KeyCode.E)

ContextActionService:BindAction("BazaarBuy", function(_action, inputState, _input)
	if inputState == Enum.UserInputState.Begin then remotes.Purchase:FireServer(nextIndex) end
end, false, Enum.KeyCode.B)

game:GetService("RunService").RenderStepped:Connect(function()
	if banner.Visible and tick() > bannerUntil then banner.Visible = false end
end)

refreshStats()
refreshShop()
print("[Bazaar] HUD online.")
