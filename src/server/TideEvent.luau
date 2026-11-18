-- TideEvent: a 90 second rhythm of warning, then a rising purple wave that punishes low ground.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotConfig"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local GameState = require(game.ServerScriptService:FindFirstChild("GameState", true))
local WorldApi = require(game.ServerScriptService:FindFirstChild("WorldApi", true))

local TideEvent = {}
local remotes
local sweeping = false

function TideEvent.SweepTide()
	if sweeping then return false end
	sweeping = true

	local wave = Instance.new("Part")
	wave.Name = "TideWave"
	wave.Shape = "Block"
	wave.Size = Vector3.new(500, 24, 16)
	wave.Position = Vector3.new(0, 12, -120)
	wave.Color = Color3.fromRGB(150, 40, 255)
	wave.Material = Enum.Material.Neon
	wave.Transparency = 0.18
	wave.Anchored = true
	wave.CastShadow = false
	wave.Parent = workspace

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(190, 70, 255)
	glow.Range = 120
	glow.Brightness = 6
	glow.Parent = wave

	local mist = Instance.new("ParticleEmitter")
	mist.Rate = 60
	mist.Lifetime = NumberRange.new(2)
	mist.Speed = NumberRange.new(4, 12)
	mist.Size = NumberSequence.new(1.5)
	mist.Color = ColorSequence.new(Color3.fromRGB(190, 90, 255))
	mist.Parent = wave

	local hit = {}
	local connection = RunService.Heartbeat:Connect(function()
		for _, player in ipairs(Players:GetPlayers()) do
			if not hit[player] then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and root.Position.Y < 8 and math.abs(root.Position.Z - wave.Position.Z) < 10 then
					hit[player] = true
					local state = GameState.Get(player)
					local stolen = GameState.RemoveNewest(player)
					state.money = math.floor(state.money * 0.8)
					if stolen then WorldApi.RemoveBrainrot(stolen.id) end
					remotes.Owned:FireClient(player, state.owned)
					remotes.Money:FireClient(player, state.money, GameState.IncomePerSecond(player), state.lifetime, state.rebirths, state.multiplier, state.capacity)
					remotes.Tide:FireClient(player, { phase = "Hit", message = "THE TIDE TOOK A BRAINROT AND 20% OF YOUR CASH!" })
					remotes.Toast:FireClient(player, "TIDE HIT - lost " .. (stolen and stolen.name or "cash"), Color3.fromRGB(255, 70, 120))
				end
			end
		end
	end)

	remotes.Tide:FireAllClients({ phase = "Sweeping", message = "THE TIDE IS HERE - GET ABOVE Y=8" })
	local tween = TweenService:Create(wave, TweenInfo.new(8, Enum.EasingStyle.Linear), {
		Position = Vector3.new(0, 12, 120),
	})
	tween:Play()
	tween.Completed:Wait()
	connection:Disconnect()
	wave:Destroy()
	sweeping = false
	remotes.Tide:FireAllClients({ phase = "Idle", message = "Tide passed. Rebuild." })
	return true
end

function TideEvent.Start()
	remotes = Net.CreateRemotes()
	task.spawn(function()
		while true do
			task.wait(90)
			remotes.Tide:FireAllClients({
				phase = "Warning",
				message = "WARNING - TIDE IN 10s. CLIMB THE TIDE GATES!",
				seconds = 10,
			})
			task.wait(10)
			TideEvent.SweepTide()
			task.wait(80)
		end
	end)
end

return TideEvent
