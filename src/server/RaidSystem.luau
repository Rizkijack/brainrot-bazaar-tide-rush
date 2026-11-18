-- RaidSystem: Copyright Crawlers march on the base. The shield is the player's 10s answer.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotConfig"))
local State = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("State"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local GameState = require(game.ServerScriptService:FindFirstChild("GameState", true))
local WorldApi = require(game.ServerScriptService:FindFirstChild("WorldApi", true))

local RaidSystem = {}
local remotes
local raiders

local function toast(player, message, color)
	remotes.Toast:FireClient(player, message, color or Color3.fromRGB(255, 120, 120))
end

local function buildCrawler()
	local model = Instance.new("Model")
	model.Name = "CopyrightCrawler"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(7, 4, 9)
	body.Color = Color3.fromRGB(210, 30, 60)
	body.Material = Enum.Material.Neon
	body.Anchored = false
	body.Parent = model
	model.PrimaryPart = body
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = "Sphere"
		eye.Size = Vector3.new(1.2, 1.2, 1.2)
		eye.Color = Color3.new(1, 1, 1)
		eye.Position = Vector3.new(side * 1.7, 1, -4.6)
		eye.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = body, eye
		weld.Parent = eye
	end
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 320, 0, 70)
	bg.StudsOffset = Vector3.new(0, 5, 0)
	bg.AlwaysOnTop = true
	bg.Parent = body
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = "COPYRIGHT CRAWLER"
	text.TextColor3 = Color3.fromRGB(255, 80, 100)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = bg
	return model
end

function RaidSystem.SpawnRaider()
	if not raiders then return end
	local crawler = buildCrawler()
	local angle = math.random() * math.pi * 2
	crawler:SetPrimaryPartCFrame(CFrame.new(Vector3.new(math.cos(angle) * 80, 3, math.sin(angle) * 80)))
	crawler.Parent = raiders
	remotes.Raid:FireAllClients({ phase = "Active", message = "COPYRIGHT CRAWLER INBOUND - [E] to shield" })

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not crawler.Parent or not crawler.PrimaryPart then
			connection:Disconnect()
			return
		end
		local root = crawler.PrimaryPart
		local delta = Vector3.new(0, 3, 0) - root.Position
		if delta.Magnitude < 8 then
			connection:Disconnect()
			local victim = Players:GetPlayers()[1]
			if victim then
				if GameState.IsLocked(victim) then
					toast(victim, "SHIELD REPELLED THE CRAWLER!", Color3.fromRGB(120, 220, 255))
					remotes.Raid:FireAllClients({ phase = "Repelled", message = "Shield held!" })
				else
					local stolen = GameState.RemoveNewest(victim)
					if stolen then
						WorldApi.RemoveBrainrot(stolen.id)
						toast(victim, "CRAWLER STOLE " .. stolen.name, Color3.fromRGB(255, 70, 90))
						remotes.Owned:FireClient(victim, GameState.Get(victim).owned)
						remotes.Raid:FireAllClients({ phase = "Stole", message = "A brainrot was stolen!" })
					end
				end
			end
			crawler:Destroy()
			return
		end
		crawler:SetPrimaryPartCFrame(CFrame.new(root.Position + delta.Unit * math.min(12 * dt, delta.Magnitude)))
	end)
end

function RaidSystem.TryLock(player)
	local state = GameState.Get(player)
	if GameState.IsLocked(player) then
		toast(player, "Shield already up", Color3.fromRGB(120, 220, 255))
		return false
	end
	if not GameState.SetLock(player, State.LOCK_DURATION, State.LOCK_COOLDOWN) then
		toast(player, "Shield cooling down", Color3.fromRGB(255, 160, 90))
		return false
	end
	WorldApi.FlashShield(true)
	remotes.Lock:FireClient(player, true, state.lockUntil)
	toast(player, "BASE SHIELD UP - 10 SECONDS", Color3.fromRGB(120, 220, 255))
	task.delay(State.LOCK_DURATION, function()
		remotes.Lock:FireClient(player, false, 0)
	end)
	return true
end

function RaidSystem.Start()
	remotes = Net.CreateRemotes()
	raiders = Instance.new("Folder")
	raiders.Name = "Raiders"
	raiders.Parent = workspace
	remotes.Lock.OnServerEvent:Connect(RaidSystem.TryLock)
	task.spawn(function()
		while true do
			task.wait(45)
			RaidSystem.SpawnRaider()
		end
	end)
end

return RaidSystem
